import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/models/investment.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/services/investment_service.dart';

class AddInvestmentSheet extends ConsumerStatefulWidget {
  final Investment? existing;

  const AddInvestmentSheet({super.key, this.existing});

  @override
  ConsumerState<AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends ConsumerState<AddInvestmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _investedController;
  late final TextEditingController _currentValController;
  late final TextEditingController _sipController;
  late InvestmentType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameController = TextEditingController(text: item?.name ?? '');
    _investedController = TextEditingController(text: item != null ? item.investedAmount.toStringAsFixed(0) : '');
    _currentValController = TextEditingController(text: item != null ? item.currentValue.toStringAsFixed(0) : '');
    _sipController = TextEditingController(text: item != null ? item.monthlyContribution.toStringAsFixed(0) : '0');
    _selectedType = item?.type ?? InvestmentType.sip;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _investedController.dispose();
    _currentValController.dispose();
    _sipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final isGuest = ref.read(isGuestProvider);
    final invested = double.tryParse(_investedController.text.trim()) ?? 0.0;
    final current = double.tryParse(_currentValController.text.trim()) ?? invested;
    final sip = double.tryParse(_sipController.text.trim()) ?? 0.0;

    final investment = Investment(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      investedAmount: invested,
      currentValue: current,
      monthlyContribution: sip,
      startDate: widget.existing?.startDate ?? DateTime.now(),
    );

    await InvestmentService.saveInvestment(investment, isGuest: isGuest);
    ref.invalidate(investmentsProvider);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(top: BorderSide(color: colors.surfaceBorder, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.existing == null ? 'Add Investment / Asset' : 'Edit Investment',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Investment Type Dropdown
              DropdownButtonFormField<InvestmentType>(
                initialValue: _selectedType,
                dropdownColor: colors.surface,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Investment Category',
                  labelStyle: TextStyle(color: colors.textSecondary),
                ),
                items: InvestmentType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.label, style: TextStyle(color: colors.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Name Field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Investment Name (e.g. Parag Parikh Flexi Cap)',
                  labelStyle: TextStyle(color: colors.textSecondary),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Invested Amount
              TextFormField(
                controller: _investedController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Invested Amount (₹)',
                  prefixText: '₹ ',
                  labelStyle: TextStyle(color: colors.textSecondary),
                ),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Current Value
              TextFormField(
                controller: _currentValController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Current Value (₹)',
                  prefixText: '₹ ',
                  labelStyle: TextStyle(color: colors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Monthly SIP
              TextFormField(
                controller: _sipController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Monthly SIP / Contribution (₹)',
                  prefixText: '₹ ',
                  labelStyle: TextStyle(color: colors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentMint,
                  foregroundColor: colors.textOnGradient,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.textOnGradient),
                        ),
                      )
                    : Text(
                        widget.existing == null ? 'ADD TO PORTFOLIO' : 'SAVE CHANGES',
                        style: TextStyle(
                          color: colors.textOnGradient,
                          fontWeight: FontWeight.bold,
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
