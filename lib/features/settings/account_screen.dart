import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/supabase_client.dart';

/// Screen for managing the user profile, account settings, and data.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _nameController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final user = SupabaseClientHelper.currentUser;
    final isGuest = ref.read(isGuestProvider);
    if (isGuest) {
      _nameController.text = 'Guest User';
    } else {
      _nameController.text =
          (user?.userMetadata?['full_name'] as String?) ?? 'Budget Buddy User';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isUpdating = true);
    try {
      final isGuest = ref.read(isGuestProvider);
      if (!isGuest) {
        await SupabaseClientHelper.client.auth.updateUser(
          UserAttributes(data: {'full_name': newName}),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPasswordController.text;
              final confirmPass = confirmPasswordController.text;
              if (newPass.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters')),
                );
                return;
              }
              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                await SupabaseClientHelper.client.auth.updateUser(
                  UserAttributes(password: newPass),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Password changed successfully!'),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to update password: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: const Text('Clear All Local Data?'),
        content: const Text(
          'This will delete all guest transactions, budgets, and savings goals stored on this device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final boxes = ['guest_transactions', 'guest_budgets', 'guest_goals', 'guest_categories'];
      for (final boxName in boxes) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
        } else {
          final box = await Hive.openBox(boxName);
          await box.clear();
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local data cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = ref.watch(isGuestProvider);
    final user = SupabaseClientHelper.currentUser;

    final email = isGuest ? 'Guest Mode (Offline)' : (user?.email ?? 'No email');
    final createdAt = isGuest ? 'Local Session' : (user?.createdAt.split('T')[0] ?? 'N/A');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Avatar & Status Card ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.xlAll,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(77),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isGuest
                          ? theme.colorScheme.tertiaryContainer.withAlpha(128)
                          : AppColors.accentGreen.withAlpha(38),
                      borderRadius: AppRadius.xlAll,
                    ),
                    child: Text(
                      isGuest ? 'Guest Account' : 'Cloud Synchronized',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isGuest
                            ? theme.colorScheme.onTertiaryContainer
                            : AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Account Details ──
            Text(
              'Personal Information',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
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
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: _isUpdating ? null : _updateName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _InfoRow(
                    label: 'Email',
                    value: email,
                    icon: Icons.email_outlined,
                  ),
                  const Divider(height: AppSpacing.xl),
                  _InfoRow(
                    label: 'Joined Date',
                    value: createdAt,
                    icon: Icons.calendar_today_outlined,
                  ),
                  if (!isGuest && user != null) ...[
                    const Divider(height: AppSpacing.xl),
                    _InfoRow(
                      label: 'User ID',
                      value: '${user.id.substring(0, 8)}...',
                      icon: Icons.fingerprint_rounded,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Security & Actions ──
            Text(
              'Security & Management',
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
                children: [
                  if (!isGuest)
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showChangePasswordDialog,
                    ),
                  if (isGuest)
                    ListTile(
                      leading: Icon(
                        Icons.cloud_upload_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Sign Up / Login to Cloud'),
                      subtitle: const Text('Backup your financial data to the cloud'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await ref.read(guestModeProvider.notifier).disableGuestMode();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  if (isGuest)
                    ListTile(
                      leading: Icon(
                        Icons.delete_sweep_outlined,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Clear Guest Data',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text('Delete all transactions and budgets'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _resetLocalData,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
