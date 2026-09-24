import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/data_providers.dart';
import '../../core/services/category_service.dart';

/// Screen allowing users to view, create, and delete spending categories.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static const List<Map<String, dynamic>> _availableIcons = [
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Food'},
    {'name': 'directions_car', 'icon': Icons.directions_car, 'label': 'Transport'},
    {'name': 'receipt_long', 'icon': Icons.receipt_long, 'label': 'Bills'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag, 'label': 'Shopping'},
    {'name': 'movie', 'icon': Icons.movie, 'label': 'Entertainment'},
    {'name': 'medical_services', 'icon': Icons.medical_services, 'label': 'Health'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Education'},
    {'name': 'fitness_center', 'icon': Icons.fitness_center, 'label': 'Fitness'},
    {'name': 'flight', 'icon': Icons.flight, 'label': 'Travel'},
    {'name': 'fastfood', 'icon': Icons.fastfood, 'label': 'Fast Food'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports, 'label': 'Gaming'},
    {'name': 'local_cafe', 'icon': Icons.local_cafe, 'label': 'Cafe'},
    {'name': 'pets', 'icon': Icons.pets, 'label': 'Pets'},
    {'name': 'work', 'icon': Icons.work, 'label': 'Work'},
    {'name': 'spa', 'icon': Icons.spa, 'label': 'Personal Care'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Home'},
    {'name': 'phone_android', 'icon': Icons.phone_android, 'label': 'Recharge'},
    {'name': 'savings', 'icon': Icons.savings, 'label': 'Savings'},
    {'name': 'card_giftcard', 'icon': Icons.card_giftcard, 'label': 'Gifts'},
    {'name': 'build', 'icon': Icons.build, 'label': 'Maintenance'},
    {'name': 'more_horiz', 'icon': Icons.more_horiz, 'label': 'Other'},
  ];

  IconData _getIconData(String? iconName) {
    for (final item in _availableIcons) {
      if (item['name'] == iconName) {
        return item['icon'] as IconData;
      }
    }
    return Icons.category_outlined;
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedIcon = 'restaurant';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
            title: const Text('Add New Category'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Groceries, Gym',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Choose Icon',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableIcons.map((item) {
                        final iconName = item['name'] as String;
                        final iconData = item['icon'] as IconData;
                        final isSelected = selectedIcon == iconName;

                        return InkWell(
                          onTap: () => setDialogState(() => selectedIcon = iconName),
                          borderRadius: AppRadius.mdAll,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                              borderRadius: AppRadius.mdAll,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant.withAlpha(77),
                              ),
                            ),
                            child: Icon(
                              iconData,
                              size: 22,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final isGuest = ref.read(isGuestProvider);
                  await CategoryService.create(
                    name: name,
                    icon: selectedIcon,
                    isGuest: isGuest,
                  );
                  ref.invalidate(categoriesProvider);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Category "$name" added!'),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "$name"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final isGuest = ref.read(isGuestProvider);
      await CategoryService.delete(id: id, isGuest: isGuest);
      ref.invalidate(categoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$name" deleted'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
          },
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withAlpha(77),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No categories found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: _showAddCategoryDialog,
                        child: const Text('Add Category'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final id = cat['id'] as String;
                  final name = cat['name'] as String;
                  final iconName = cat['icon'] as String?;
                  final isDefault = cat['is_default'] == true;

                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.xlAll,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(77),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(128),
                          borderRadius: AppRadius.lgAll,
                        ),
                        child: Icon(
                          _getIconData(iconName),
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isDefault ? 'Default Category' : 'Custom Category',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                      trailing: isDefault
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Text(
                                'System',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(153),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => _deleteCategory(id, name),
                            ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: index * 40),
                        duration: 250.ms,
                      );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Error loading categories: $err'),
            ),
          ),
        ),
      ),
    );
  }
}
