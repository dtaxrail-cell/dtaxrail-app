import 'package:flutter/material.dart';

class AppColors {
  // DTR Brand — Blue primary, Green accent
  static const primary = Color(0xFF1A56DB);       // DTR Blue
  static const primaryDark = Color(0xFF1040B0);
  static const primaryLight = Color(0xFFE8EFFF);
  static const accent = Color(0xFF2DAB6F);         // DTR Green
  static const accentLight = Color(0xFFE6F7EF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F7FF);
  static const cardBg = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF0D1B3E);
  static const textMid = Color(0xFF4A5568);
  static const textLight = Color(0xFF8896AB);
  static const divider = Color(0xFFE2E8F0);
  static const error = Color(0xFFE53E3E);

  // Status colors
  static const statusPending = Color(0xFFF6AD55);
  static const statusReview = Color(0xFF63B3ED);
  static const statusFiled = Color(0xFFFC8181);
  static const statusDone = Color(0xFF2DAB6F);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      hintStyle: const TextStyle(
        color: AppColors.textLight,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
    ),
  );
}