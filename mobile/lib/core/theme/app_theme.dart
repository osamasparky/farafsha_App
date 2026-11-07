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
}
