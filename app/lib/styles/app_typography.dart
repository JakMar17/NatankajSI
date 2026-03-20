import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:app/styles/app_colors.dart';

/// Shared text styles and font family mapping.
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return GoogleFonts.spaceGroteskTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: AppColors.textBodyHigh,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textBodyMedium,
        ),
      ),
    );
  }
}
