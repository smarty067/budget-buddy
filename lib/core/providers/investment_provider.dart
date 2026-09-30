import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/investment.dart';
import '../services/investment_service.dart';
import 'auth_provider.dart';

final investmentsProvider = FutureProvider.autoDispose<List<Investment>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return InvestmentService.getInvestments(isGuest: isGuest);
});

class InvestmentSummary {
  final double totalInvested;
  final double totalCurrentValue;
  final double totalReturns;
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
    totalInvested += inv.investedAmount;
    totalCurrentValue += inv.currentValue;
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
