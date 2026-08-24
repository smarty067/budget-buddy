import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../core/providers/dashboard_tab_provider.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';
import '../statistics/statistics_screen.dart';
import '../budgets/budgets_screen.dart';

/// Navigation shell wrapping dashboard, statistics, ai coach, wallet/budgets, and settings.
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    AiCoachScreen(),
    BudgetsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(dashboardTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(dashboardTabProvider.notifier).state = index;
        },
      ),
    );
  }
}
