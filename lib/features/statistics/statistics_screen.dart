import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/design_tokens.dart';

/// Statistics screen showing charts and category breakdown.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PeriodButton(
                    label: 'Weekly',
                    isActive: _selectedPeriod == 'Weekly',
                    onTap: () => setState(() => _selectedPeriod = 'Weekly'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _PeriodButton(
                    label: 'Monthly',
                    isActive: _selectedPeriod == 'Monthly',
                    onTap: () => setState(() => _selectedPeriod = 'Monthly'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _PeriodButton(
                    label: 'Yearly',
                    isActive: _selectedPeriod == 'Yearly',
                    onTap: () => setState(() => _selectedPeriod = 'Yearly'),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // Bar Chart Card
              Container(
                height: 260,
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
                    Text(
                      'Spending Trend',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 5000,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        days[idx],
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withAlpha(128),
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
                          barGroups: [
                            _makeBarGroup(0, 1200, isDark),
                            _makeBarGroup(1, 2800, isDark),
                            _makeBarGroup(2, 900, isDark),
                            _makeBarGroup(3, 3400, isDark),
                            _makeBarGroup(4, 1500, isDark),
                            _makeBarGroup(5, 4200, isDark),
                            _makeBarGroup(6, 2100, isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .scaleY(begin: 0.9, end: 1.0, delay: 150.ms, duration: 400.ms),

              const SizedBox(height: AppSpacing.xl),

              // Category Breakdown List
              Text(
                'Category Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _CategoryProgressRow(
                    icon: Icons.restaurant,
                    name: 'Food & Dining',
                    amount: '₹3,720',
                    percent: 0.45,
                    color: AppColors.accentGreen,
                  ),
                  _CategoryProgressRow(
                    icon: Icons.shopping_bag,
                    name: 'Shopping',
                    amount: '₹2,100',
                    percent: 0.25,
                    color: theme.colorScheme.primary,
                  ),
                  _CategoryProgressRow(
                    icon: Icons.directions_car,
                    name: 'Transport',
                    amount: '₹1,500',
                    percent: 0.18,
                    color: theme.colorScheme.tertiary,
                  ),
                  _CategoryProgressRow(
                    icon: Icons.movie,
                    name: 'Entertainment',
                    amount: '₹800',
                    percent: 0.09,
                    color: Colors.amber,
                  ),
                  _CategoryProgressRow(
                    icon: Icons.more_horiz,
                    name: 'Other',
                    amount: '₹380',
                    percent: 0.03,
                    color: theme.colorScheme.outline,
                  ),
                ]
                    .asMap()
                    .entries
                    .map((e) => e.value.animate().fadeIn(
                          delay: Duration(milliseconds: 300 + e.key * 80),
                          duration: 300.ms,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, bool isDark) {
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
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
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
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: AppRadius.xlAll,
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : theme.colorScheme.outlineVariant.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
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
                    value: percent,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.outline.withAlpha(38),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(
                width: 32,
                child: Text(
                  '${(percent * 100).toInt()}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
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
