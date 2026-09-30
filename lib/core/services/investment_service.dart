import 'package:flutter/foundation.dart';
import '../models/investment.dart';
import '../supabase_client.dart';

class InvestmentService {
  InvestmentService._();

  // In-memory demo data for guests (starts from zero)
  static final List<Investment> _guestInvestments = [];

  static Future<List<Investment>> getInvestments({bool isGuest = false}) async {
    if (isGuest || SupabaseClientHelper.currentUser == null) {
      return List.unmodifiable(_guestInvestments);
    }

    try {
      final response = await SupabaseClientHelper.client
          .from('investments')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => Investment.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('[InvestmentService] Error fetching investments: $e');
      return List.unmodifiable(_guestInvestments);
    }
  }

  static Future<Investment?> saveInvestment(
    Investment investment, {
    bool isGuest = false,
  }) async {
    final userId = SupabaseClientHelper.currentUser?.id;

    if (isGuest || userId == null) {
      final guestItem = Investment(
        id: investment.id ?? 'inv-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'guest',
        name: investment.name,
        type: investment.type,
        investedAmount: investment.investedAmount,
        currentValue: investment.currentValue,
        expectedReturnRate: investment.expectedReturnRate,
        monthlyContribution: investment.monthlyContribution,
        startDate: investment.startDate,
        notes: investment.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final existingIndex = _guestInvestments.indexWhere((item) => item.id == guestItem.id);
      if (existingIndex >= 0) {
        _guestInvestments[existingIndex] = guestItem;
      } else {
        _guestInvestments.insert(0, guestItem);
      }
      return guestItem;
    }

    try {
      final json = investment.toJson();
      json['user_id'] = userId;

      if (investment.id != null) {
        final response = await SupabaseClientHelper.client
            .from('investments')
            .update(json)
            .eq('id', investment.id!)
            .select()
            .single();
        return Investment.fromJson(response);
      } else {
        final response = await SupabaseClientHelper.client
            .from('investments')
            .insert(json)
            .select()
            .single();
        return Investment.fromJson(response);
      }
    } catch (e) {
      debugPrint('[InvestmentService] Error saving investment: $e');
      _guestInvestments.insert(0, investment);
      return investment;
    }
  }

  static Future<void> deleteInvestment(String id, {bool isGuest = false}) async {
    _guestInvestments.removeWhere((item) => item.id == id);

    if (!isGuest && SupabaseClientHelper.currentUser != null) {
      try {
        await SupabaseClientHelper.client
            .from('investments')
            .delete()
            .eq('id', id);
      } catch (e) {
        debugPrint('[InvestmentService] Error deleting investment: $e');
      }
    }
  }
}
