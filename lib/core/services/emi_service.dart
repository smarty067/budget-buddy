import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emi_calculation.dart';
import '../supabase_client.dart';
import 'notification_service.dart';
import 'session_service.dart';

/// Service for EMI calculation storage — fully persisted in local Hive box
/// (`local_calculations`) across all app restarts, with optional Supabase cloud sync.
class EmiService {
  EmiService._();

  static const String _boxName = 'local_calculations';

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  /// Get all saved calculations, sorted latest first.
  static Future<List<EmiCalculation>> getCalculations({bool isGuest = false}) async {
    SessionService.recordActivity();
    final box = await _getBox();

    // 1. Read local Hive items
    final List<EmiCalculation> localList = [];
    for (final raw in box.values) {
      if (raw is Map) {
        try {
          final map = Map<String, dynamic>.from(raw);
          localList.add(EmiCalculation.fromJson(map));
        } catch (e) {
          debugPrint('[EmiService] Error parsing cached calculation: $e');
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
          .from('emi_calculations')
          .select()
          .order('created_at', ascending: false);

      final cloudList = (response as List)
          .map((item) => EmiCalculation.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sync cloud items to local Hive storage
      for (final item in cloudList) {
        if (item.id != null) {
          await box.put(item.id, item.toJson());
        }
      }

      return cloudList.isNotEmpty ? cloudList : localList;
    } catch (e) {
      debugPrint('[EmiService] Supabase read failed, using offline cache: $e');
      return List.unmodifiable(localList);
    }
  }

  /// Save an EMI calculation locally in Hive and in Supabase (if authenticated).
  static Future<EmiCalculation?> saveCalculation(
    EmiCalculation calculation, {
    bool isGuest = false,
  }) async {
    SessionService.recordActivity();
    final box = await _getBox();
    final userId = SupabaseClientHelper.currentUser?.id;

    final id = calculation.id ?? 'calc_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = EmiCalculation(
      id: id,
      userId: isGuest ? 'guest' : (userId ?? 'guest'),
      title: calculation.title,
      loanAmount: calculation.loanAmount,
      interestRate: calculation.interestRate,
      tenureYears: calculation.tenureYears,
      monthlyEmi: calculation.monthlyEmi,
      totalInterest: calculation.totalInterest,
      totalPayment: calculation.totalPayment,
      createdAt: calculation.createdAt ?? DateTime.now(),
    );

    // Save to local persistent storage immediately
    await box.put(id, toSave.toJson());

    // Send local notification alert
    await NotificationService.showLoanSavedAlert(
      title: toSave.title,
      monthlyEmi: toSave.monthlyEmi,
    );

    // Attempt cloud sync if authenticated
    if (!isGuest && userId != null) {
      try {
        final json = toSave.toJson();
        json['user_id'] = userId;

        final response = await SupabaseClientHelper.client
            .from('emi_calculations')
            .insert(json)
            .select()
            .single();

        final cloudSaved = EmiCalculation.fromJson(response);
        await box.put(cloudSaved.id ?? id, cloudSaved.toJson());
        return cloudSaved;
      } catch (e) {
        debugPrint('[EmiService] Cloud save failed, saved locally: $e');
      }
    }

    return toSave;
  }

  /// Delete a calculation from local storage and Supabase.
  static Future<void> deleteCalculation(String id, {bool isGuest = false}) async {
    SessionService.recordActivity();
    final box = await _getBox();
    await box.delete(id);

    if (!isGuest && SupabaseClientHelper.currentUser != null) {
      try {
        await SupabaseClientHelper.client
            .from('emi_calculations')
            .delete()
            .eq('id', id);
      } catch (e) {
        debugPrint('[EmiService] Cloud delete error: $e');
      }
    }
  }
}
