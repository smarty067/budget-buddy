import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../supabase_client.dart';
import 'session_service.dart';

/// Robust service for managing user loans with local Hive caching (`local_loans`),
/// safe Supabase synchronization, idempotent upserts, and guest-to-account migration.
class LoanService {
  LoanService._();

  static const String _boxName = 'local_loans';
  static const String _pendingDeletesBoxName = 'local_loans_pending_deletes';
  static const _uuid = Uuid();

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  static Future<Box> _getPendingDeletesBox() async {
    if (Hive.isBoxOpen(_pendingDeletesBoxName)) {
      return Hive.box(_pendingDeletesBoxName);
    }
    return await Hive.openBox(_pendingDeletesBoxName);
  }

  /// Get all loans, sorted by created_at or start_date descending.
  static Future<List<Loan>> getLoans({bool isGuest = false}) async {
    SessionService.recordActivity();
    final box = await _getBox();
    final currentUser = SupabaseClientHelper.currentUser;
    final authenticatedUserId = currentUser?.id;

    // 1. Read local cache items
    final List<Loan> localList = [];
    for (final raw in box.values) {
      if (raw is Map) {
        try {
          final map = Map<String, dynamic>.from(raw);
          localList.add(Loan.fromJson(map));
        } catch (e) {
          debugPrint('[LoanService] Error parsing cached loan: $e');
        }
      }
    }

    // 2. If guest mode or unauthenticated, return local guest loans only
    if (isGuest || authenticatedUserId == null) {
      final guestLoans = localList.where((l) => l.userId == 'guest').toList();
      guestLoans.sort((a, b) {
        final aDate = a.createdAt ?? a.startDate;
        final bDate = b.createdAt ?? b.startDate;
        return bDate.compareTo(aDate);
      });
      return List.unmodifiable(guestLoans);
    }

    // 3. Authenticated mode:
    // A) Process any pending deletions that failed previously
    await _flushPendingDeletes(authenticatedUserId);

    // B) Migrate any guest loans to the authenticated user
    await _migrateGuestLoans(box, authenticatedUserId);

    // C) Fetch latest cloud loans from Supabase
    try {
      final pendingBox = await _getPendingDeletesBox();
      final pendingIds = pendingBox.keys.map((k) => k.toString()).toSet();

      final response = await SupabaseClientHelper.client
          .from('loans')
          .select()
          .eq('user_id', authenticatedUserId)
          .order('created_at', ascending: false);

      final cloudList = (response as List)
          .map((item) => Loan.fromJson(item as Map<String, dynamic>))
          .where((item) => !pendingIds.contains(item.id))
          .toList();

      // Safe update: update or insert cloud loans into Hive without wiping other data
      final cloudIds = cloudList.map((l) => l.id).toSet();
      for (final item in cloudList) {
        await box.put(item.id, item.toJson());
      }

      // Remove from local cache any user loans that were deleted on cloud
      for (final local in localList) {
        if (local.userId == authenticatedUserId && !cloudIds.contains(local.id)) {
          await box.delete(local.id);
        }
      }

      return cloudList;
    } catch (e) {
      debugPrint('[LoanService] Supabase fetch failed, fallback to local cache: $e');
      final userLoans = localList.where((l) => l.userId == authenticatedUserId).toList();
      userLoans.sort((a, b) {
        final aDate = a.createdAt ?? a.startDate;
        final bDate = b.createdAt ?? b.startDate;
        return bDate.compareTo(aDate);
      });
      return List.unmodifiable(userLoans);
    }
  }

  /// Create or update a loan with idempotent upsert and strict authenticated user binding.
  static Future<Loan?> saveLoan(Loan loan, {bool isGuest = false}) async {
    SessionService.recordActivity();
    final box = await _getBox();
    final currentUser = SupabaseClientHelper.currentUser;
    final authenticatedUserId = currentUser?.id;

    // Strict user ID binding: NEVER accept an arbitrary user_id from client input
    final effectiveUserId = (isGuest || authenticatedUserId == null)
        ? 'guest'
        : authenticatedUserId;

    final loanId = loan.id.isNotEmpty ? loan.id : _uuid.v4();
    final toSave = loan.copyWith(
      id: loanId,
      userId: effectiveUserId,
      createdAt: loan.createdAt ?? DateTime.now(),
    );

    // Save to Hive cache immediately
    await box.put(loanId, toSave.toJson());

    // Guest mode stays local
    if (isGuest || authenticatedUserId == null) {
      return toSave;
    }

    // Cloud upsert (idempotent, safe on retry)
    try {
      final payload = toSave.toJson();
      // Ensure user_id in payload is strictly the authenticated user's ID
      payload['user_id'] = authenticatedUserId;

      final res = await SupabaseClientHelper.client
          .from('loans')
          .upsert(payload, onConflict: 'id')
          .select()
          .single();

      final saved = Loan.fromJson(res);
      await box.put(saved.id, saved.toJson());
      return saved;
    } catch (e) {
      debugPrint('[LoanService] Supabase upsert failed, stored in local cache: $e');
      return toSave;
    }
  }

  /// Update loan status ('active' | 'closed') safely across cache and Supabase.
  static Future<bool> updateLoanStatus(
    String id,
    String status, {
    bool isGuest = false,
  }) async {
    SessionService.recordActivity();
    final box = await _getBox();
    final currentUser = SupabaseClientHelper.currentUser;
    final authenticatedUserId = currentUser?.id;

    // Update in Hive cache
    final cached = box.get(id);
    if (cached is Map) {
      final map = Map<String, dynamic>.from(cached);
      map['status'] = status;
      await box.put(id, map);
    }

    if (isGuest || authenticatedUserId == null) {
      return true;
    }

    try {
      await SupabaseClientHelper.client
          .from('loans')
          .update({'status': status})
          .eq('id', id)
          .eq('user_id', authenticatedUserId);
      return true;
    } catch (e) {
      debugPrint('[LoanService] Supabase update status failed: $e');
      return false;
    }
  }

  /// Delete a loan safely: removes from Hive and Supabase with pending delete tracking on offline/failure.
  static Future<bool> deleteLoan(String id, {bool isGuest = false}) async {
    SessionService.recordActivity();
    final box = await _getBox();
    final currentUser = SupabaseClientHelper.currentUser;
    final authenticatedUserId = currentUser?.id;

    // Remove from local cache
    await box.delete(id);

    if (isGuest || authenticatedUserId == null) {
      return true;
    }

    // Record to pending deletes so offline deletes are guaranteed to sync later
    final pendingBox = await _getPendingDeletesBox();
    await pendingBox.put(id, DateTime.now().toIso8601String());

    try {
      await SupabaseClientHelper.client
          .from('loans')
          .delete()
          .eq('id', id)
          .eq('user_id', authenticatedUserId);

      // Successfully deleted on cloud -> clear pending delete marker
      await pendingBox.delete(id);
      return true;
    } catch (e) {
      debugPrint('[LoanService] Supabase delete failed, queued in pending deletes: $e');
      return false;
    }
  }

  /// Flushes any pending deletes against Supabase when connectivity is available.
  static Future<void> _flushPendingDeletes(String authenticatedUserId) async {
    try {
      final pendingBox = await _getPendingDeletesBox();
      if (pendingBox.isEmpty) return;

      final keys = List<dynamic>.from(pendingBox.keys);
      for (final key in keys) {
        final id = key.toString();
        try {
          await SupabaseClientHelper.client
              .from('loans')
              .delete()
              .eq('id', id)
              .eq('user_id', authenticatedUserId);
          await pendingBox.delete(key);
        } catch (e) {
          debugPrint('[LoanService] Retry delete failed for $id: $e');
        }
      }
    } catch (e) {
      debugPrint('[LoanService] Error flushing pending deletes: $e');
    }
  }

  /// Migrates local guest loans (`userId == 'guest'`) to the authenticated user upon sign-in.
  static Future<void> _migrateGuestLoans(Box box, String authenticatedUserId) async {
    final guestLoans = <Loan>[];
    for (final raw in box.values) {
      if (raw is Map) {
        try {
          final loan = Loan.fromJson(Map<String, dynamic>.from(raw));
          if (loan.userId == 'guest') {
            guestLoans.add(loan);
          }
        } catch (_) {}
      }
    }

    if (guestLoans.isEmpty) return;

    for (final guestLoan in guestLoans) {
      try {
        final migrated = guestLoan.copyWith(userId: authenticatedUserId);
        final payload = migrated.toJson();
        payload['user_id'] = authenticatedUserId;

        await SupabaseClientHelper.client
            .from('loans')
            .upsert(payload, onConflict: 'id');

        await box.put(migrated.id, migrated.toJson());
        debugPrint('[LoanService] Migrated guest loan ${migrated.name} to user account');
      } catch (e) {
        debugPrint('[LoanService] Failed to migrate guest loan ${guestLoan.id}: $e');
      }
    }
  }
}
