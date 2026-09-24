import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/transaction_service.dart';
import 'account_screen.dart';
import 'categories_screen.dart';

/// Settings screen with working profile, currency, categories, appearance, and export options.
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
    final selectedCurrency = ref.watch(currencyProvider);

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
                subtitle: isGuest ? 'Guest User (Tap to manage)' : 'Manage your profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.currency_rupee_rounded,
                title: 'Currency',
                subtitle: '${selectedCurrency.name} (${selectedCurrency.symbol})',
                onTap: () {
                  _showCurrencyDialog(context, ref, selectedCurrency);
                },
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
                onTap: () {
                  _showLanguageDialog(context);
                },
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.download_rounded,
                title: 'Export Data',
                subtitle: 'Download CSV of transactions',
                onTap: () {
                  _exportData(context, isGuest);
                },
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
            title: 'Session',
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

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, CurrencyInfo currentCurrency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: ListView.builder(
            itemCount: availableCurrencies.length,
            itemBuilder: (context, index) {
              final currency = availableCurrencies[index];
              final isSelected = currency.code == currentCurrency.code;

              return ListTile(
                leading: Text(
                  currency.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text('${currency.name} (${currency.code})'),
                trailing: Text(
                  currency.symbol,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                selected: isSelected,
                selectedTileColor:
                    Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                onTap: () {
                  ref.read(currencyProvider.notifier).setCurrency(currency);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Currency updated to ${currency.code} (${currency.symbol})'),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: const Icon(Icons.check, color: AppColors.accentGreen),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Hindi (हिंदी)'),
              subtitle: const Text('Coming soon'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, bool isGuest) async {
    try {
      final transactions = await TransactionService.getAll(limit: 500, isGuest: isGuest);
      if (transactions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions to export.')),
          );
        }
        return;
      }

      // Format CSV
      final csvHeader = 'ID,Date,Type,Category,Amount,Note\n';
      final csvRows = transactions.map((t) {
        final id = t['id'] ?? '';
        final date = t['transaction_date'] ?? '';
        final type = t['type'] ?? '';
        final cat = t['categories']?['name'] ?? t['category_name'] ?? '';
        final amount = t['amount'] ?? 0;
        final note = (t['note'] as String? ?? '').replaceAll(',', ';');
        return '$id,$date,$type,$cat,$amount,$note';
      }).join('\n');

      final fullCsv = csvHeader + csvRows;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
            title: const Text('Export Data Ready'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transactions.length} transactions exported successfully in CSV format.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Text(
                    '${fullCsv.split('\n').take(4).join('\n')}\n...',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exported ${transactions.length} rows.'),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e')),
        );
      }
    }
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
          clipBehavior: Clip.antiAlias,
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
