import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game_session.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../theme/lamma_theme.dart';
import 'game_button.dart';
import 'game_rules_sheet.dart';

class TeamScoreDisplay {
  final String name;
  final int score;
  final Color color;
  final Color borderColor;
  final Color bgColor;

  const TeamScoreDisplay({
    required this.name,
    required this.score,
    required this.color,
    required this.borderColor,
    required this.bgColor,
  });
}

class PauseDialog extends StatefulWidget {
  final GameSession? session;
  final int currentRound;
  final int totalRounds;
  final String gameTitle;
  final String? gameSlug;
  final int violetScore;
  final int orangeScore;
  final Map<String, int>? teamScores;
  final VoidCallback onResume;
  final VoidCallback? onRestartRound;
  final VoidCallback? onShowRules;

  const PauseDialog({
    super.key,
    this.session,
    required this.currentRound,
    required this.totalRounds,
    this.gameTitle = 'اللعبة',
    this.gameSlug,
    this.violetScore = 14,
    this.orangeScore = 11,
    this.teamScores,
    required this.onResume,
    this.onRestartRound,
    this.onShowRules,
  });

  static Future<void> show(
    BuildContext context, {
    GameSession? session,
    required int currentRound,
    required int totalRounds,
    String gameTitle = 'اللعبة',
    String? gameSlug,
    int violetScore = 14,
    int orangeScore = 11,
    Map<String, int>? teamScores,
    required VoidCallback onResume,
    VoidCallback? onRestartRound,
    VoidCallback? onShowRules,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF0A0418).withValues(alpha: 0.75),
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: PauseDialog(
          session: session,
          currentRound: currentRound,
          totalRounds: totalRounds,
          gameTitle: gameTitle,
          gameSlug: gameSlug,
          violetScore: violetScore,
          orangeScore: orangeScore,
          teamScores: teamScores,
          onResume: onResume,
          onRestartRound: onRestartRound,
          onShowRules: onShowRules,
        ),
      ),
    );
  }

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SettingsService.instance.soundEffects;
  }

  List<TeamScoreDisplay> _buildScoreList() {
    final List<TeamScoreDisplay> list = [];

    // 1. إذا توفرت الجلسة GameSession
    if (widget.session != null) {
      final teams = widget.session!.rankedTeams;
      if (teams.isNotEmpty) {
        for (int i = 0; i < teams.length; i++) {
          final entry = teams[i];
          final colorTuple = _getColorForIndex(i, entry.key);
          list.add(
            TeamScoreDisplay(
              name: entry.key,
              score: entry.value,
              color: colorTuple.$1,
              borderColor: colorTuple.$2,
              bgColor: colorTuple.$3,
            ),
          );
        }
        return list;
      }

      // إذا كانت لعبة فردية بدون فرق
      final players = widget.session!.rankedPlayers;
      if (players.isNotEmpty) {
        for (int i = 0; i < players.length; i++) {
          final p = players[i];
          final colorTuple = _getColorForIndex(i, p.name);
          list.add(
            TeamScoreDisplay(
              name: p.name,
              score: p.score,
              color: colorTuple.$1,
              borderColor: colorTuple.$2,
              bgColor: colorTuple.$3,
            ),
          );
        }
        return list;
      }
    }

    // 2. إذا توفرت خريطة النقاط teamScores
    if (widget.teamScores != null && widget.teamScores!.isNotEmpty) {
      final entries = widget.teamScores!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final colorTuple = _getColorForIndex(i, entry.key);
        list.add(
          TeamScoreDisplay(
            name: entry.key,
            score: entry.value,
            color: colorTuple.$1,
            borderColor: colorTuple.$2,
            bgColor: colorTuple.$3,
          ),
        );
      }
      return list;
    }

    // 3. القيم الافتراضية
    list.add(
      TeamScoreDisplay(
        name: 'فرفوش',
        score: widget.violetScore,
        color: const Color(0xFFEADFFF),
        borderColor: const Color(0xFFB98AFF).withValues(alpha: 0.6),
        bgColor: const Color(0xFFA35BFF).withValues(alpha: 0.2),
      ),
    );
    list.add(
      TeamScoreDisplay(
        name: 'قفوش',
        score: widget.orangeScore,
        color: const Color(0xFFFFE3D2),
        borderColor: const Color(0xFFFF9E6A).withValues(alpha: 0.6),
        bgColor: const Color(0xFFFF8A4C).withValues(alpha: 0.18),
      ),
    );

    return list;
  }

  (Color, Color, Color) _getColorForIndex(int index, String name) {
    if (name.contains('برتقان') || index == 1) {
      return (
        const Color(0xFFFFE3D2),
        const Color(0xFFFF9E6A).withValues(alpha: 0.6),
        const Color(0xFFFF8A4C).withValues(alpha: 0.18),
      );
    } else if (name.contains('بنفسج') || index == 0) {
      return (
        const Color(0xFFEADFFF),
        const Color(0xFFB98AFF).withValues(alpha: 0.6),
        const Color(0xFFA35BFF).withValues(alpha: 0.2),
      );
    } else if (index == 2) {
      return (
        const Color(0xFFD4F9EA),
        const Color(0xFF34D399).withValues(alpha: 0.6),
        const Color(0xFF059669).withValues(alpha: 0.18),
      );
    } else {
      return (
        const Color(0xFFFFF0D2),
        const Color(0xFFFFC24B).withValues(alpha: 0.6),
        const Color(0xFFD97706).withValues(alpha: 0.18),
      );
    }
  }

  void _openRules() {
    SoundService.instance.playClick();
    if (widget.onShowRules != null) {
      Navigator.pop(context);
      widget.onShowRules!();
    } else {
      // إظهار شاشة الشرح فورياً فوق الاستراحة
      GameRulesSheet.show(
        context,
        gameTitle: widget.session?.gameTitle ?? widget.gameTitle,
        gameSlug: widget.session?.gameSlug ?? widget.gameSlug,
        onResume: () {
          Navigator.pop(context); // إغلاق الدايلوج
          widget.onResume();
        },
      );
    }
  }

  void _confirmExit() {
    SoundService.instance.playClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF241050),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFB98AFF), width: 1.5),
        ),
        title: const Text(
          'إنهاء اللعبة؟',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'هل أنت متأكد من إنهاء اللعبة الحالية والرجوع للرئيسية؟',
          style: TextStyle(color: Color(0xFFCFC6E4), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // إغلاق نافذة التأكيد
              Navigator.pop(context); // إغلاق الاستراحة
              context.go('/home');
            },
            child: const Text('نعم، إنهاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreList = _buildScoreList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 52, 22, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF34197A), Color(0xFF1F0F46)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFB98AFF), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA35BFF).withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'استراحة!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الجولة ${widget.currentRound} من ${widget.totalRounds} · الوقت واقف',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFCFC6E4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // رصيد النقاط للفرق المشاركة ديناميكياً
                if (scoreList.length <= 2)
                  Row(
                    children: scoreList
                        .map(
                          (item) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: item.bgColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: item.borderColor),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: item.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.score}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  )
                else
                  // إذا كانت 3 فرق أو أكثر
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: scoreList.length,
                    itemBuilder: (context, index) {
                      final item = scoreList[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: item.borderColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.score}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 18),

                // زر كمّل اللعب
                GameButton(
                  text: 'كمّل اللعب',
                  icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2A0E35), size: 24),
                  showArrow: false,
                  height: 54,
                  onPressed: () {
                    SoundService.instance.playClick();
                    Navigator.pop(context);
                    widget.onResume();
                  },
                ),
                const SizedBox(height: 10),

                // زر شرح اللعبة (يعمل 100%)
                GestureDetector(
                  onTap: _openRules,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFA35BFF).withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.help_outline_rounded, color: LammaColors.gold500, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'شرح اللعبة',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // أزرار الصوت وإعادة الجولة
                Row(
                  children: [
                    // زر الصوت الفعلي المتصل بـ SettingsService
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final newVal = !_soundEnabled;
                          setState(() => _soundEnabled = newVal);
                          SettingsService.instance.setSoundEffects(newVal);
                          if (newVal) {
                            SoundService.instance.playClick();
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _soundEnabled
                                  ? const Color(0xFFB98AFF).withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                color: _soundEnabled ? LammaColors.gold500 : const Color(0xFFCFC6E4),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _soundEnabled ? 'الصوت شغال' : 'الصوت مكتوم',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر إعادة الجولة
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          SoundService.instance.playClick();
                          Navigator.pop(context);
                          widget.onRestartRound?.call();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'إعادة الجولة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // زر إنهاء اللعبة
                GestureDetector(
                  onTap: _confirmExit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.exit_to_app_rounded, color: Color(0xFFFF8FA0), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'إنهاء اللعبة',
                          style: TextStyle(
                            color: Color(0xFFFF8FA0),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // الأيقونة العائمة في الأعلى (إيقاف مؤقت 3D)
          Positioned(
            top: -36,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                gradient: LammaGradients.ctaPrimary,
                borderRadius: BorderRadius.circular(24),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFB83A72), width: 5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF2569A).withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.pause_rounded, color: Color(0xFF2A0E35), size: 38),
            ),
          ),
        ],
      ),
    );
  }
}
