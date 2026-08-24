import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

/// Custom bottom navigation bar with 5 tabs.
/// AI Coach tab (center) is highlighted with a raised design.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                theme: theme,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Statistics',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                theme: theme,
              ),
              // AI Coach — raised center button
              _AiCoachNavItem(
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                theme: theme,
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.category_rounded,
                label: 'Wallet',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                theme: theme,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withAlpha(153);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiCoachNavItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _AiCoachNavItem({
    required this.isActive,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.darkPrimaryGradient
                : AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withAlpha(isActive ? 102 : 51),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: isDark ? AppColors.onPrimaryDark : Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
