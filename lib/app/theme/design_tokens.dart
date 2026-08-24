import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================
/// Budget Buddy Design Tokens
/// Premium Emerald Fintech — Material 3 token system
/// ============================================================

// --------------- Color Tokens ---------------

class AppColors {
  AppColors._();

  // ── Light Mode ──
  static const Color primaryLight = Color(0xFF006C49);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFF10B981);
  static const Color onPrimaryContainerLight = Color(0xFF002114);

  static const Color secondaryLight = Color(0xFF2B6954);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFB0F1D5);
  static const Color onSecondaryContainerLight = Color(0xFF002116);

  static const Color tertiaryLight = Color(0xFF3B6374);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color tertiaryContainerLight = Color(0xFFBFE9FC);
  static const Color onTertiaryContainerLight = Color(0xFF001F2A);

  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color errorContainerLight = Color(0xFFFFDAD6);
  static const Color onErrorContainerLight = Color(0xFF410002);

  static const Color surfaceLight = Color(0xFFF4FBF4);
  static const Color onSurfaceLight = Color(0xFF161D19);
  static const Color surfaceVariantLight = Color(0xFFDAE5DD);
  static const Color onSurfaceVariantLight = Color(0xFF3F4943);
  static const Color outlineLight = Color(0xFF6F7972);
  static const Color outlineVariantLight = Color(0xFFBEC9C1);

  static const Color backgroundLight = Color(0xFFF4FBF4);
  static const Color onBackgroundLight = Color(0xFF161D19);

  static const Color inverseSurfaceLight = Color(0xFF2B322D);
  static const Color onInverseSurfaceLight = Color(0xFFECF2EC);
  static const Color inversePrimaryLight = Color(0xFF4EDEA3);

  static const Color shadowLight = Color(0xFF000000);
  static const Color scrimLight = Color(0xFF000000);
  static const Color surfaceTintLight = Color(0xFF006C49);

  // ── Dark Mode (fixed-dim equivalents) ──
  static const Color primaryDark = Color(0xFF4EDEA3);
  static const Color onPrimaryDark = Color(0xFF003825);
  static const Color primaryContainerDark = Color(0xFF005137);
  static const Color onPrimaryContainerDark = Color(0xFF6FFBBE);

  static const Color secondaryDark = Color(0xFF6FFBBE);
  static const Color onSecondaryDark = Color(0xFF003829);
  static const Color secondaryContainerDark = Color(0xFF0D503D);
  static const Color onSecondaryContainerDark = Color(0xFFB0F1D5);

  static const Color tertiaryDark = Color(0xFFA3CDE0);
  static const Color onTertiaryDark = Color(0xFF043543);
  static const Color tertiaryContainerDark = Color(0xFF224B5B);
  static const Color onTertiaryContainerDark = Color(0xFFBFE9FC);

  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);

  static const Color surfaceDark = Color(0xFF161D19);
  static const Color onSurfaceDark = Color(0xFFDDE4DE);
  static const Color surfaceVariantDark = Color(0xFF3F4943);
  static const Color onSurfaceVariantDark = Color(0xFFBEC9C1);
  static const Color outlineDark = Color(0xFF89938C);
  static const Color outlineVariantDark = Color(0xFF3F4943);

  static const Color backgroundDark = Color(0xFF161D19);
  static const Color onBackgroundDark = Color(0xFFDDE4DE);

  static const Color inverseSurfaceDark = Color(0xFFDDE4DE);
  static const Color onInverseSurfaceDark = Color(0xFF2B322D);
  static const Color inversePrimaryDark = Color(0xFF006C49);

  static const Color shadowDark = Color(0xFF000000);
  static const Color scrimDark = Color(0xFF000000);
  static const Color surfaceTintDark = Color(0xFF4EDEA3);

  // ── Glassmorphism Surfaces ──
  static const Color glassLight = Color(0x66FFFFFF); // rgba(255,255,255,0.4)
  static const Color glassDark = Color(0x661E2320); // rgba(30,35,32,0.4)
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x33FFFFFF);

  // ── Accent / Gradient ──
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006C49), Color(0xFF10B981)],
  );
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4EDEA3), Color(0xFF6FFBBE)],
  );
}

// --------------- Typography Tokens ---------------

class AppTypography {
  AppTypography._();

  /// Base Manrope text theme — use this to build all styles.
  static TextTheme get textTheme {
    return GoogleFonts.manropeTextTheme().copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      ),
    );
  }
}

// --------------- Spacing Tokens ---------------

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

// --------------- Radius Tokens ---------------

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double hero = 48.0;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius heroAll = BorderRadius.all(Radius.circular(hero));
}

// --------------- Glassmorphism Tokens ---------------

class AppGlass {
  AppGlass._();

  static const double blurIntensity = 24.0;
  static const double borderWidth = 1.5;
}

// --------------- Animation Tokens ---------------

class AppAnimation {
  AppAnimation._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 2500);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;

  /// Scale factor for button press animation
  static const double buttonPressScale = 0.96;
}
