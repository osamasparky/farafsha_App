import 'package:flutter/material.dart';

/// نظام الألوان لتطبيق لمّة (Lammah)
/// متوافق 100% مع الهوية المعتمدة في وثيقة المنتج ونظام التصميم
class AppColors {
  AppColors._();

  // --- ألوان الهوية الرئيسية (Brand) ---
  /// البنفسجي العميق للخلفيات والأسطح الفاخرة
  static const Color brandDeepPurple = Color(0xFF21143F);
  
  /// البنفسجي الساطع للإجراءات الأساسية والأزرار
  static const Color brandViolet = Color(0xFF8138E8);
  static const Color brandVioletLight = Color(0xFF9D61F2);
  static const Color brandVioletDark = Color(0xFF5E1FB5);

  // --- ألوان التمييز والحيوية (Accents) ---
  /// برتقالي مشرق للمؤقت والنقاط والإبراز المرح
  static const Color accentOrange = Color(0xFFFF9850);
  static const Color accentOrangeDark = Color(0xFFE5792F);

  /// وردي شبابي للوسوم والتصنيفات والرسوم التفاعلية
  static const Color accentPink = Color(0xFFF15D9C);

  // --- حالات النظام (Status) ---
  static const Color success = Color(0xFF2E9D7B);
  static const Color warning = Color(0xFFD98720);
  static const Color error = Color(0xFFC8465B);

  // --- أسطح الوضع الليلي (Dark Mode / Night Lounge) ---
  static const Color bgDark = Color(0xFF160B2E);
  static const Color surfaceDark = Color(0xFF21143F);
  static const Color cardDark = Color(0xFF2E1C55);
  static const Color cardDarkBorder = Color(0xFF432C76);
  static const Color textDarkPrimary = Color(0xFFFFFFFF);
  static const Color textDarkSecondary = Color(0xFFB8AFC7);
  static const Color textDarkMuted = Color(0xFF7A6F8C);

  // --- أسطح الوضع النهاري (Light Mode) ---
  static const Color bgLight = Color(0xFFF7F5FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardLightBorder = Color(0xFFE2DDE8);
  static const Color textLightPrimary = Color(0xFF241B35);
  static const Color textLightSecondary = Color(0xFF6F6580);
  static const Color textLightMuted = Color(0xFF9C93AA);

  // --- تدرجات لونية مميزة (Lammah Gradients) ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8138E8), Color(0xFFA055F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF9850), Color(0xFFFF7A29)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFF321A63), Color(0xFF21143F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient crownGoldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

