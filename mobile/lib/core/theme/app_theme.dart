import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.brandViolet,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandViolet,
        secondary: AppColors.accentOrange,
        tertiary: AppColors.accentPink,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textDarkPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.heading3,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardDarkBorder, width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.brandDeepPurple,
        selectedItemColor: AppColors.brandViolet,
        unselectedItemColor: AppColors.textDarkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      primaryColor: AppColors.brandViolet,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandViolet,
        secondary: AppColors.accentOrange,
        tertiary: AppColors.accentPink,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textLightPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.heading3.copyWith(color: AppColors.textLightPrimary),
        iconTheme: const IconThemeData(color: AppColors.textLightPrimary),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardLight,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardLightBorder, width: 1.0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brandViolet,
        unselectedItemColor: AppColors.textLightMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }
}
