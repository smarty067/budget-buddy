import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/data_providers.dart';
import '../../shared/widgets/glass_card.dart';
import 'widgets/add_budget_sheet.dart';

/// Budgets and Savings Goals screen (Wallet page).
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _showAddBudgetDialog(BuildContext context, bool isGoal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBudgetSheet(initialIsGoal: isGoal),
    );
  }

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final goalsAsync = ref.watch(savingsGoalsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Budgets'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(savingsGoalsProvider);
            ref.invalidate(budgetsProvider);
            ref.invalidate(monthlyTotalsProvider);
          },
          color: theme.colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Savings Goals Section ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Savings Goals',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddBudgetDialog(context, true),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                goalsAsync.when(
                  data: (goals) {
                    if (goals.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppRadius.xlAll,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withAlpha(77),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              size: 40,
                              color: theme.colorScheme.onSurface.withAlpha(77),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No savings goals set',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(128),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showAddBudgetDialog(context, true),
                              child: const Text('Create a Goal'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: goals.map((g) {
                        final title = g['title'] as String;
                        final target = (g['target_amount'] as num).toDouble();
                        final current = (g['current_amount'] as num).toDouble();
                        final targetDate = g['target_date'] as String?;
                        final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: GlassCard(
                            borderRadius: AppRadius.xxl,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (targetDate != null)
                                          Text(
                                            'Target: $targetDate',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurface.withAlpha(128),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '${(ratio * 100).toInt()}%',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ClipRRect(
                                  borderRadius: AppRadius.smAll,
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: theme.colorScheme.outline.withAlpha(38),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Saved: $currencySymbol${current.toStringAsFixed(0)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Goal: $currencySymbol${target.toStringAsFixed(0)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withAlpha(153),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text('Error loading goals: $err'),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Category Budgets Section ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category Budgets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddBudgetDialog(context, false),
                      icon: const Icon(Icons.add_rounded),
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                budgetsAsync.when(
                  data: (budgets) {
                    if (budgets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppRadius.xlAll,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withAlpha(77),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.donut_large_rounded,
                              size: 40,
                              color: theme.colorScheme.onSurface.withAlpha(77),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No budgets set for this month',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(128),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showAddBudgetDialog(context, false),
                              child: const Text('Set a Budget'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Render budget tiles
                    return Column(
                      children: budgets.asMap().entries.map((e) {
                        final b = e.value;
                        final amount = (b['amount'] as num).toDouble();
                        final catName = b['categories']?['name'] ?? b['category_name'] ?? 'Overall';
                        final catIcon = b['categories']?['icon'] ?? 'all_inclusive';

                        // Total spent from totals provider or category-wise?
                        // For simplicity, we can fetch category-wise totals or show budget limit vs overall spent
                        final double spent = totalsAsync.valueOrNull?['expense'] ?? 0.0;

                        return _BudgetTile(
                          categoryName: catName,
                          icon: _getIconData(catIcon),
                          spent: spent,
                          budget: amount,
                          color: AppColors.accentTeal,
                          currencySymbol: currencySymbol,
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 200 + e.key * 80),
                              duration: 350.ms,
                            );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text('Error loading budgets: $err'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final String categoryName;
  final IconData icon;
  final double spent;
  final double budget;
  final Color color;
  final String currencySymbol;

  const _BudgetTile({
    required this.categoryName,
    required this.icon,
    required this.spent,
    required this.budget,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > budget;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(77),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Budget: $currencySymbol${budget.toInt()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$currencySymbol${spent.toInt()}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isOver ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outline.withAlpha(38),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? theme.colorScheme.error : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
