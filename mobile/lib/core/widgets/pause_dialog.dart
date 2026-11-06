import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/lamma_theme.dart';
import 'game_button.dart';

class PauseDialog extends StatefulWidget {
  final int currentRound;
  final int totalRounds;
  final int violetScore;
  final int orangeScore;
  final VoidCallback onResume;
  final VoidCallback? onRestartRound;
  final VoidCallback? onShowRules;

  const PauseDialog({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    this.violetScore = 14,
    this.orangeScore = 11,
    required this.onResume,
    this.onRestartRound,
    this.onShowRules,
  });

  static Future<void> show(
    BuildContext context, {
    required int currentRound,
    required int totalRounds,
    int violetScore = 14,
    int orangeScore = 11,
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
          currentRound: currentRound,
          totalRounds: totalRounds,
          violetScore: violetScore,
          orangeScore: orangeScore,
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
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 22),
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
                const SizedBox(height: 18),

                // رصيد النقاط للفريقين
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA35BFF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFB98AFF).withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'البنفسج',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEADFFF)),
                            ),
                            Text(
                              '${widget.violetScore}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A4C).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFF9E6A).withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'البرتقان',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFE3D2)),
                            ),
                            Text(
                              '${widget.orangeScore}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // زر كمل اللعب
                GameButton(
                  text: 'كمّل اللعب',
                  icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2A0E35), size: 24),
                  showArrow: false,
                  height: 56,
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onResume();
                  },
                ),
                const SizedBox(height: 10),

                // زر شرح اللعبة
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onShowRules?.call();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.55), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _soundEnabled = !_soundEnabled);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
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
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
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
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
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
