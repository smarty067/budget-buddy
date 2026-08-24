import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Dark theme for Budget Buddy — Premium Emerald Fintech (fixed-dim tokens)
ThemeData buildDarkTheme() {
  final colorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryContainerDark,
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: AppColors.tertiaryContainerDark,
    onTertiaryContainer: AppColors.onTertiaryContainerDark,
    error: AppColors.errorDark,
    onError: AppColors.onErrorDark,
    errorContainer: AppColors.errorContainerDark,
    onErrorContainer: AppColors.onErrorContainerDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceContainerHighest: AppColors.surfaceVariantDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    inverseSurface: AppColors.inverseSurfaceDark,
    onInverseSurface: AppColors.onInverseSurfaceDark,
    inversePrimary: AppColors.inversePrimaryDark,
    shadow: AppColors.shadowDark,
    scrim: AppColors.scrimDark,
    surfaceTint: AppColors.surfaceTintDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.onSurfaceDark,
      displayColor: AppColors.onSurfaceDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.onSurfaceDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.onSurfaceDark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceVariantDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.onPrimaryDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
        ),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
        ),
        side: const BorderSide(color: AppColors.primaryDark),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantDark.withAlpha(77),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide(
          color: AppColors.outlineVariantDark,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide(
          color: AppColors.primaryDark,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide(
          color: AppColors.errorDark,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide(
          color: AppColors.errorDark,
          width: 2.0,
        ),
      ),
      labelStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariantDark,
      ),
      hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariantDark.withAlpha(153),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.onSurfaceVariantDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryContainerDark,
      foregroundColor: AppColors.onPrimaryContainerDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inverseSurfaceDark,
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.onInverseSurfaceDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.outlineVariantDark,
      thickness: 1,
    ),
  );
}
