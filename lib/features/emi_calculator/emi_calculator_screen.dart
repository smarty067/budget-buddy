import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/models/emi_calculation.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/emi_provider.dart';
import '../../core/services/emi_service.dart';
import 'widgets/amortization_sheet.dart';

/// Pixel-perfect Loan / EMI Calculator dynamically supporting Light & Dark themes
/// with direct numeric typing inputs, live synchronized sliders, and quick presets.
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

  final _numberFormat = NumberFormat('#,##,###', 'en_IN');

  late final TextEditingController _amountController;
  late final TextEditingController _tenureController;
  late final TextEditingController _rateController;

  late final FocusNode _amountFocus;
  late final FocusNode _tenureFocus;
  late final FocusNode _rateFocus;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(currentEmiProvider);
    _amountController = TextEditingController(text: _formatNumber(initial.loanAmount.round()));
    _tenureController = TextEditingController(text: initial.tenureYears.toString());
    _rateController = TextEditingController(text: initial.interestRate.toString());

    _amountFocus = FocusNode()..addListener(_onAmountFocusChange);
    _tenureFocus = FocusNode()..addListener(_onTenureFocusChange);
    _rateFocus = FocusNode()..addListener(_onRateFocusChange);
  }

  @override
  void dispose() {
    _amountFocus.removeListener(_onAmountFocusChange);
    _tenureFocus.removeListener(_onTenureFocusChange);
    _rateFocus.removeListener(_onRateFocusChange);
    _amountFocus.dispose();
    _tenureFocus.dispose();
    _rateFocus.dispose();
    _amountController.dispose();
    _tenureController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String _formatNumber(num value) {
    return _numberFormat.format(value);
  }

  void _onAmountFocusChange() {
    if (!_amountFocus.hasFocus) {
      final current = ref.read(currentEmiProvider).loanAmount;
      _amountController.text = _formatNumber(current.round());
    }
  }

  void _onTenureFocusChange() {
    if (!_tenureFocus.hasFocus) {
      final current = ref.read(currentEmiProvider).tenureYears;
      _tenureController.text = current.toString();
    }
  }

  void _onRateFocusChange() {
    if (!_rateFocus.hasFocus) {
      final current = ref.read(currentEmiProvider).interestRate;
      _rateController.text = current.toString();
    }
  }

  void _onAmountTyped(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = double.tryParse(clean) ?? 0;
    if (val > 0) {
      ref.read(currentEmiProvider.notifier).updateAmount(val);
    }
  }

  void _onAmountSlider(double val) {
    ref.read(currentEmiProvider.notifier).updateAmount(val);
    _amountController.text = _formatNumber(val.round());
  }

  void _onTenureTyped(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = int.tryParse(clean) ?? 0;
    if (val > 0 && val <= 50) {
      ref.read(currentEmiProvider.notifier).updateTenure(val);
    }
  }

  void _onTenureSlider(double val) {
    final years = val.round();
    ref.read(currentEmiProvider.notifier).updateTenure(years);
    _tenureController.text = years.toString();
  }

  void _onRateTyped(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(clean) ?? 0;
    if (val > 0 && val <= 50) {
      ref.read(currentEmiProvider.notifier).updateInterestRate(val);
    }
  }

  void _onRateSlider(double val) {
    final rate = double.parse(val.toStringAsFixed(1));
    ref.read(currentEmiProvider.notifier).updateInterestRate(rate);
    _rateController.text = rate.toString();
  }

  void _applyAmountPreset(double amount) {
    ref.read(currentEmiProvider.notifier).updateAmount(amount);
    _amountController.text = _formatNumber(amount.round());
  }

  void _applyTenurePreset(int years) {
    ref.read(currentEmiProvider.notifier).updateTenure(years);
    _tenureController.text = years.toString();
  }

  void _applyRatePreset(double rate) {
    ref.read(currentEmiProvider.notifier).updateInterestRate(rate);
    _rateController.text = rate.toString();
  }

  void _showSavedHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SavedCalculationsModal(
        onSelect: (calc) {
          ref.read(currentEmiProvider.notifier).setCalculation(calc);
          _amountController.text = _formatNumber(calc.loanAmount.round());
          _tenureController.text = calc.tenureYears.toString();
          _rateController.text = calc.interestRate.toString();
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
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
                      icon: Icons.history_rounded,
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

                      // ── EDITABLE PARAMETER 1: LOAN AMOUNT ──
                      _EditableParamCard(
                        label: 'Loan Amount Required',
                        controller: _amountController,
                        focusNode: _amountFocus,
                        prefixText: '₹ ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        sliderValue: emiState.loanAmount,
                        sliderMin: 10000,
                        sliderMax: 10000000,
                        sliderDivisions: 1000,
                        minLabel: '₹10K',
                        maxLabel: '₹1 Cr',
                        onTextChanged: _onAmountTyped,
                        onSliderChanged: _onAmountSlider,
                        presets: const [
                          _PresetOption(label: '₹1L', value: 100000),
                          _PresetOption(label: '₹5L', value: 500000),
                          _PresetOption(label: '₹10L', value: 1000000),
                          _PresetOption(label: '₹25L', value: 2500000),
                          _PresetOption(label: '₹50L', value: 5000000),
                          _PresetOption(label: '₹1Cr', value: 10000000),
                        ],
                        selectedPresetValue: emiState.loanAmount,
                        onPresetSelected: (val) => _applyAmountPreset(val.toDouble()),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── EDITABLE PARAMETER 2: REPAYMENT TERM ──
                      _EditableParamCard(
                        label: 'Repayment Term',
                        controller: _tenureController,
                        focusNode: _tenureFocus,
                        suffixText: emiState.tenureYears == 1 ? ' Year' : ' Years',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        sliderValue: emiState.tenureYears.toDouble(),
                        sliderMin: 1,
                        sliderMax: 30,
                        sliderDivisions: 29,
                        minLabel: '1 Yr',
                        maxLabel: '30 Yrs',
                        onTextChanged: _onTenureTyped,
                        onSliderChanged: _onTenureSlider,
                        presets: const [
                          _PresetOption(label: '1Y', value: 1),
                          _PresetOption(label: '3Y', value: 3),
                          _PresetOption(label: '5Y', value: 5),
                          _PresetOption(label: '10Y', value: 10),
                          _PresetOption(label: '15Y', value: 15),
                          _PresetOption(label: '20Y', value: 20),
                          _PresetOption(label: '30Y', value: 30),
                        ],
                        selectedPresetValue: emiState.tenureYears.toDouble(),
                        onPresetSelected: (val) => _applyTenurePreset(val.round()),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── EDITABLE PARAMETER 3: INTEREST RATE ──
                      _EditableParamCard(
                        label: 'Interest Rate',
                        controller: _rateController,
                        focusNode: _rateFocus,
                        suffixText: '% p.a.',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        sliderValue: emiState.interestRate,
                        sliderMin: 1.0,
                        sliderMax: 25.0,
                        sliderDivisions: 240,
                        minLabel: '1.0%',
                        maxLabel: '25.0%',
                        onTextChanged: _onRateTyped,
                        onSliderChanged: _onRateSlider,
                        presets: const [
                          _PresetOption(label: '7.5%', value: 7.5),
                          _PresetOption(label: '8.5%', value: 8.5),
                          _PresetOption(label: '9.5%', value: 9.5),
                          _PresetOption(label: '10.5%', value: 10.5),
                          _PresetOption(label: '12.0%', value: 12.0),
                          _PresetOption(label: '15.0%', value: 15.0),
                        ],
                        selectedPresetValue: emiState.interestRate,
                        onPresetSelected: (val) => _applyRatePreset(val.toDouble()),
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

class _PresetOption {
  final String label;
  final num value;

  const _PresetOption({required this.label, required this.value});
}

class _EditableParamCard extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? prefixText;
  final String? suffixText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final int? sliderDivisions;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<double> onSliderChanged;
  final List<_PresetOption> presets;
  final num selectedPresetValue;
  final ValueChanged<num> onPresetSelected;

  const _EditableParamCard({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.prefixText,
    this.suffixText,
    required this.keyboardType,
    this.inputFormatters,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    this.sliderDivisions,
    required this.minLabel,
    required this.maxLabel,
    required this.onTextChanged,
    required this.onSliderChanged,
    required this.presets,
    required this.selectedPresetValue,
    required this.onPresetSelected,
  });

  @override
  State<_EditableParamCard> createState() => _EditableParamCardState();
}

class _EditableParamCardState extends State<_EditableParamCard> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: _isFocused ? colors.accentMint : colors.surfaceBorder,
          width: _isFocused ? 1.6 : 1.2,
        ),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row with Label & Interactive Typing Input ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type or drag slider',
                      style: TextStyle(
                        color: colors.textSecondary.withAlpha(180),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Typing Input Box
              GestureDetector(
                onTap: () {
                  widget.focusNode.requestFocus();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _isFocused ? colors.accentMint : colors.surfaceBorder,
                      width: _isFocused ? 1.5 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.prefixText != null)
                        Text(
                          widget.prefixText!,
                          style: TextStyle(
                            color: colors.accentMint,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      Flexible(
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            keyboardType: widget.keyboardType,
                            inputFormatters: widget.inputFormatters,
                            textAlign: TextAlign.right,
                            cursorColor: colors.accentMint,
                            style: TextStyle(
                              color: colors.accentMint,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Manrope',
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                            onChanged: widget.onTextChanged,
                          ),
                        ),
                      ),
                      if (widget.suffixText != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Text(
                            widget.suffixText!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: _isFocused ? colors.accentMint : colors.textSecondary.withAlpha(120),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Slider ──
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.sliderActive,
              inactiveTrackColor: colors.sliderInactive,
              thumbColor: colors.sliderThumb,
              overlayColor: colors.sliderActive.withAlpha(51),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
                elevation: 3,
              ),
            ),
            child: Slider(
              value: widget.sliderValue.clamp(widget.sliderMin, widget.sliderMax),
              min: widget.sliderMin,
              max: widget.sliderMax,
              divisions: widget.sliderDivisions,
              onChanged: widget.onSliderChanged,
            ),
          ),

          // ── Min & Max Labels ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.minLabel,
                  style: TextStyle(
                    color: colors.textSecondary.withAlpha(180),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.maxLabel,
                  style: TextStyle(
                    color: colors.textSecondary.withAlpha(180),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Quick Preset Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.presets.map((preset) {
                final isSelected = (widget.selectedPresetValue - preset.value).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => widget.onPresetSelected(preset.value),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentMint : colors.chipBackground,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? colors.accentMint : colors.surfaceBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        preset.label,
                        style: TextStyle(
                          color: isSelected ? colors.textOnGradient : colors.textPrimary,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
