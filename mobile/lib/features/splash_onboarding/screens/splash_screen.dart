import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/tactile_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 10),

              // شعار لمّة مع التاج
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandViolet.withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 64,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لمّة',
                    style: AppTypography.heading1.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'لعبة الجماعة',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'مجموعة ألعاب جماعية\nللمتعة والتحدي مع الأصدقاء والعائلة',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 15,
                      color: AppColors.textDarkSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              // بطاقة الميزات والخصائص السريعة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardDarkBorder, width: 1.2),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.phone_android_rounded, 'دعم اللعب المحلي (هاتف واحد للمجموعة)'),
                    const Divider(color: AppColors.cardDarkBorder, height: 16),
                    _buildFeatureRow(Icons.wifi_rounded, 'العب أونلاين مع أصدقائك عن بُعد'),
                    const Divider(color: AppColors.cardDarkBorder, height: 16),
                    _buildFeatureRow(Icons.cloud_sync_rounded, 'محتوى متجدد باستمرار وبلا إنترنت'),
                  ],
                ),
              ),

              // أزرار البداية والدخول
              Column(
                children: [
                  TactileButton(
                    text: 'ابدأ الآن',
                    icon: Icons.play_arrow_rounded,
                    backgroundColor: AppColors.brandViolet,
                    shadowColor: AppColors.brandVioletDark,
                    onPressed: () {
                      context.push('/onboarding');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      context.push('/login');
                    },
                    child: Text(
                      'لدي حساب؟ تسجيل الدخول',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandViolet.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

