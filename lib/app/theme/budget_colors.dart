import 'package:flutter/material.dart';

/// Semantic color tokens for Budget Buddy supporting both Light and Dark themes.
@immutable
class BudgetColors extends ThemeExtension<BudgetColors> {
  final Color background;
  final Color surface;
  final Color surfaceBorder;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnGradient;
  final Color primaryEmerald;
  final Color accentMint;
  final Color gainGreen;
  final Color lossRed;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color bannerGradientStart;
  final Color bannerGradientEnd;
  final Color chipBackground;
  final Color chipBorder;
  final Color sliderActive;
  final Color sliderInactive;
  final Color sliderThumb;
  final Color ringTickActive;
  final Color ringTickInactive;
  final List<BoxShadow> cardShadow;

  const BudgetColors({
    required this.background,
    required this.surface,
    required this.surfaceBorder,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnGradient,
    required this.primaryEmerald,
    required this.accentMint,
    required this.gainGreen,
    required this.lossRed,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.bannerGradientStart,
    required this.bannerGradientEnd,
    required this.chipBackground,
    required this.chipBorder,
    required this.sliderActive,
    required this.sliderInactive,
    required this.sliderThumb,
    required this.ringTickActive,
    required this.ringTickInactive,
    required this.cardShadow,
  });

  /// Dark theme semantic palette (Reference dark-emerald fintech look)
  static const dark = BudgetColors(
    background: Color(0xFF0B0F14),
    surface: Color(0xFF141A22),
    surfaceBorder: Color(0xFF1E2630),
    surfaceSubtle: Color(0xFF18202A),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textOnGradient: Color(0xFF053B2A),
    primaryEmerald: Color(0xFF0FC27B),
    accentMint: Color(0xFF2EE8A5),
    gainGreen: Color(0xFF2EE8A5),
    lossRed: Color(0xFFFFB4AB),
    heroGradientStart: Color(0xFF0FC27B),
    heroGradientEnd: Color(0xFF2EE8A5),
    bannerGradientStart: Color(0xFF0F5A3D),
    bannerGradientEnd: Color(0xFF141A22),
    chipBackground: Color(0x262EE8A5),
    chipBorder: Color(0x4D2EE8A5),
    sliderActive: Color(0xFF2EE8A5),
    sliderInactive: Color(0xFF1E2630),
    sliderThumb: Color(0xFFFFFFFF),
    ringTickActive: Color(0xFF2EE8A5),
    ringTickInactive: Color(0xFF1E2630),
    cardShadow: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );

  /// Light theme semantic palette (Fresh emerald fintech look)
  static const light = BudgetColors(
    background: Color(0xFFF4FBF8),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFDCEFE6),
    surfaceSubtle: Color(0xFFEDF7F2),
    textPrimary: Color(0xFF0B1F17),
    textSecondary: Color(0xFF5B7268),
    textOnGradient: Color(0xFF053B2A),
    primaryEmerald: Color(0xFF006C49),
    accentMint: Color(0xFF0FC27B),
    gainGreen: Color(0xFF00875A),
    lossRed: Color(0xFFBA1A1A),
    heroGradientStart: Color(0xFF0FC27B),
    heroGradientEnd: Color(0xFF2EE8A5),
    bannerGradientStart: Color(0xFFE2F6EC),
    bannerGradientEnd: Color(0xFFFFFFFF),
    chipBackground: Color(0x200FC27B),
    chipBorder: Color(0x4D0FC27B),
    sliderActive: Color(0xFF0FC27B),
    sliderInactive: Color(0xFFD5E4DC),
    sliderThumb: Color(0xFF0FC27B),
    ringTickActive: Color(0xFF0FC27B),
    ringTickInactive: Color(0xFFD5E4DC),
    cardShadow: [
      BoxShadow(
        color: Color(0x0F006C49),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [heroGradientStart, heroGradientEnd],
      );

  LinearGradient get bannerGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bannerGradientStart, bannerGradientEnd],
      );

  @override
  BudgetColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceBorder,
    Color? surfaceSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnGradient,
    Color? primaryEmerald,
    Color? accentMint,
    Color? gainGreen,
    Color? lossRed,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? bannerGradientStart,
    Color? bannerGradientEnd,
    Color? chipBackground,
    Color? chipBorder,
    Color? sliderActive,
    Color? sliderInactive,
    Color? sliderThumb,
    Color? ringTickActive,
    Color? ringTickInactive,
    List<BoxShadow>? cardShadow,
  }) {
    return BudgetColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnGradient: textOnGradient ?? this.textOnGradient,
      primaryEmerald: primaryEmerald ?? this.primaryEmerald,
      accentMint: accentMint ?? this.accentMint,
      gainGreen: gainGreen ?? this.gainGreen,
      lossRed: lossRed ?? this.lossRed,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      bannerGradientStart: bannerGradientStart ?? this.bannerGradientStart,
      bannerGradientEnd: bannerGradientEnd ?? this.bannerGradientEnd,
      chipBackground: chipBackground ?? this.chipBackground,
      chipBorder: chipBorder ?? this.chipBorder,
      sliderActive: sliderActive ?? this.sliderActive,
      sliderInactive: sliderInactive ?? this.sliderInactive,
      sliderThumb: sliderThumb ?? this.sliderThumb,
      ringTickActive: ringTickActive ?? this.ringTickActive,
      ringTickInactive: ringTickInactive ?? this.ringTickInactive,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  BudgetColors lerp(ThemeExtension<BudgetColors>? other, double t) {
    if (other is! BudgetColors) return this;
    return BudgetColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textOnGradient: Color.lerp(textOnGradient, other.textOnGradient, t)!,
      primaryEmerald: Color.lerp(primaryEmerald, other.primaryEmerald, t)!,
      accentMint: Color.lerp(accentMint, other.accentMint, t)!,
      gainGreen: Color.lerp(gainGreen, other.gainGreen, t)!,
      lossRed: Color.lerp(lossRed, other.lossRed, t)!,
      heroGradientStart: Color.lerp(heroGradientStart, other.heroGradientStart, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      bannerGradientStart: Color.lerp(bannerGradientStart, other.bannerGradientStart, t)!,
      bannerGradientEnd: Color.lerp(bannerGradientEnd, other.bannerGradientEnd, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t)!,
      sliderActive: Color.lerp(sliderActive, other.sliderActive, t)!,
      sliderInactive: Color.lerp(sliderInactive, other.sliderInactive, t)!,
      sliderThumb: Color.lerp(sliderThumb, other.sliderThumb, t)!,
      ringTickActive: Color.lerp(ringTickActive, other.ringTickActive, t)!,
      ringTickInactive: Color.lerp(ringTickInactive, other.ringTickInactive, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

/// Convenient extension on BuildContext to access BudgetColors easily
extension BudgetThemeContext on BuildContext {
  BudgetColors get colors {
    final theme = Theme.of(this);
    final ext = theme.extension<BudgetColors>();
    if (ext != null) return ext;
    return theme.brightness == Brightness.dark ? BudgetColors.dark : BudgetColors.light;
  }
}
