import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/providers/dashboard_tab_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/session_service.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../budgets/budgets_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import 'dashboard_screen.dart';

/// Navigation shell wrapping dashboard, statistics, ai coach, wallet/budgets, and settings.
class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  static const List<Widget> _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    AiCoachScreen(),
    BudgetsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptNotifications();
    });
  }

  Future<void> _checkAndPromptNotifications() async {
    SessionService.recordActivity();
    try {
      final box = Hive.isBoxOpen('settings_box')
          ? Hive.box('settings_box')
          : await Hive.openBox('settings_box');
      final prompted =
          box.get('notification_prompted', defaultValue: false) as bool;
      if (!prompted) {
        await box.put('notification_prompted', true);
        await NotificationService.requestPermission();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(dashboardTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          SessionService.recordActivity();
          ref.read(dashboardTabProvider.notifier).state = index;
        },
      ),
    );
  }
}
