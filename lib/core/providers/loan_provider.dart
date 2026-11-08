import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../services/loan_service.dart';
import 'auth_provider.dart';

/// Provider for loading all loans (active and closed)
final loansProvider = FutureProvider.autoDispose<List<Loan>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return LoanService.getLoans(isGuest: isGuest);
});

/// Provider returning only active loans
final activeLoansProvider = Provider.autoDispose<List<Loan>>((ref) {
  final asyncLoans = ref.watch(loansProvider);
  return asyncLoans.valueOrNull?.where((loan) => loan.isActive).toList() ?? [];
});

/// Provider returning only closed loans
final closedLoansProvider = Provider.autoDispose<List<Loan>>((ref) {
  final asyncLoans = ref.watch(loansProvider);
  return asyncLoans.valueOrNull?.where((loan) => loan.isClosed).toList() ?? [];
});

/// Total monthly EMI for all active loans
final totalActiveMonthlyEmiProvider = Provider.autoDispose<double>((ref) {
  final activeLoans = ref.watch(activeLoansProvider);
  return activeLoans.fold<double>(0.0, (sum, loan) => sum + loan.emiAmount);
});

