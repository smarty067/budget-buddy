import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Light theme for Budget Buddy — Premium Emerald Fintech
ThemeData buildLightTheme() {
  final colorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.onPrimaryLight,
    primaryContainer: AppColors.primaryContainerLight,
    onPrimaryContainer: AppColors.onPrimaryContainerLight,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.onSecondaryLight,
    secondaryContainer: AppColors.secondaryContainerLight,
    onSecondaryContainer: AppColors.onSecondaryContainerLight,
    tertiary: AppColors.tertiaryLight,
    onTertiary: AppColors.onTertiaryLight,
    tertiaryContainer: AppColors.tertiaryContainerLight,
    onTertiaryContainer: AppColors.onTertiaryContainerLight,
    error: AppColors.errorLight,
    onError: AppColors.onErrorLight,
    errorContainer: AppColors.errorContainerLight,
    onErrorContainer: AppColors.onErrorContainerLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurfaceLight,
    surfaceContainerHighest: AppColors.surfaceVariantLight,
    onSurfaceVariant: AppColors.onSurfaceVariantLight,
    outline: AppColors.outlineLight,
    outlineVariant: AppColors.outlineVariantLight,
    inverseSurface: AppColors.inverseSurfaceLight,
    onInverseSurface: AppColors.onInverseSurfaceLight,
    inversePrimary: AppColors.inversePrimaryLight,
    shadow: AppColors.shadowLight,
    scrim: AppColors.scrimLight,
    surfaceTint: AppColors.surfaceTintLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.onSurfaceLight,
      displayColor: AppColors.onSurfaceLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.onSurfaceLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.onSurfaceLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onPrimaryLight,
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
        foregroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
        ),
        side: const BorderSide(color: AppColors.primaryLight),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantLight.withAlpha(77),
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
          color: AppColors.outlineVariantLight,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide(
          color: AppColors.primaryLight,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide(
          color: AppColors.errorLight,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.xlAll,
        borderSide: BorderSide(
          color: AppColors.errorLight,
          width: 2.0,
        ),
      ),
      labelStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariantLight,
      ),
      hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceVariantLight.withAlpha(153),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.onSurfaceVariantLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryContainerLight,
      foregroundColor: AppColors.onPrimaryContainerLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inverseSurfaceLight,
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.onInverseSurfaceLight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.outlineVariantLight,
      thickness: 1,
    ),
  );
}
