import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/game_session.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class ResultsScreen extends StatelessWidget {
  final GameSession? session;
  final String winnerTeam;
  final int winnerScore;
  final String runnerUpTeam;
  final int runnerUpScore;
  final String mvpName;
  final String mvpAvatar;
  final String mvpStats;

  const ResultsScreen({
    super.key,
    this.session,
    this.winnerTeam = 'فرفوش',
    this.winnerScore = 24,
    this.runnerUpTeam = 'قفوش',
    this.runnerUpScore = 19,
    this.mvpName = 'سارة',
    this.mvpAvatar = 'assets/images/av-sara.webp',
    this.mvpStats = 'سارة — 7 إجابات صح',
  });

  factory ResultsScreen.fromSession(GameSession session) {
    final ranked = session.rankedTeams;
    final winner = ranked.isNotEmpty ? ranked.first : const MapEntry('فريق الفائز', 0);
    final runnerUp = ranked.length > 1
        ? ranked[1]
        : (ranked.isNotEmpty ? ranked.first : const MapEntry('فريق المنافس', 0));
    final mvp = session.mvp;

    return ResultsScreen(
      session: session,
      winnerTeam: winner.key,
      winnerScore: winner.value,
      runnerUpTeam: runnerUp.key,
      runnerUpScore: runnerUp.value,
      mvpName: mvp?.name ?? 'البطل',
      mvpAvatar: mvp?.avatar ?? 'assets/images/av-ahmed.webp',
      mvpStats: '${mvp?.name ?? "البطل"} — ${mvp?.correctAnswers ?? 0} إجابات صح',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.56),
            radius: 1.0,
            colors: [
              Color(0xFF6A33C4),
              Color(0xFF2E1660),
              Color(0xFF150A2E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              children: [
                // كأس الفوز مع التوهج والاحتفال
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              LammaColors.gold500.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1458).withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: LammaColors.gold500, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: LammaColors.gold500.withValues(alpha: 0.5),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 78,
                          color: LammaColors.gold500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'الجولة خلصت!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LammaColors.gold300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$winnerTeam كسب 🎉',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xFF6A24C9),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // كارت الفريق الفائز
                Container(
                  height: 66,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8F4BF0), Color(0xFF5B1FB8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFC9A2FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA35BFF).withValues(alpha: 0.45),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: LammaColors.gold500, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          winnerTeam,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      Text(
                        '$winnerScore',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: LammaColors.gold500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // كارت الفريق الثاني
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A4C).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFF9E6A).withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('2', style: TextStyle(color: Color(0xFFFFE3D2), fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          runnerUpTeam,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      Text(
                        '$runnerUpScore',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFFE3D2)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // كارت نجمة الجولة (MVP)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: LammaColors.gold500, width: 3),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            mvpAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'نجمة الجولة 🌟',
                              style: TextStyle(fontSize: 13, color: LammaColors.gold300, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mvpStats,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: LammaColors.gold500,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '+5',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2A0E35)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // زر العب تاني (CTA رئيسي)
                GameButton(
                  text: 'العب تاني',
                  showArrow: false,
                  height: 62,
                  onPressed: () {
                    if (session != null) {
                      for (final p in session!.players) {
                        p.score = 0;
                        p.correctAnswers = 0;
                      }
                      session!.currentRoundIndex = 0;
                      context.go(session!.gameRoute, extra: session);
                    } else {
                      context.go('/home');
                    }
                  },
                ),

                const SizedBox(height: 12),

                // صف الأزرار الثانوية (غير اللعبة / شارك النتيجة)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'غيّر اللعبة',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ النتيجة لمشاركتها مع أصحابك!')),
                          );
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'شارك النتيجة',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

