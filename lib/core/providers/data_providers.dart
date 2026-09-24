import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';
import 'auth_provider.dart';

/// Provider for list of transactions.
final transactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return TransactionService.getAll(isGuest: isGuest);
});

/// Provider for monthly budget list.
final budgetsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return BudgetService.getBudgets(isGuest: isGuest);
});

/// Provider for monthly financial summary totals (spent and income).
final monthlyTotalsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return TransactionService.getCurrentMonthTotals(isGuest: isGuest);
});

/// Provider for list of saving goals.
final savingsGoalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return BudgetService.getGoals(isGuest: isGuest);
});


/// Provider for list of categories (seeded default categories for guest, DB entries for cloud).
final categoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final isGuest = ref.watch(isGuestProvider);
  return CategoryService.getAll(isGuest: isGuest);
});
