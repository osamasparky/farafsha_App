import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/game_session.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/player_avatar_widget.dart';

class ResultsScreen extends StatefulWidget {
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
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    _syncScoreToLeaderboard();
  }

  Future<void> _syncScoreToLeaderboard() async {
    final session = widget.session;
    if (session == null || AuthService.instance.isGuest || !AuthService.instance.isLoggedIn) {
      return;
    }

    final userName = (ApiService.instance.currentUser?['name']?.toString().trim() ??
            AuthService.instance.userName.trim())
        .toLowerCase();

    GamePlayer? userPlayer;
    if (userName.isNotEmpty) {
      for (final p in session.players) {
        if (p.name.trim().toLowerCase() == userName) {
          userPlayer = p;
          break;
        }
      }
    }
    userPlayer ??= session.players.isNotEmpty ? session.players.first : null;
    if (userPlayer == null) return;

    final isWin = userPlayer.teamName == widget.winnerTeam && userPlayer.score > 0;
    await ApiService.instance.recordGameScore(
      score: userPlayer.score,
      isWin: isWin,
    );
  }

  GameSession? get session => widget.session;
  String get winnerTeam => widget.winnerTeam;
  int get winnerScore => widget.winnerScore;
  String get runnerUpTeam => widget.runnerUpTeam;
  int get runnerUpScore => widget.runnerUpScore;
  String get mvpName => widget.mvpName;
  String get mvpAvatar => widget.mvpAvatar;
  String get mvpStats => widget.mvpStats;

  final GlobalKey _victoryCardKey = GlobalKey();
  bool _isSharing = false;

  /// التقاط بطاقة النتيجة كصورة جاهزة للمشاركة على الستوري والواتساب
  Future<void> _shareVictoryCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final boundary = _victoryCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/farafsha_result_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(pngBytes);

          final shareText =
              '🎉 $winnerTeam كسب $winnerScore - $runnerUpScore في لعبة فرفشة! حمّل التطبيق والعب مع صحابك: https://farafsha.com';
          await Share.shareXFiles([XFile(file.path)], text: shareText);
          return;
        }
      }
      await Share.share(
        '🎉 $winnerTeam كسب $winnerScore - $runnerUpScore في لعبة فرفشة! حمّل التطبيق والعب مع صحابك: https://farafsha.com',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر مشاركة صورة النتيجة، حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
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
                // بطاقة النتيجة القابلة للمشاركة (Story / WhatsApp)
                RepaintBoundary(
                  key: _victoryCardKey,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(0.0, -0.5),
                        radius: 1.1,
                        colors: [
                          Color(0xFF5D2BB0),
                          Color(0xFF281254),
                          Color(0xFF150A2E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.35), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // كأس الفوز مع التوهج والاحتفال
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
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
                                width: 102,
                                height: 102,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A1458).withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: LammaColors.gold500, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: LammaColors.gold500.withValues(alpha: 0.5),
                                      blurRadius: 28,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 64,
                                  color: LammaColors.gold500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'الجولة خلصت!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: LammaColors.gold300,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$winnerTeam كسب 🎉',
                          style: const TextStyle(
                            fontSize: 30,
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
                        const SizedBox(height: 18),

                        // كارت الفريق الفائز
                        Container(
                          height: 62,
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
                        const SizedBox(height: 10),

                        // كارت الفريق الثاني
                        Container(
                          height: 56,
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
                        const SizedBox(height: 14),

                        // كارت نجمة الجولة (MVP)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: LammaColors.gold500, width: 2.5),
                                ),
                                child: PlayerAvatarWidget(
                                  avatarPath: mvpAvatar,
                                  size: 46,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'نجمة الجولة 🌟',
                                      style: TextStyle(fontSize: 12, color: LammaColors.gold300, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      mvpStats,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
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
                        const SizedBox(height: 10),
                        Text(
                          'تطبيق فرفشة • farafsha.com',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
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
                        onTap: _isSharing ? null : _shareVictoryCard,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSharing)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              else
                                const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              const Text(
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

