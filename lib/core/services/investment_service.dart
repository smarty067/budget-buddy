import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/investment.dart';
import '../supabase_client.dart';
import 'notification_service.dart';
import 'session_service.dart';

/// Service for Investment & Asset portfolio storage — fully persisted in local Hive box
/// (`local_investments`) across all app restarts, with optional Supabase cloud sync.
class InvestmentService {
  InvestmentService._();

  static const String _boxName = 'local_investments';

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  /// Get all saved investments, sorted latest created first.
  static Future<List<Investment>> getInvestments({bool isGuest = false}) async {
    SessionService.recordActivity();
    final box = await _getBox();

    // 1. Read local Hive items
    final List<Investment> localList = [];
    for (final raw in box.values) {
      if (raw is Map) {
        try {
          final map = Map<String, dynamic>.from(raw);
          localList.add(Investment.fromJson(map));
        } catch (e) {
          debugPrint('[InvestmentService] Error parsing cached investment: $e');
        }
      }
    }

    localList.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    if (isGuest || SupabaseClientHelper.currentUser == null) {
      return List.unmodifiable(localList);
    }

    // 2. Cloud sync if logged into Supabase
    try {
      final response = await SupabaseClientHelper.client
          .from('investments')
          .select()
          .order('created_at', ascending: false);

      final cloudList = (response as List)
          .map((item) => Investment.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sync cloud items to local Hive storage
      for (final item in cloudList) {
        if (item.id != null) {
          await box.put(item.id, item.toJson());
        }
      }

      return cloudList.isNotEmpty ? cloudList : localList;
    } catch (e) {
      debugPrint('[InvestmentService] Supabase read failed, using offline cache: $e');
      return List.unmodifiable(localList);
    }
  }

  /// Save an investment/asset locally in Hive and in Supabase (if authenticated).
  static Future<Investment?> saveInvestment(
    Investment investment, {
    bool isGuest = false,
  }) async {
    SessionService.recordActivity();
    final box = await _getBox();
    final userId = SupabaseClientHelper.currentUser?.id;

    final id = investment.id ?? 'inv_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = Investment(
      id: id,
      userId: isGuest ? 'guest' : (userId ?? 'guest'),
      name: investment.name,
      type: investment.type,
      investedAmount: investment.investedAmount,
      currentValue: investment.currentValue,
      expectedReturnRate: investment.expectedReturnRate,
      monthlyContribution: investment.monthlyContribution,
      startDate: investment.startDate,
      notes: investment.notes,
      createdAt: investment.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to local persistent storage immediately
    await box.put(id, toSave.toJson());

    // Send local notification alert
    await NotificationService.showInvestmentSavedAlert(
      name: toSave.name,
      amount: toSave.investedAmount,
    );

    // Attempt cloud sync if authenticated
    if (!isGuest && userId != null) {
      try {
        final json = toSave.toJson();
        json['user_id'] = userId;

        if (investment.id != null) {
          final response = await SupabaseClientHelper.client
              .from('investments')
              .update(json)
              .eq('id', investment.id!)
              .select()
              .single();
          final cloudSaved = Investment.fromJson(response);
          await box.put(cloudSaved.id ?? id, cloudSaved.toJson());
          return cloudSaved;
        } else {
          final response = await SupabaseClientHelper.client
              .from('investments')
              .insert(json)
              .select()
              .single();
          final cloudSaved = Investment.fromJson(response);
          await box.put(cloudSaved.id ?? id, cloudSaved.toJson());
          return cloudSaved;
        }
      } catch (e) {
        debugPrint('[InvestmentService] Cloud save failed, saved locally: $e');
      }
    }

    return toSave;
  }

  /// Delete an investment from local storage and Supabase.
  static Future<void> deleteInvestment(String id, {bool isGuest = false}) async {
    SessionService.recordActivity();
    final box = await _getBox();
    await box.delete(id);

    if (!isGuest && SupabaseClientHelper.currentUser != null) {
      try {
        await SupabaseClientHelper.client
            .from('investments')
            .delete()
            .eq('id', id);
      } catch (e) {
        debugPrint('[InvestmentService] Cloud delete error: $e');
      }
    }
  }
}
