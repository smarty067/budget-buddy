import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/investment.dart';
import '../models/investment_valuation_history.dart';
import '../services/investment_service.dart';
import '../services/investment_valuation_service.dart';
import 'auth_provider.dart';

// ── Investments List ──
final investmentsProvider = FutureProvider.autoDispose<List<Investment>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return InvestmentService.getInvestments(isGuest: isGuest);
});

// ── Investment Valuation History for a specific investment ──
final investmentHistoryProvider =
    FutureProvider.autoDispose.family<List<InvestmentValuationHistory>, String>(
        (ref, investmentId) async {
  final isGuest = ref.watch(isGuestProvider);
  return InvestmentValuationService.getHistoryForInvestment(investmentId,
      isGuest: isGuest);
});

// ── Portfolio Summary ──
class InvestmentSummary {
  final double totalInvested;       // Cost basis — never changes with market moves
  final double totalCurrentValue;   // Current market value
  final double totalReturns;        // Unrealized P&L = current - invested
  final double overallReturnPercentage;
  final double totalMonthlySip;

  const InvestmentSummary({
    required this.totalInvested,
    required this.totalCurrentValue,
    required this.totalReturns,
    required this.overallReturnPercentage,
    required this.totalMonthlySip,
  });
}

final investmentSummaryProvider = Provider.autoDispose<InvestmentSummary>((ref) {
  final asyncInvestments = ref.watch(investmentsProvider);
  final list = asyncInvestments.valueOrNull ?? [];

  double totalInvested = 0;
  double totalCurrentValue = 0;
  double totalMonthlySip = 0;

  for (final inv in list) {
    totalInvested += inv.investedAmount;      // cost basis
    totalCurrentValue += inv.currentValue;   // market value
    totalMonthlySip += inv.monthlyContribution;
  }

  final totalReturns = totalCurrentValue - totalInvested;
  final overallReturnPercentage =
      totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0.0;

  return InvestmentSummary(
    totalInvested: totalInvested,
    totalCurrentValue: totalCurrentValue,
    totalReturns: totalReturns,
    overallReturnPercentage: overallReturnPercentage,
    totalMonthlySip: totalMonthlySip,
  );
});
