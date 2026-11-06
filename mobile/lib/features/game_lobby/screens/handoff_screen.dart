import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class HandoffScreen extends StatelessWidget {
  final String playerName;
  final String playerAvatar;
  final String teamName;
  final int round;
  final int totalRounds;
  final String targetRoute;

  const HandoffScreen({
    super.key,
    this.playerName = 'منة',
    this.playerAvatar = 'assets/images/av-mena.png',
    this.teamName = 'فريق البرتقان',
    this.round = 3,
    this.totalRounds = 10,
    this.targetRoute = '/game/amthal',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.24),
            radius: 1.0,
            colors: [
              Color(0xFF8E2A6E),
              Color(0xFF3E1670),
              Color(0xFF150A2E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                // رقم الجولة واسم الفريق
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'الجولة $round من $totalRounds · $teamName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // العنوان: سلّم الموبايل لـ
                const Text(
                  'سلّم الموبايل لـ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFE3D2),
                  ),
                ),

                const SizedBox(height: 24),

                // الأفاتار الكبير مع الحلقات المشعة والتأثيرات
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // حلقة التوهج
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFF2569A).withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // الدائرة المنقطة
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFC24B).withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                    // صورة اللاعب
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF9E6A), width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9E6A).withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: const Color(0xFFF2569A).withValues(alpha: 0.6),
                            blurRadius: 50,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          playerAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // اسم اللاعب بحجم ضخم وظل ثلاثي الأبعاد
                Text(
                  playerName,
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xFFB83A72),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // تحذير: باقي اللاعبين ما يبصوش على الشاشة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        color: LammaColors.gold500,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'باقي اللاعبين ما يبصّوش على الشاشة!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEADFFF),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // زر كشف الكارت
                GameButton(
                  text: 'أنا $playerName، اكشف الكارت',
                  icon: const Icon(Icons.touch_app_rounded, color: Color(0xFF2A0E35), size: 24),
                  showArrow: false,
                  height: 64,
                  onPressed: () {
                    context.push(targetRoute);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
