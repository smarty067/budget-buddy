import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/design_tokens.dart';
import '../../app/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/data_providers.dart';
import '../../core/providers/dashboard_tab_provider.dart';
import 'widgets/add_transaction_sheet.dart';

/// Dashboard home screen with dynamic balance display, quick actions, and recent activity.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      default:
        return Icons.more_horiz;
    }
  }

  void _showAddTransaction(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(initialType: type),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isGuest = ref.watch(isGuestProvider);
    final userAsync = ref.watch(authUserProvider);
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    // Get display name
    final displayName = isGuest
        ? 'Guest User'
        : (userAsync.valueOrNull?.userMetadata?['full_name'] as String? ?? 'User');

    // Get Greeting
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(monthlyTotalsProvider);
            ref.invalidate(transactionsProvider);
            ref.invalidate(budgetsProvider);
          },
          color: theme.colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting 👋',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Balance Card ──
                totalsAsync.when(
                  data: (totals) {
                    final income = totals['income'] ?? 0.0;
                    final expense = totals['expense'] ?? 0.0;
                    final balance = income - expense;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkPrimaryGradient
                            : AppColors.primaryGradient,
                        borderRadius: AppRadius.xxlAll,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryLight.withAlpha(64),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Balance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha(204),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${AppConstants.currencySymbol}${balance.toStringAsFixed(2)}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Income / Expense Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _BalanceStat(
                                icon: Icons.arrow_downward_rounded,
                                label: 'Income',
                                amount: '${AppConstants.currencySymbol}${income.toStringAsFixed(0)}',
                                iconColor: const Color(0xFF6FFBBE),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withAlpha(51),
                              ),
                              _BalanceStat(
                                icon: Icons.arrow_upward_rounded,
                                label: 'Expense',
                                amount: '${AppConstants.currencySymbol}${expense.toStringAsFixed(0)}',
                                iconColor: const Color(0xFFFFB4AB),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withAlpha(77),
                      borderRadius: AppRadius.xxlAll,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withAlpha(77),
                      borderRadius: AppRadius.xxlAll,
                    ),
                    child: Text('Error loading balances: $err'),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Quick Actions ──
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.remove_circle_outline_rounded,
                        label: 'Add Expense',
                        color: theme.colorScheme.error,
                        bgColor: theme.colorScheme.errorContainer.withAlpha(77),
                        onTap: () => _showAddTransaction(context, 'expense'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Add Income',
                        color: AppColors.accentGreen,
                        bgColor: AppColors.accentGreen.withAlpha(38),
                        onTap: () => _showAddTransaction(context, 'income'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.bar_chart_rounded,
                        label: 'Statistics',
                        color: theme.colorScheme.tertiary,
                        bgColor: theme.colorScheme.tertiaryContainer.withAlpha(77),
                        onTap: () {
                          // Switch to Statistics tab (index 1)
                          ref.read(dashboardTabProvider.notifier).state = 1;
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Budget Progress Card ──
                budgetsAsync.when(
                  data: (budgets) {
                    if (budgets.isEmpty) return const SizedBox.shrink();

                    // Find overall budget or default to first category budget
                    final overallBudget = budgets.firstWhere(
                      (b) => b['category_id'] == null,
                      orElse: () => budgets.first,
                    );
                    final double budgetAmount = (overallBudget['amount'] as num).toDouble();

                    // Calculate total spent from totals provider
                    final totalSpent = totalsAsync.valueOrNull?['expense'] ?? 0.0;
                    final ratio = budgetAmount > 0 ? (totalSpent / budgetAmount).clamp(0.0, 1.0) : 0.0;

                    return _BudgetProgressCard(
                      theme: theme,
                      isDark: isDark,
                      spent: totalSpent,
                      budget: budgetAmount,
                      ratio: ratio,
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Recent Activity ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch to wallet/budgets tab (index 3)
                        ref.read(dashboardTabProvider.notifier).state = 3;
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wallet_giftcard_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurface.withAlpha(77),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No transactions yet',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(128),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Add your first expense or income above!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(102),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: transactions
                          .take(5)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final t = entry.value;
                        final isExpense = t['type'] == 'expense';
                        final amount = (t['amount'] as num).toDouble();
                        final dateStr = t['transaction_date'] as String;

                        // Resolve category details
                        final catName = t['categories']?['name'] ?? t['category_name'] ?? 'Other';
                        final catIcon = t['categories']?['icon'] ?? 'more_horiz';

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: AppRadius.xlAll,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withAlpha(77),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isExpense
                                          ? theme.colorScheme.errorContainer
                                          : AppColors.accentGreen)
                                      .withAlpha(51),
                                  borderRadius: AppRadius.lgAll,
                                ),
                                child: Icon(
                                  _getIconData(catIcon),
                                  color: isExpense
                                      ? theme.colorScheme.error
                                      : AppColors.accentGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catName,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Text(
                                      dateStr,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withAlpha(128),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isExpense ? "-" : "+"}${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: isExpense
                                      ? theme.colorScheme.error
                                      : AppColors.accentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 600 + entry.key * 80),
                              duration: 300.ms,
                            );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Text('Error loading transactions: $err'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ──

class _BalanceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color iconColor;

  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.amount,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(51),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withAlpha(179),
                  ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.xlAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.xlAll,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final double spent;
  final double budget;
  final double ratio;

  const _BudgetProgressCard({
    required this.theme,
    required this.isDark,
    required this.spent,
    required this.budget,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Budget',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withAlpha(38),
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  '${(ratio * 100).toInt()}% used',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: theme.colorScheme.outline.withAlpha(38),
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio > 0.8
                    ? theme.colorScheme.error
                    : AppColors.accentGreen,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppConstants.currencySymbol}${spent.toStringAsFixed(0)} spent',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${budget.toStringAsFixed(0)} budget',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
