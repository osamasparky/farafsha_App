import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';
import '../services/settings_service.dart';

class GuestLockedModal extends StatelessWidget {
  final String gameTitle;
  final String? customTitle;
  final String? customMessage;

  const GuestLockedModal({
    super.key,
    required this.gameTitle,
    this.customTitle,
    this.customMessage,
  });

  static Future<void> show(
    BuildContext context, {
    String gameTitle = 'اللعبة',
    String? customTitle,
    String? customMessage,
  }) {
    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuestLockedModal(
        gameTitle: gameTitle,
        customTitle: customTitle,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF190C36),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Color(0xFF8F4BF0), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 86,
            height: 86,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD27A), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8F4BF0).withOpacity(0.55),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Image.asset('assets/images/farfasha_logo.webp', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            customTitle ?? 'سجل دخول عشان تفرفش! 🎉',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customMessage ??
                'لعبة "$gameTitle" وباقي الألعاب المميزة متاحة للأعضاء المسجلين فقط.\nسجّل دخولك الآن وافتح جميع الألعاب والتحديات واحفظ نقاطك وإنجازاتك!',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD9CCF2),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              context.push('/login');
            },
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A4C), Color(0xFFE94560)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94560).withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'تسجيل الدخول / إنشاء حساب 🚀',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'الاستمرار كزائر للعبة الأمثال المتاحة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFA99BC8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
