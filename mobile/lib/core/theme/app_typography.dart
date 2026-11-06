import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// نظام الخطوط والطباعة لتطبيق لمّة
/// معتمد على خط Cairo للأصالة والوضوح العالي في العربية، مع وزن متناسق
class AppTypography {
  AppTypography._();

  static TextStyle get heading1 => GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textDarkPrimary,
        height: 1.25,
      );

  static TextStyle get heading2 => GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textDarkPrimary,
        height: 1.3,
      );

  static TextStyle get heading3 => GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDarkPrimary,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDarkPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textDarkSecondary,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textDarkMuted,
        height: 1.3,
      );

  static TextStyle get button => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      );

  static TextStyle get badge => GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get timer => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.accentOrange,
        letterSpacing: 1.2,
      );
}

