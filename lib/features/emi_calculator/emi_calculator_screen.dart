import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/models/emi_calculation.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/emi_provider.dart';
import '../../core/services/emi_service.dart';
import 'widgets/amortization_sheet.dart';

/// Pixel-perfect Loan / EMI Calculator dynamically supporting Light & Dark themes.
class EmiCalculatorScreen extends ConsumerStatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  ConsumerState<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends ConsumerState<EmiCalculatorScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  bool _isSaving = false;

  void _showSavedHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SavedCalculationsModal(
        onSelect: (calc) {
          ref.read(currentEmiProvider.notifier).setCalculation(calc);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAmortization() {
    final state = ref.read(currentEmiProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AmortizationSheet(calculation: state.calculation),
    );
  }

  Future<void> _saveCalculation() async {
    setState(() => _isSaving = true);
    final state = ref.read(currentEmiProvider);
    final isGuest = ref.read(isGuestProvider);
    final colors = context.colors;

    final title = 'Loan ₹${_currencyFormat.format(state.loanAmount).replaceAll('₹', '')} @ ${state.interestRate}%';
    final calcToSave = EmiCalculation(
      title: title,
      loanAmount: state.loanAmount,
      interestRate: state.interestRate,
      tenureYears: state.tenureYears,
      monthlyEmi: state.calculation.monthlyEmi,
      totalInterest: state.calculation.totalInterest,
      totalPayment: state.calculation.totalPayment,
    );

    await EmiService.saveCalculation(calcToSave, isGuest: isGuest);
    ref.invalidate(emiCalculationsProvider);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: colors.gainGreen, size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Calculation saved successfully!',
                style: TextStyle(color: colors.textPrimary),
              ),
            ],
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: colors.surfaceBorder),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emiState = ref.watch(currentEmiProvider);
    final calc = emiState.calculation;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _CircularIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Text(
                    'Loan Calculator',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  // History / Info button
                  _CircularIconButton(
                    icon: Icons.info_outline_rounded,
                    onTap: _showSavedHistoryModal,
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),

                    // ── HERO GRADIENT CARD ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: colors.heroGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accentMint.withAlpha(64),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MONTHLY PAYABLE EMI',
                            style: TextStyle(
                              color: colors.textOnGradient.withAlpha(210),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currencyFormat.format(calc.monthlyEmi.round()),
                            style: TextStyle(
                              color: colors.textOnGradient,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: colors.textOnGradient.withAlpha(230),
                                fontSize: 13,
                                fontFamily: 'Manrope',
                              ),
                              children: [
                                const TextSpan(text: 'Total payable for '),
                                TextSpan(
                                  text: '${emiState.tenureYears} ${emiState.tenureYears == 1 ? 'year' : 'years'} ${_currencyFormat.format(calc.totalPayment.round())}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── BREAKDOWN CARD ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: colors.surfaceBorder, width: 1.2),
                        boxShadow: colors.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Interest Payable',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(calc.totalInterest.round()),
                                style: TextStyle(
                                  color: colors.gainGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Divider(color: colors.surfaceBorder, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Payment',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(calc.totalPayment.round()),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── SLIDER 1: LOAN AMOUNT ──
                    _SliderSection(
                      label: 'Loan Amount Required',
                      valueDisplay: _currencyFormat.format(emiState.loanAmount.round()),
                      value: emiState.loanAmount,
                      min: 10000,
                      max: 10000000,
                      divisions: 1000,
                      onChanged: (val) {
                        ref.read(currentEmiProvider.notifier).updateAmount(val);
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── SLIDER 2: REPAYMENT TERM ──
                    _SliderSection(
                      label: 'Repayment Term',
                      valueDisplay: '${emiState.tenureYears} ${emiState.tenureYears == 1 ? 'Year' : 'Years'}',
                      value: emiState.tenureYears.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      onChanged: (val) {
                        ref.read(currentEmiProvider.notifier).updateTenure(val.round());
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── SLIDER 3: INTEREST RATE ──
                    _SliderSection(
                      label: 'Interest Rate',
                      valueDisplay: '${emiState.interestRate.toStringAsFixed(1)}%',
                      value: emiState.interestRate,
                      min: 1.0,
                      max: 25.0,
                      divisions: 240,
                      onChanged: (val) {
                        ref.read(currentEmiProvider.notifier).updateInterestRate(
                              double.parse(val.toStringAsFixed(1)),
                            );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Amortization Schedule Link ──
                    Center(
                      child: TextButton.icon(
                        onPressed: _showAmortization,
                        icon: Icon(Icons.table_chart_outlined, color: colors.accentMint, size: 18),
                        label: Text(
                          'View Amortization Schedule',
                          style: TextStyle(
                            color: colors.accentMint,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // ── BOTTOM PROCEED / SAVE BUTTON ──
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                top: AppSpacing.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentMint,
                    foregroundColor: colors.textOnGradient,
                    elevation: 0,
                    shadowColor: colors.accentMint.withAlpha(128),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.textOnGradient),
                          ),
                        )
                      : Text(
                          'SAVE CALCULATION',
                          style: TextStyle(
                            color: colors.textOnGradient,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircularIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surfaceBorder, width: 1.2),
        boxShadow: colors.cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.textPrimary, size: 22),
        onPressed: onTap,
        splashRadius: 22,
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  final String label;
  final String valueDisplay;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SliderSection({
    required this.label,
    required this.valueDisplay,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.surfaceBorder, width: 1.2),
              ),
              child: Text(
                valueDisplay,
                style: TextStyle(
                  color: colors.accentMint,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.sliderActive,
            inactiveTrackColor: colors.sliderInactive,
            thumbColor: colors.sliderThumb,
            overlayColor: colors.sliderActive.withAlpha(51),
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 9,
              elevation: 4,
            ),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SavedCalculationsModal extends ConsumerWidget {
  final ValueChanged<EmiCalculation> onSelect;

  const _SavedCalculationsModal({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculationsAsync = ref.watch(emiCalculationsProvider);
    final colors = context.colors;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(top: BorderSide(color: colors.surfaceBorder, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
            'Saved Calculations',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          calculationsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'No saved calculations found',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.calculate_outlined, color: colors.accentMint, size: 40),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No saved calculations yet.',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return InkWell(
                      onTap: () => onSelect(item),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: colors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.chipBackground,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.account_balance_wallet_outlined, color: colors.accentMint, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'EMI: ${currencyFormat.format(item.monthlyEmi.round())}/mo • ${item.tenureYears} yrs',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, color: colors.textSecondary.withAlpha(128), size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
