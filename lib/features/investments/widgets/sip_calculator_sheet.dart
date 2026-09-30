import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/models/investment.dart';

class SipCalculatorSheet extends StatefulWidget {
  const SipCalculatorSheet({super.key});

  @override
  State<SipCalculatorSheet> createState() => _SipCalculatorSheetState();
}

class _SipCalculatorSheetState extends State<SipCalculatorSheet> {
  double _monthlyInvestment = 5000;
  double _expectedReturnRate = 12.0;
  int _years = 10;

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  final _numberFormat = NumberFormat('#,##,###', 'en_IN');

  late final TextEditingController _sipController;
  late final TextEditingController _returnController;
  late final TextEditingController _yearsController;

  late final FocusNode _sipFocus;
  late final FocusNode _returnFocus;
  late final FocusNode _yearsFocus;

  @override
  void initState() {
    super.initState();
    _sipController = TextEditingController(text: _numberFormat.format(_monthlyInvestment.round()));
    _returnController = TextEditingController(text: _expectedReturnRate.toString());
    _yearsController = TextEditingController(text: _years.toString());

    _sipFocus = FocusNode()..addListener(() {
      if (!_sipFocus.hasFocus) {
        _sipController.text = _numberFormat.format(_monthlyInvestment.round());
      }
    });
    _returnFocus = FocusNode()..addListener(() {
      if (!_returnFocus.hasFocus) {
        _returnController.text = _expectedReturnRate.toString();
      }
    });
    _yearsFocus = FocusNode()..addListener(() {
      if (!_yearsFocus.hasFocus) {
        _yearsController.text = _years.toString();
      }
    });
  }

  @override
  void dispose() {
    _sipFocus.dispose();
    _returnFocus.dispose();
    _yearsFocus.dispose();
    _sipController.dispose();
    _returnController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _onSipTyped(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = double.tryParse(clean) ?? 0;
    if (val > 0) {
      setState(() => _monthlyInvestment = val);
    }
  }

  void _onSipSlider(double val) {
    setState(() {
      _monthlyInvestment = val;
      _sipController.text = _numberFormat.format(val.round());
    });
  }

  void _onReturnTyped(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(clean) ?? 0;
    if (val > 0 && val <= 50) {
      setState(() => _expectedReturnRate = val);
    }
  }

  void _onReturnSlider(double val) {
    final rounded = double.parse(val.toStringAsFixed(1));
    setState(() {
      _expectedReturnRate = rounded;
      _returnController.text = rounded.toString();
    });
  }

  void _onYearsTyped(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = int.tryParse(clean) ?? 0;
    if (val > 0 && val <= 50) {
      setState(() => _years = val);
    }
  }

  void _onYearsSlider(double val) {
    final rounded = val.round();
    setState(() {
      _years = rounded;
      _yearsController.text = rounded.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final results = Investment.calculateSipReturns(
      monthlyInvestment: _monthlyInvestment,
      annualRate: _expectedReturnRate,
      years: _years,
    );

    final totalInvested = results['totalInvested']!;
    final estimatedReturns = results['estimatedReturns']!;
    final totalValue = results['totalValue']!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          border: Border(top: BorderSide(color: colors.surfaceBorder, width: 1.5)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SIP Return Calculator',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Projected Value Hero Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: colors.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accentMint.withAlpha(64),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPECTED MATURITY WEALTH',
                      style: TextStyle(
                        color: colors.textOnGradient.withAlpha(210),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(totalValue.round()),
                      style: TextStyle(
                        color: colors.textOnGradient,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invested: ${_currencyFormat.format(totalInvested.round())}',
                          style: TextStyle(
                            color: colors.textOnGradient.withAlpha(230),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Gains: +${_currencyFormat.format(estimatedReturns.round())}',
                          style: TextStyle(
                            color: colors.textOnGradient,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Editable Slider 1: Monthly Investment
              _buildEditableSliderRow(
                colors: colors,
                label: 'Monthly Investment',
                controller: _sipController,
                focusNode: _sipFocus,
                prefix: '₹ ',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                value: _monthlyInvestment,
                min: 500,
                max: 100000,
                divisions: 199,
                minLabel: '₹500',
                maxLabel: '₹1 Lakh',
                onTextChanged: _onSipTyped,
                onSliderChanged: _onSipSlider,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Editable Slider 2: Expected CAGR %
              _buildEditableSliderRow(
                colors: colors,
                label: 'Expected Return Rate (p.a.)',
                controller: _returnController,
                focusNode: _returnFocus,
                suffix: '%',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                value: _expectedReturnRate,
                min: 1.0,
                max: 30.0,
                divisions: 290,
                minLabel: '1.0%',
                maxLabel: '30.0%',
                onTextChanged: _onReturnTyped,
                onSliderChanged: _onReturnSlider,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Editable Slider 3: Time Period (Years)
              _buildEditableSliderRow(
                colors: colors,
                label: 'Time Period',
                controller: _yearsController,
                focusNode: _yearsFocus,
                suffix: _years == 1 ? ' Yr' : ' Yrs',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                value: _years.toDouble(),
                min: 1,
                max: 35,
                divisions: 34,
                minLabel: '1 Yr',
                maxLabel: '35 Yrs',
                onTextChanged: _onYearsTyped,
                onSliderChanged: _onYearsSlider,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableSliderRow({
    required BudgetColors colors,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    String? prefix,
    String? suffix,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<String> onTextChanged,
    required ValueChanged<double> onSliderChanged,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => focusNode.requestFocus(),
              child: Container(
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isFocused ? colors.accentMint : colors.surfaceBorder,
                    width: isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (prefix != null)
                      Text(
                        prefix,
                        style: TextStyle(color: colors.accentMint, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    Flexible(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: keyboardType,
                          inputFormatters: inputFormatters,
                          textAlign: TextAlign.right,
                          cursorColor: colors.accentMint,
                          style: TextStyle(
                            color: colors.accentMint,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Manrope',
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                            border: InputBorder.none,
                          ),
                          onChanged: onTextChanged,
                        ),
                      ),
                    ),
                    if (suffix != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          suffix,
                          style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(width: 3),
                    Icon(Icons.edit_outlined, size: 12, color: colors.accentMint.withAlpha(150)),
                  ],
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
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onSliderChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: TextStyle(color: colors.textSecondary.withAlpha(160), fontSize: 10)),
              Text(maxLabel, style: TextStyle(color: colors.textSecondary.withAlpha(160), fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
