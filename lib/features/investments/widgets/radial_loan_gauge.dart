import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/design_tokens.dart';

/// Radial tick mark loan / portfolio balance gauge matching reference image 1.
class RadialLoanGauge extends StatelessWidget {
  final double balance;
  final String nextDueDate;
  final int currentInstallment;
  final int totalInstallments;
  final VoidCallback onViewDetails;
  final VoidCallback onSecondaryAction;
  final String secondaryActionLabel;

  const RadialLoanGauge({
    super.key,
    required this.balance,
    required this.nextDueDate,
    required this.currentInstallment,
    required this.totalInstallments,
    required this.onViewDetails,
    required this.onSecondaryAction,
    this.secondaryActionLabel = 'CALCULATE EMI',
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 0,
    );

    final progressRatio = totalInstallments > 0
        ? (currentInstallment / totalInstallments).clamp(0.0, 1.0)
        : 0.2;

    return Column(
      children: [
        // ── Radial Gauge with Center Information ──
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(300, 300),
                painter: _RadialTicksPainter(
                  progressRatio: progressRatio,
                  activeColor: AppColors.mint,
                  inactiveColor: AppColors.cardBorder.withOpacity(0.8),
                  totalTicks: 56,
                ),
              ),
              // Center Labels
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'LOAN BALANCE',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariantDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          color: AppColors.mint,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(balance.round()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Next Due : $nextDueDate',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariantDark.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentInstallment/$totalInstallments',
                    style: const TextStyle(
                      color: AppColors.mint,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Action Buttons Row ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              // View Details
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.cardDark,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text(
                      'VIEW DETAILS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Secondary Action (Calculate EMI / Save Calculation)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onSecondaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: AppColors.heroDarkText,
                      elevation: 0,
                      shadowColor: AppColors.mint.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Text(
                      secondaryActionLabel,
                      style: const TextStyle(
                        color: AppColors.heroDarkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadialTicksPainter extends CustomPainter {
  final double progressRatio;
  final Color activeColor;
  final Color inactiveColor;
  final int totalTicks;

  _RadialTicksPainter({
    required this.progressRatio,
    required this.activeColor,
    required this.inactiveColor,
    required this.totalTicks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const tickLength = 16.0;
    final activeCount = (totalTicks * progressRatio).round();

    // Start angle from top (-PI/2) and rotate clockwise
    const startAngle = -math.pi / 2;
    final angleStep = (2 * math.pi) / totalTicks;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glowing shadow for active ticks
    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.35)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < totalTicks; i++) {
      final angle = startAngle + (i * angleStep);
      final outerX = center.dx + radius * math.cos(angle);
      final outerY = center.dy + radius * math.sin(angle);
      final innerX = center.dx + (radius - tickLength) * math.cos(angle);
      final innerY = center.dy + (radius - tickLength) * math.sin(angle);

      final p1 = Offset(innerX, innerY);
      final p2 = Offset(outerX, outerY);

      if (i <= activeCount) {
        canvas.drawLine(p1, p2, glowPaint);
        canvas.drawLine(p1, p2, activePaint);
      } else {
        canvas.drawLine(p1, p2, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadialTicksPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
