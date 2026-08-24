import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

/// A glassmorphic card with frosted-glass blur effect.
///
/// Used selectively — hero illustrations, AI chat bubbles, floating badges —
/// **never** on core numeric/balance displays (per PRD).
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurIntensity;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.borderRadius = AppRadius.xl,
    this.blurIntensity = AppGlass.blurIntensity,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.glassDark : AppColors.glassLight);
    final border = borderColor ??
        (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: border,
              width: AppGlass.borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
