import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/services/budget_service.dart';

/// Bottom sheet dialog to create a savings goal or set a category budget.
class AddBudgetSheet extends ConsumerStatefulWidget {
  final bool initialIsGoal; // true for Savings Goal, false for Category Budget

  const AddBudgetSheet({
    super.key,
    this.initialIsGoal = true,
  });

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late bool _isGoal;
  bool _isSaving = false;

  // Form Fields
  final _amountController = TextEditingController();
  final _titleController = TextEditingController(); // For goals
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 90)); // default target: 90 days

  @override
  void initState() {
    super.initState();
    _isGoal = widget.initialIsGoal;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.accentGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final isGuest = ref.read(isGuestProvider);

    try {
      if (_isGoal) {
        if (_titleController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a goal title')),
          );
          return;
        }

        await BudgetService.createGoal(
          title: _titleController.text.trim(),
          targetAmount: amount,
          targetDate: _selectedDate,
          isGuest: isGuest,
        );
        ref.invalidate(savingsGoalsProvider);
      } else {
        await BudgetService.createBudget(
          amount: amount,
          categoryId: _selectedCategoryId, // null means overall budget
          isGuest: isGuest,
        );
        ref.invalidate(budgetsProvider);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isGoal ? 'Savings Goal created!' : 'Budget updated!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  IconData _getIconData(String iconName) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title & Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isGoal ? 'Add Savings Goal' : 'Set Category Budget',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                      borderRadius: AppRadius.xlAll,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _ToggleButton(
                          label: 'Goal',
                          isActive: _isGoal,
                          activeColor: theme.colorScheme.primary,
                          onTap: () => setState(() => _isGoal = true),
                        ),
                        _ToggleButton(
                          label: 'Budget',
                          isActive: !_isGoal,
                          activeColor: theme.colorScheme.primary,
                          onTap: () => setState(() => _isGoal = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title Input for Goals
              if (_isGoal) ...[
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g. Diwali Savings 🪔',
                    prefixIcon: Icon(Icons.star_outline_rounded),
                  ),
                  validator: (value) {
                    if (_isGoal && (value == null || value.trim().isEmpty)) {
                      return 'Goal title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _isGoal ? 'Target Amount' : 'Budget Amount',
                  hintText: '0.00',
                  prefixText: '${AppConstants.currencySymbol} ',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date Picker for Savings Goal target
              if (_isGoal) ...[
                InkWell(
                  onTap: () => _selectTargetDate(context),
                  borderRadius: AppRadius.mdAll,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(102),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 20, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Target Date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Category Selector for Budgets
              if (!_isGoal) ...[
                Text(
                  'Budget Category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 52,
                  child: categoriesAsync.when(
                    data: (categories) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          // Insert "Overall" budget option at index 0
                          if (index == 0) {
                            final isSelected = _selectedCategoryId == null;
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: ChoiceChip(
                                label: const Row(
                                  children: [
                                    Icon(Icons.all_inclusive, size: 16),
                                    SizedBox(width: AppSpacing.xs),
                                    Text('Overall'),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: theme.colorScheme.primary,
                                labelStyle: theme.textTheme.labelMedium?.copyWith(
                                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategoryId = null;
                                  });
                                },
                              ),
                            );
                          }

                          final cat = categories[index - 1];
                          final id = cat['id'] as String;
                          final name = cat['name'] as String;
                          final isSelected = _selectedCategoryId == id;

                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: ChoiceChip(
                              label: Row(
                                children: [
                                  Icon(
                                    _getIconData(cat['icon'] as String),
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(name),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: theme.colorScheme.primary,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategoryId = selected ? id : null;
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => Text('Error loading categories: $err'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.xlAll,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isGoal ? 'Create Goal' : 'Save Budget',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: AppRadius.xlAll,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
