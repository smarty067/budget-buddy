import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/emi_calculation.dart';
import '../../../app/theme/design_tokens.dart';

class AmortizationSheet extends StatelessWidget {
  final EmiCalculation calculation;

  const AmortizationSheet({super.key, required this.calculation});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final schedule = calculation.getAmortizationSchedule();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
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
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amortization Schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Year-by-year principal & interest payoff',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariantDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('YEAR', style: TextStyle(color: AppColors.mint, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('PRINCIPAL', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('INTEREST', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('BALANCE', textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: schedule.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder, height: 1),
              itemBuilder: (context, index) {
                final row = schedule[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Yr ${row.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          currencyFormatter.format(row.principalPaid),
                          style: const TextStyle(
                            color: AppColors.mint,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          currencyFormatter.format(row.interestPaid),
                          style: TextStyle(
                            color: AppColors.onSurfaceVariantDark,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          currencyFormatter.format(row.remainingBalance),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
