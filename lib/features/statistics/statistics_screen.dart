import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/data_providers.dart';

/// Dynamic, real-time statistics screen calculating spending trends and category breakdown
/// from actual user transactions for Weekly, Monthly, and Yearly periods.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedPeriod = 'Weekly'; // 'Weekly', 'Monthly', 'Yearly'
  DateTime _currentAnchorDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencySymbol = ref.watch(currencySymbolProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
          },
          child: transactionsAsync.when(
            data: (allTransactions) {
              return _buildContent(
                context,
                theme,
                isDark,
                currencySymbol,
                allTransactions,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text('Error loading statistics: $err'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String currencySymbol,
    List<Map<String, dynamic>> allTransactions,
  ) {
    // 1. Filter transactions by period
    final periodData = _calculatePeriodData(allTransactions);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Period Toggle Buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PeriodButton(
                label: 'Weekly',
                isActive: _selectedPeriod == 'Weekly',
                onTap: () {
                  setState(() {
                    _selectedPeriod = 'Weekly';
                    _currentAnchorDate = DateTime.now();
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _PeriodButton(
                label: 'Monthly',
                isActive: _selectedPeriod == 'Monthly',
                onTap: () {
                  setState(() {
                    _selectedPeriod = 'Monthly';
                    _currentAnchorDate = DateTime.now();
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _PeriodButton(
                label: 'Yearly',
                isActive: _selectedPeriod == 'Yearly',
                onTap: () {
                  setState(() {
                    _selectedPeriod = 'Yearly';
                    _currentAnchorDate = DateTime.now();
                  });
                },
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.lg),

          // ── Date Range Navigator ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.xlAll,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(77),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previousPeriod,
                  tooltip: 'Previous',
                ),
                Text(
                  periodData.periodLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextPeriod,
                  tooltip: 'Next',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Summary Cards ──
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total Spent',
                  amount: '$currencySymbol${periodData.totalExpense.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward_rounded,
                  color: theme.colorScheme.error,
                  bgColor: theme.colorScheme.errorContainer.withAlpha(51),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryCard(
                  label: 'Total Income',
                  amount: '$currencySymbol${periodData.totalIncome.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.accentGreen,
                  bgColor: AppColors.accentGreen.withAlpha(38),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

          const SizedBox(height: AppSpacing.xl),

          // ── Bar Chart Card ──
          Container(
            height: 280,
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                      'Spending Trend',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Avg: $currencySymbol${periodData.averageExpense.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: periodData.maxChartY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = periodData.chartLabels[group.x.toInt()];
                            return BarTooltipItem(
                              '$label\n',
                              TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '$currencySymbol${rod.toY.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < periodData.chartLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    periodData.chartLabels[idx],
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withAlpha(153),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: periodData.barValues.asMap().entries.map((e) {
                        return _makeBarGroup(
                          e.key,
                          e.value,
                          isDark,
                          theme,
                          periodData.barValues.length > 7 ? 8 : 14,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .scaleY(begin: 0.92, end: 1.0, delay: 150.ms, duration: 400.ms),

          const SizedBox(height: AppSpacing.xl),

          // ── Category Breakdown List ──
          Text(
            'Category Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (periodData.categoryBreakdowns.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xxl,
                horizontal: AppSpacing.lg,
              ),
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
                    Icons.pie_chart_outline_rounded,
                    size: 44,
                    color: theme.colorScheme.onSurface.withAlpha(77),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No expenses for this ${_selectedPeriod.toLowerCase()}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Expenses you add will automatically appear here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(102),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: periodData.categoryBreakdowns.length,
              itemBuilder: (context, index) {
                final item = periodData.categoryBreakdowns[index];
                return _CategoryProgressRow(
                  icon: _getIconData(item.icon),
                  name: item.name,
                  amount: '$currencySymbol${item.amount.toStringAsFixed(0)}',
                  percent: item.percent,
                  color: _getCategoryColor(index, theme),
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 250 + index * 60),
                      duration: 300.ms,
                    );
              },
            ),
        ],
      ),
    );
  }

  void _previousPeriod() {
    setState(() {
      if (_selectedPeriod == 'Weekly') {
        _currentAnchorDate = _currentAnchorDate.subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'Monthly') {
        _currentAnchorDate = DateTime(
          _currentAnchorDate.year,
          _currentAnchorDate.month - 1,
          1,
        );
      } else {
        _currentAnchorDate = DateTime(
          _currentAnchorDate.year - 1,
          1,
          1,
        );
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_selectedPeriod == 'Weekly') {
        _currentAnchorDate = _currentAnchorDate.add(const Duration(days: 7));
      } else if (_selectedPeriod == 'Monthly') {
        _currentAnchorDate = DateTime(
          _currentAnchorDate.year,
          _currentAnchorDate.month + 1,
          1,
        );
      } else {
        _currentAnchorDate = DateTime(
          _currentAnchorDate.year + 1,
          1,
          1,
        );
      }
    });
  }

  _PeriodComputedData _calculatePeriodData(List<Map<String, dynamic>> allTransactions) {
    if (_selectedPeriod == 'Weekly') {
      return _calculateWeeklyData(allTransactions);
    } else if (_selectedPeriod == 'Monthly') {
      return _calculateMonthlyData(allTransactions);
    } else {
      return _calculateYearlyData(allTransactions);
    }
  }

  _PeriodComputedData _calculateWeeklyData(List<Map<String, dynamic>> allTransactions) {
    // Current anchor week: find Monday
    final anchor = _currentAnchorDate;
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final startStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
    final endStr = DateFormat('yyyy-MM-dd').format(endOfWeek);

    final periodLabel =
        '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';

    final barValues = List<double>.filled(7, 0.0);
    const chartLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    double totalExpense = 0.0;
    double totalIncome = 0.0;
    final categoryMap = <String, _CategoryAccumulator>{};

    for (final t in allTransactions) {
      final dateStr = t['transaction_date'] as String? ?? '';
      if (dateStr.compareTo(startStr) >= 0 && dateStr.compareTo(endStr) <= 0) {
        final date = DateTime.tryParse(dateStr);
        final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
        final isExpense = t['type'] == 'expense';

        if (isExpense) {
          totalExpense += amount;
          if (date != null) {
            final dayIndex = (date.weekday - 1).clamp(0, 6);
            barValues[dayIndex] += amount;
          }

          final catName = t['categories']?['name'] ?? t['category_name'] ?? 'Other';
          final catIcon = t['categories']?['icon'] ?? 'more_horiz';

          if (!categoryMap.containsKey(catName)) {
            categoryMap[catName] = _CategoryAccumulator(name: catName, icon: catIcon, amount: 0.0);
          }
          categoryMap[catName]!.amount += amount;
        } else {
          totalIncome += amount;
        }
      }
    }

    final categoryBreakdowns = _buildCategoryList(categoryMap, totalExpense);
    final maxVal = barValues.fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);
    final maxChartY = maxVal > 0 ? maxVal * 1.25 : 100.0;

    return _PeriodComputedData(
      periodLabel: periodLabel,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      averageExpense: totalExpense / 7,
      chartLabels: chartLabels,
      barValues: barValues,
      maxChartY: maxChartY,
      categoryBreakdowns: categoryBreakdowns,
    );
  }

  _PeriodComputedData _calculateMonthlyData(List<Map<String, dynamic>> allTransactions) {
    final year = _currentAnchorDate.year;
    final month = _currentAnchorDate.month;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final startStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
    final endStr = DateFormat('yyyy-MM-dd').format(endOfMonth);
    final periodLabel = DateFormat('MMMM yyyy').format(startOfMonth);

    // 4-5 weekly buckets (W1: 1-7, W2: 8-14, W3: 15-21, W4: 22-28, W5: 29-end)
    final daysInMonth = endOfMonth.day;
    final numBuckets = daysInMonth > 28 ? 5 : 4;
    final barValues = List<double>.filled(numBuckets, 0.0);
    final chartLabels = ['W1 (1-7)', 'W2 (8-14)', 'W3 (15-21)', 'W4 (22-28)'];
    if (numBuckets == 5) {
      chartLabels.add('W5 (29-$daysInMonth)');
    }

    double totalExpense = 0.0;
    double totalIncome = 0.0;
    final categoryMap = <String, _CategoryAccumulator>{};

    for (final t in allTransactions) {
      final dateStr = t['transaction_date'] as String? ?? '';
      if (dateStr.compareTo(startStr) >= 0 && dateStr.compareTo(endStr) <= 0) {
        final date = DateTime.tryParse(dateStr);
        final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
        final isExpense = t['type'] == 'expense';

        if (isExpense) {
          totalExpense += amount;
          if (date != null) {
            final day = date.day;
            final bucket = ((day - 1) ~/ 7).clamp(0, numBuckets - 1);
            barValues[bucket] += amount;
          }

          final catName = t['categories']?['name'] ?? t['category_name'] ?? 'Other';
          final catIcon = t['categories']?['icon'] ?? 'more_horiz';

          if (!categoryMap.containsKey(catName)) {
            categoryMap[catName] = _CategoryAccumulator(name: catName, icon: catIcon, amount: 0.0);
          }
          categoryMap[catName]!.amount += amount;
        } else {
          totalIncome += amount;
        }
      }
    }

    final categoryBreakdowns = _buildCategoryList(categoryMap, totalExpense);
    final maxVal = barValues.fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);
    final maxChartY = maxVal > 0 ? maxVal * 1.25 : 100.0;

    return _PeriodComputedData(
      periodLabel: periodLabel,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      averageExpense: totalExpense / numBuckets,
      chartLabels: chartLabels,
      barValues: barValues,
      maxChartY: maxChartY,
      categoryBreakdowns: categoryBreakdowns,
    );
  }

  _PeriodComputedData _calculateYearlyData(List<Map<String, dynamic>> allTransactions) {
    final year = _currentAnchorDate.year;
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

    final startStr = DateFormat('yyyy-MM-dd').format(startOfYear);
    final endStr = DateFormat('yyyy-MM-dd').format(endOfYear);
    final periodLabel = '$year';

    final barValues = List<double>.filled(12, 0.0);
    const chartLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    double totalExpense = 0.0;
    double totalIncome = 0.0;
    final categoryMap = <String, _CategoryAccumulator>{};

    for (final t in allTransactions) {
      final dateStr = t['transaction_date'] as String? ?? '';
      if (dateStr.compareTo(startStr) >= 0 && dateStr.compareTo(endStr) <= 0) {
        final date = DateTime.tryParse(dateStr);
        final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
        final isExpense = t['type'] == 'expense';

        if (isExpense) {
          totalExpense += amount;
          if (date != null) {
            final monthIndex = (date.month - 1).clamp(0, 11);
            barValues[monthIndex] += amount;
          }

          final catName = t['categories']?['name'] ?? t['category_name'] ?? 'Other';
          final catIcon = t['categories']?['icon'] ?? 'more_horiz';

          if (!categoryMap.containsKey(catName)) {
            categoryMap[catName] = _CategoryAccumulator(name: catName, icon: catIcon, amount: 0.0);
          }
          categoryMap[catName]!.amount += amount;
        } else {
          totalIncome += amount;
        }
      }
    }

    final categoryBreakdowns = _buildCategoryList(categoryMap, totalExpense);
    final maxVal = barValues.fold<double>(0.0, (prev, curr) => curr > prev ? curr : prev);
    final maxChartY = maxVal > 0 ? maxVal * 1.25 : 100.0;

    return _PeriodComputedData(
      periodLabel: periodLabel,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      averageExpense: totalExpense / 12,
      chartLabels: chartLabels,
      barValues: barValues,
      maxChartY: maxChartY,
      categoryBreakdowns: categoryBreakdowns,
    );
  }

  List<_CategoryBreakdownItem> _buildCategoryList(
    Map<String, _CategoryAccumulator> categoryMap,
    double totalExpense,
  ) {
    final list = categoryMap.values.map((c) {
      final pct = totalExpense > 0 ? (c.amount / totalExpense) : 0.0;
      return _CategoryBreakdownItem(
        name: c.name,
        icon: c.icon,
        amount: c.amount,
        percent: pct,
      );
    }).toList();

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  BarChartGroupData _makeBarGroup(
    int x,
    double y,
    bool isDark,
    ThemeData theme,
    double width,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isDark
                ? [AppColors.primaryDark, AppColors.secondaryDark]
                : [AppColors.primaryLight, AppColors.primaryContainerLight],
          ),
          width: width,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
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
      case 'fitness_center':
        return Icons.fitness_center;
      case 'flight':
        return Icons.flight;
      case 'fastfood':
        return Icons.fastfood;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'pets':
        return Icons.pets;
      case 'work':
        return Icons.work;
      case 'spa':
        return Icons.spa;
      case 'home':
        return Icons.home;
      case 'phone_android':
        return Icons.phone_android;
      case 'savings':
        return Icons.savings;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'build':
        return Icons.build;
      default:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(int index, ThemeData theme) {
    final colors = [
      AppColors.accentGreen,
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
      Colors.amber.shade700,
      Colors.deepOrangeAccent,
      Colors.purpleAccent,
      Colors.cyan,
      theme.colorScheme.outline,
    ];
    return colors[index % colors.length];
  }
}

class _CategoryAccumulator {
  final String name;
  final String icon;
  double amount;

  _CategoryAccumulator({
    required this.name,
    required this.icon,
    required this.amount,
  });
}

class _CategoryBreakdownItem {
  final String name;
  final String icon;
  final double amount;
  final double percent;

  _CategoryBreakdownItem({
    required this.name,
    required this.icon,
    required this.amount,
    required this.percent,
  });
}

class _PeriodComputedData {
  final String periodLabel;
  final double totalExpense;
  final double totalIncome;
  final double averageExpense;
  final List<String> chartLabels;
  final List<double> barValues;
  final double maxChartY;
  final List<_CategoryBreakdownItem> categoryBreakdowns;

  _PeriodComputedData({
    required this.periodLabel,
    required this.totalExpense,
    required this.totalIncome,
    required this.averageExpense,
    required this.chartLabels,
    required this.barValues,
    required this.maxChartY,
    required this.categoryBreakdowns,
  });
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.xlAll,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: AppRadius.xlAll,
          border: Border.all(
            color: isActive ? Colors.transparent : theme.colorScheme.outlineVariant.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                Text(
                  amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String amount;
  final double percent;
  final Color color;

  const _CategoryProgressRow({
    required this.icon,
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.outline.withAlpha(38),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(
                width: 38,
                child: Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
