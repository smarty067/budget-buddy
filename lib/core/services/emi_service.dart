import 'package:flutter/foundation.dart';
import '../models/emi_calculation.dart';
import '../supabase_client.dart';

class EmiService {
  EmiService._();

  // In-memory cache for guest mode
  static final List<EmiCalculation> _guestCalculations = [];

  static Future<List<EmiCalculation>> getCalculations({bool isGuest = false}) async {
    if (isGuest || SupabaseClientHelper.currentUser == null) {
      return List.unmodifiable(_guestCalculations);
    }

    try {
      final response = await SupabaseClientHelper.client
          .from('emi_calculations')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => EmiCalculation.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('[EmiService] Error fetching calculations from Supabase: $e');
      return List.unmodifiable(_guestCalculations);
    }
  }

  static Future<EmiCalculation?> saveCalculation(
    EmiCalculation calculation, {
    bool isGuest = false,
  }) async {
    final userId = SupabaseClientHelper.currentUser?.id;

    if (isGuest || userId == null) {
      final guestItem = EmiCalculation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'guest',
        title: calculation.title,
        loanAmount: calculation.loanAmount,
        interestRate: calculation.interestRate,
        tenureYears: calculation.tenureYears,
        monthlyEmi: calculation.monthlyEmi,
        totalInterest: calculation.totalInterest,
        totalPayment: calculation.totalPayment,
        createdAt: DateTime.now(),
      );
      _guestCalculations.insert(0, guestItem);
      return guestItem;
    }

    try {
      final json = calculation.toJson();
      json['user_id'] = userId;

      final response = await SupabaseClientHelper.client
          .from('emi_calculations')
          .insert(json)
          .select()
          .single();

      return EmiCalculation.fromJson(response);
    } catch (e) {
      debugPrint('[EmiService] Error saving calculation to Supabase: $e');
      // Save locally as fallback
      _guestCalculations.insert(0, calculation);
      return calculation;
    }
  }

  static Future<void> deleteCalculation(String id, {bool isGuest = false}) async {
    _guestCalculations.removeWhere((item) => item.id == id);

    if (!isGuest && SupabaseClientHelper.currentUser != null) {
      try {
        await SupabaseClientHelper.client
            .from('emi_calculations')
            .delete()
            .eq('id', id);
      } catch (e) {
        debugPrint('[EmiService] Error deleting calculation from Supabase: $e');
      }
    }
  }
}
