import 'package:flutter/material.dart';
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

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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

            // Slider 1: Monthly Investment
            _buildSliderRow(
              colors: colors,
              label: 'Monthly Investment',
              display: _currencyFormat.format(_monthlyInvestment.round()),
              value: _monthlyInvestment,
              min: 500,
              max: 100000,
              divisions: 199,
              onChanged: (val) => setState(() => _monthlyInvestment = val),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Slider 2: Expected CAGR %
            _buildSliderRow(
              colors: colors,
              label: 'Expected Return Rate (p.a.)',
              display: '${_expectedReturnRate.toStringAsFixed(1)}%',
              value: _expectedReturnRate,
              min: 5.0,
              max: 30.0,
              divisions: 250,
              onChanged: (val) => setState(() => _expectedReturnRate = double.parse(val.toStringAsFixed(1))),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Slider 3: Time Period (Years)
            _buildSliderRow(
              colors: colors,
              label: 'Time Period',
              display: '$_years ${_years == 1 ? 'Year' : 'Years'}',
              value: _years.toDouble(),
              min: 1,
              max: 35,
              divisions: 34,
              onChanged: (val) => setState(() => _years = val.round()),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required BudgetColors colors,
    required String label,
    required String display,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.surfaceBorder),
              ),
              child: Text(
                display,
                style: TextStyle(color: colors.accentMint, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.sliderActive,
            inactiveTrackColor: colors.sliderInactive,
            thumbColor: colors.sliderThumb,
            overlayColor: colors.sliderActive.withAlpha(51),
            trackHeight: 3.5,
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
