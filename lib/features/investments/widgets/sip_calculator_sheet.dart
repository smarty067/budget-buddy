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
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
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
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SIP Return Calculator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Projected Value Hero Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0FC27B), Color(0xFF2EE8A5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPECTED MATURITY WEALTH',
                    style: TextStyle(
                      color: AppColors.heroDarkText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(totalValue.round()),
                    style: const TextStyle(
                      color: AppColors.heroDarkText,
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
                          color: AppColors.heroDarkText.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Gains: +${_currencyFormat.format(estimatedReturns.round())}',
                        style: const TextStyle(
                          color: AppColors.heroDarkText,
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
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                display,
                style: const TextStyle(color: AppColors.mint, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.mint,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: Colors.white,
            overlayColor: AppColors.mint.withOpacity(0.2),
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
