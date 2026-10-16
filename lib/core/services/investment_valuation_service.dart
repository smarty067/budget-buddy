import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/investment.dart';
import '../models/investment_valuation_history.dart';
import '../supabase_client.dart';
import 'investment_service.dart';
import 'session_service.dart';

/// Service for recording investment valuation updates (growth/decrease).
/// Maintains a history of all changes while keeping the cost basis unchanged.
class InvestmentValuationService {
  InvestmentValuationService._();

  static const String _historyBoxName = 'local_investment_history';

  static Future<Box> _getHistoryBox() async {
    if (Hive.isBoxOpen(_historyBoxName)) return Hive.box(_historyBoxName);
    return Hive.openBox(_historyBoxName);
  }

  // ────────────────────────────────────────────────────────────────────────
  // HISTORY RETRIEVAL
  // ────────────────────────────────────────────────────────────────────────

  /// Returns all valuation history records for [investmentId], latest first.
  static Future<List<InvestmentValuationHistory>> getHistoryForInvestment(
    String investmentId, {
    bool isGuest = false,
  }) async {
    SessionService.recordActivity();
    final box = await _getHistoryBox();

    final local = <InvestmentValuationHistory>[];
    for (final raw in box.values) {
      if (raw is Map) {
        try {
          final map = Map<String, dynamic>.from(raw);
          if (map['investment_id'] == investmentId) {
            local.add(InvestmentValuationHistory.fromJson(map));
          }
        } catch (e) {
          debugPrint('[InvestmentValuationService] parse error: $e');
        }
      }
    }

    if (isGuest || SupabaseClientHelper.currentUser == null) {
      local.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return List.unmodifiable(local);
    }

    try {
      final response = await SupabaseClientHelper.client
          .from('investment_valuation_history')
          .select()
          .eq('investment_id', investmentId)
          .order('timestamp', ascending: false);

      final cloud = (response as List)
          .map((e) => InvestmentValuationHistory.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final h in cloud) {
        if (h.id != null) await box.put(h.id, h.toJson());
      }
      return cloud.isNotEmpty ? cloud : local;
    } catch (e) {
      debugPrint('[InvestmentValuationService] Supabase read failed: $e');
      local.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return List.unmodifiable(local);
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // UPDATE INVESTMENT VALUE
  // ────────────────────────────────────────────────────────────────────────

  /// Updates the market value of [investment] to [newMarketValue].
  ///
  /// Rules:
  /// - The original [investedAmount] (cost basis) is NEVER changed.
  /// - Only [currentValue] changes.
  /// - A history record is created for the change.
  /// - Returns the updated Investment and the history record, or null on failure.
  static Future<({Investment investment, InvestmentValuationHistory history})?> updateValue({
    required Investment investment,
    required double newMarketValue,
    required String updateType,
    String? note,
    bool isGuest = false,
  }) async {
    if (newMarketValue < 0) {
      debugPrint('[InvestmentValuationService] Rejected negative market value');
      return null;
    }
    if (investment.id == null) {
      debugPrint('[InvestmentValuationService] Investment has no ID');
      return null;
    }

    SessionService.recordActivity();
    final box = await _getHistoryBox();
    final userId = SupabaseClientHelper.currentUser?.id;

    final previousValue = investment.currentValue;
    final amountChanged = newMarketValue - previousValue;
    final percentageChanged = previousValue > 0
        ? (amountChanged / previousValue) * 100
        : 0.0;

    // Create history record
    final historyId = 'ivh_${DateTime.now().millisecondsSinceEpoch}';
    final history = InvestmentValuationHistory(
      id: historyId,
      investmentId: investment.id!,
      userId: isGuest ? 'guest' : (userId ?? 'guest'),
      previousValue: previousValue,
      newValue: newMarketValue,
      amountChanged: amountChanged,
      percentageChanged: percentageChanged,
      updateType: updateType,
      timestamp: DateTime.now(),
      note: note,
    );

    await box.put(historyId, history.toJson());

    // Update the investment's current value — DO NOT change investedAmount
    final updatedInvestment = Investment(
      id: investment.id,
      userId: investment.userId ?? (isGuest ? 'guest' : (userId ?? 'guest')),
      name: investment.name,
      type: investment.type,
      investedAmount: investment.investedAmount, // ← cost basis unchanged
      currentValue: newMarketValue,
      expectedReturnRate: investment.expectedReturnRate,
      monthlyContribution: investment.monthlyContribution,
      startDate: investment.startDate,
      notes: investment.notes,
      createdAt: investment.createdAt,
      updatedAt: DateTime.now(),
    );

    final saved = await InvestmentService.saveInvestment(updatedInvestment, isGuest: isGuest);

    // Cloud sync for history
    if (!isGuest && userId != null) {
      try {
        final json = history.toJson()..['user_id'] = userId;
        final response = await SupabaseClientHelper.client
            .from('investment_valuation_history')
            .insert(json)
            .select()
            .single();
        final cloudHistory = InvestmentValuationHistory.fromJson(response);
        await box.put(cloudHistory.id ?? historyId, cloudHistory.toJson());
        return (investment: saved ?? updatedInvestment, history: cloudHistory);
      } catch (e) {
        debugPrint('[InvestmentValuationService] History cloud save failed: $e');
      }
    }

    return (investment: saved ?? updatedInvestment, history: history);
  }

  // ────────────────────────────────────────────────────────────────────────
  // CALCULATIONS (stateless, pure)
  // ────────────────────────────────────────────────────────────────────────

  /// Calculates growth: currentValue + growthAmount.
  /// Returns (newValue, amountChange, percentChange).
  static ({double newValue, double amountChange, double percentChange}) calculateGrowth({
    required double currentValue,
    required double growthAmount,
  }) {
    final newValue = currentValue + growthAmount;
    final amountChange = growthAmount;
    final percentChange = currentValue > 0 ? (growthAmount / currentValue) * 100 : 0.0;
    return (newValue: newValue, amountChange: amountChange, percentChange: percentChange);
  }

  /// Calculates decrease: currentValue - decreaseAmount.
  static ({double newValue, double amountChange, double percentChange}) calculateDecrease({
    required double currentValue,
    required double decreaseAmount,
  }) {
    final newValue = (currentValue - decreaseAmount).clamp(0.0, double.infinity);
    final amountChange = -(currentValue - newValue);
    final percentChange = currentValue > 0 ? (amountChange / currentValue) * 100 : 0.0;
    return (newValue: newValue, amountChange: amountChange, percentChange: percentChange);
  }

  /// Calculates change when a new total value is directly entered.
  static ({double amountChange, double percentChange}) calculateChangeFromNewValue({
    required double previousValue,
    required double newValue,
  }) {
    final amountChange = newValue - previousValue;
    final percentChange = previousValue > 0 ? (amountChange / previousValue) * 100 : 0.0;
    return (amountChange: amountChange, percentChange: percentChange);
  }

  /// Unrealized profit or loss = current market value - cost basis.
  static double unrealizedProfitLoss(double currentValue, double costBasis) {
    return currentValue - costBasis;
  }

  /// Unrealized return percentage against cost basis.
  static double unrealizedReturnPercentage(double currentValue, double costBasis) {
    if (costBasis <= 0) return 0.0;
    return ((currentValue - costBasis) / costBasis) * 100;
  }
}
