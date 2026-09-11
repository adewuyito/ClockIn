import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type scale straight from the Stitch design system (Project
/// 2859884629275757623): Plus Jakarta Sans for interface narrative,
/// JetBrains Mono for cryptographic/tabular data (addresses, hashes,
/// balances).
class AppTypography {
  AppTypography._();

  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        height: 38 / 30,
        fontWeight: FontWeight.w700,
      );
  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get headlineSm => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get titleMd => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
      );
  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
      );
  static TextStyle get labelLg => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelMd => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get labelSm => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w500,
      );
}

/// ClockIn AppTheme providing Light Fintech style from Stitch design specs.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLg.copyWith(color: AppColors.onSurface),
        headlineMedium: AppTypography.headlineMd.copyWith(color: AppColors.onSurface),
        headlineSmall: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
        titleMedium: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
        bodyLarge: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
        bodyMedium: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        bodySmall: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        labelLarge: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
        labelMedium: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
        labelSmall: AppTypography.labelSm.copyWith(color: AppColors.outline),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.titleMd,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.titleMd,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          color: AppColors.outline,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
