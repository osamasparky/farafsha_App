import 'package:flutter/material.dart';

class LammaColors {
  LammaColors._();

  static const bgDeepest = Color(0xFF150A2E);
  static const bgDeep = Color(0xFF170B30);
  static const bgBase = Color(0xFF241050);
  static const bgRaised = Color(0xFF2A1458);
  static const glow = Color(0xFF4E2590);

  static const card = Color(0xFF2A1850);
  static const cardBorder = Color(0x59A35BFF); // rgba(163,91,255,0.35)

  static const violet300 = Color(0xFFC9A2FF);
  static const violet400 = Color(0xFFB98AFF);
  static const violet500 = Color(0xFFA35BFF);
  static const violet700 = Color(0xFF7A2FE0);
  static const violet900 = Color(0xFF4A1690);

  static const orange300 = Color(0xFFFFB25E);
  static const orange500 = Color(0xFFFF8A4C);
  static const pink500 = Color(0xFFF2569A);
  static const pink700 = Color(0xFFB83A72);

  static const gold300 = Color(0xFFFFD27A);
  static const gold500 = Color(0xFFFFC24B);

  static const success = Color(0xFF35B88E);
  static const successLight = Color(0xFF6FD9B5);
  static const warning = Color(0xFFD98720);
  static const error = Color(0xFFC8465B);
  static const errorLight = Color(0xFFFF8FA0);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFEADFFF);
  static const textMuted = Color(0xFFCFC6E4);
  static const textFaint = Color(0xFFA99BC8);
  static const onCta = Color(0xFF2A0E35);

  static const parchmentTop = Color(0xFFF6E3B8);
  static const parchmentBottom = Color(0xFFE8C98A);
  static const parchmentText = Color(0xFF3E2410);
}

class LammaGradients {
  LammaGradients._();

  static const screen = RadialGradient(
    center: Alignment(0, -0.5),
    radius: 1.1,
    colors: [LammaColors.glow, LammaColors.bgRaised, LammaColors.bgDeep],
    stops: [0, 0.5, 1],
  );

  static const ctaPrimary = LinearGradient(
    begin: Alignment.centerRight, // RTL start
    end: Alignment.centerLeft,
    colors: [LammaColors.orange300, LammaColors.orange500, LammaColors.pink500],
    stops: [0, 0.45, 1],
  );

  static const ctaSecondary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [LammaColors.violet400, LammaColors.violet700],
  );

  static LinearGradient tile(Color a, Color b) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      );
}

class LammaRadius {
  LammaRadius._();

  static const input = 16.0;
  static const card = 20.0;
  static const tile = 22.0;
  static const sheet = 32.0;
}

class LammaTheme {
  LammaTheme._();

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true, fontFamily: 'Cairo');
    return base.copyWith(
      scaffoldBackgroundColor: LammaColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: LammaColors.violet500,
        secondary: LammaColors.orange500,
        tertiary: LammaColors.gold500,
        error: LammaColors.error,
        surface: LammaColors.card,
        onPrimary: Colors.white,
        onSecondary: LammaColors.onCta,
        onSurface: Colors.white,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
        headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LammaColors.textSecondary),
        bodySmall: const TextStyle(fontSize: 13, color: LammaColors.textMuted),
        labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: LammaColors.textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        hintStyle: const TextStyle(color: LammaColors.textFaint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LammaRadius.input),
          borderSide: const BorderSide(color: LammaColors.cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LammaRadius.input),
          borderSide: const BorderSide(color: LammaColors.violet400, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : LammaColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? LammaColors.violet500 : Colors.white24),
      ),
    );
  }
}
