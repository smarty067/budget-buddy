import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/auth_service.dart';

/// Settings screen with theme toggle and placeholder sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _themeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Profile Section ──
          _SettingsSection(
            title: 'Profile',
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Account',
                subtitle: isGuest ? 'Guest User' : 'Manage your profile',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.currency_rupee_rounded,
                title: 'Currency',
                subtitle: 'INR (₹)',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Appearance Section ──
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: _themeModeString(currentThemeMode),
                onTap: () {
                  _showThemeDialog(context, ref, currentThemeMode);
                },
              ),
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Data Section ──
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categories',
                subtitle: 'Manage spending categories',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.download_rounded,
                title: 'Export Data',
                subtitle: 'Download CSV of transactions',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Notifications Section ──
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Budget Alerts',
                subtitle: 'Get notified at 80% and 100%',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                ),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.auto_awesome_outlined,
                title: 'AI Weekly Digest',
                subtitle: 'Weekly spending summary',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Danger Zone ──
          _SettingsSection(
            title: 'Account',
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                titleColor: theme.colorScheme.error,
                onTap: () async {
                  if (isGuest) {
                    await ref.read(guestModeProvider.notifier).disableGuestMode();
                  } else {
                    await AuthService.signOut();
                  }
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              if (!isGuest)
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  titleColor: theme.colorScheme.error,
                  onTap: () {},
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Version Info ──
          Center(
            child: Text(
              'Budget Buddy v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(102),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ──

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          clipBehavior: Clip.antiAlias, // Protect ink splashes from overflowing
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.xlAll,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(77),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: titleColor ?? theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withAlpha(77),
          ),
      onTap: onTap,
    );
  }
}
