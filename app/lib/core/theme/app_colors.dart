import 'package:flutter/material.dart';

/// Design tokens derived from Google Stitch UI specs (Project 2859884629275757623).
class AppColors {
  AppColors._();

  // Primary brand palette (Teal / Blue)
  static const Color primary = Color(0xFF00556D);
  static const Color primaryContainer = Color(0xFF0F6F8C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFC3EBFF);
  static const Color primaryFixedDim = Color(0xFF85D1F1);

  // Secondary palette
  static const Color secondary = Color(0xFF1F667F);
  static const Color secondaryContainer = Color(0xFFA1E0FD);
  static const Color onSecondaryContainer = Color(0xFF1E647E);

  // Semantic feedback colors
  static const Color success = Color(0xFF1F9D5B);
  static const Color tertiary = Color(0xFF005B30);
  static const Color tertiaryContainer = Color(0xFF007640);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFC97A0A);
  static const Color warningContainer = Color(0xFFFFE0B2);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // Surface & backgrounds (Light Fintech theme)
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Color(0xFFF8F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFEDEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE7E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E4);

  // Typography & outlines
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3F484D);
  static const Color outline = Color(0xFF6F787D);
  static const Color outlineVariant = Color(0xFFBFC8CD);
}
