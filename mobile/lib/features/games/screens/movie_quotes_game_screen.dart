import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/game_session.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';

class MovieQuotesGameScreen extends StatefulWidget {
  final GameSession? session;
  const MovieQuotesGameScreen({super.key, this.session});

  @override
  State<MovieQuotesGameScreen> createState() => _MovieQuotesGameScreenState();
}

class _MovieQuotesGameScreenState extends State<MovieQuotesGameScreen> {
  late GameSession _session;
  int _secondsLeft = 15;
  Timer? _timer;
  int? _selectedChoiceIndex;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? _createDefaultSession();
    _startTimer();
  }

  GameSession _createDefaultSession() {
    return GameSession(
      gameSlug: 'famous-quotes',
      gameTitle: 'جمل مشهورة',
      gameRoute: '/game/quotes',
      totalRounds: 10,
      players: [
        GamePlayer(
          id: '1',
          name: 'أحمد',
          teamName: 'فريق البنفسج',
          avatar: 'assets/images/av-ahmed.png',
          teamColor: const Color(0xFFA35BFF),
        ),
        GamePlayer(
          id: '2',
          name: 'سارة',
          teamName: 'فريق البرتقان',
          avatar: 'assets/images/av-sara.png',
          teamColor: const Color(0xFFFF8A4C),
        ),
        GamePlayer(
          id: '3',
          name: 'محمود',
          teamName: 'فريق البنفسج',
          avatar: 'assets/images/av-mahmoud.png',
          teamColor: const Color(0xFFA35BFF),
        ),
        GamePlayer(
          id: '4',
          name: 'منة',
          teamName: 'فريق البرتقان',
          avatar: 'assets/images/av-mena.png',
          teamColor: const Color(0xFFFF8A4C),
        ),
      ],
      questions: [
        GameQuestion(
          prompt: '«يا بابا .. أنا مش زعلان ...»',
          answer: 'أنا متضايق بس',
          options: ['أنا متضايق بس', 'أنا مش باطل', 'أنا زعلان قوي'],
          explanation: 'فيلم الكيف - الفنان محمود عبد العزيز (مزاجنجي).',
        ),
        GameQuestion(
          prompt: '«هو كله ضرب ضرب ...»',
          answer: 'مفيش شتيمة؟',
          options: ['مفيش شتيمة؟', 'مفيش راحة؟', 'مفيش كلام؟'],
          explanation: 'فيلم بوحة - الفنان محمد سعد.',
        ),
        GameQuestion(
          prompt: '«أنا مش كريم أنا ...»',
          answer: 'أنا شحاتة يا عمري',
          options: ['أنا شحاتة يا عمري', 'أنا حمادة', 'أنا غلبان'],
          explanation: 'فيلم كركر - الفنان محمد سعد والفنان حسن حسني.',
        ),
        GameQuestion(
          prompt: '«اللي يخاف من العفريت ...»',
          answer: 'يطلع له',
          options: ['يطلع له', 'يستخبى منه', 'يقفل الباب'],
          explanation: 'فيلم الإنس والنمس - الفنان محمد هنيدي.',
        ),
        GameQuestion(
          prompt: '«دي بلد شهادات يا ...»',
          answer: 'محيي',
          options: ['محيي', 'حودة', 'أحمد'],
          explanation: 'فيلم صعيدي في الجامعة الأمريكية - الفنان محمد هنيدي.',
        ),
        GameQuestion(
          prompt: '«الجوازة دي لازم ...»',
          answer: 'تبوظ',
          options: ['تبوظ', 'تتم', 'تتأجل'],
          explanation: 'فيلم غبي منه فيه - الفنان طلعت زكريا وهاني رمزي.',
        ),
        GameQuestion(
          prompt: '«أنا في الميري يا باشا ...»',
          answer: 'مبفكرش',
          options: ['مبفكرش', 'مبتكلمش', 'منفذ وبس'],
          explanation: 'فيلم النوم في العسل - الفنان عادل إمام.',
        ),
      ],
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 5 && _secondsLeft > 0) {
          SoundService.instance.playTick();
          SettingsService.instance.triggerHaptic();
        }
      } else {
        _timer?.cancel();
        setState(() => _isAnswered = true);
        SoundService.instance.playWrong();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    if (_secondsLeft > 0 && !_isAnswered) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onSelectChoice(int index) {
    if (_isAnswered) return;
    _timer?.cancel();

    final question = _session.currentQuestion;
    final isCorrect = question.options[index] == question.answer;

    setState(() {
      _selectedChoiceIndex = index;
      _isAnswered = true;
      _session.recordAnswer(isCorrect: isCorrect, points: 3);
    });

    if (isCorrect) {
      SoundService.instance.playCorrect();
      SettingsService.instance.triggerHaptic();
    } else {
      SoundService.instance.playWrong();
      SettingsService.instance.triggerHaptic(isHeavy: true);
    }
  }

  void _openPauseModal() {
    _pauseTimer();
    SoundService.instance.playClick();

    PauseDialog.show(
      context,
      session: _session,
      currentRound: _session.currentRoundNumber,
      totalRounds: _session.totalRounds,
      gameTitle: _session.gameTitle,
      gameSlug: _session.gameSlug,
      onResume: _resumeTimer,
      onRestartRound: () {
        setState(() {
          _secondsLeft = 15;
          _selectedChoiceIndex = null;
          _isAnswered = false;
        });
        _startTimer();
      },
    );
  }

  void _onNext() async {
    _timer?.cancel();
    SoundService.instance.playClick();
    SettingsService.instance.triggerHaptic();

    if (_session.isLastRound) {
      SoundService.instance.playWin();
      context.push('/results', extra: _session);
    } else {
      _session.advanceToNextRound();

      await context.push('/handoff', extra: _session);

      if (!mounted) return;

      setState(() {
        _secondsLeft = 15;
        _selectedChoiceIndex = null;
        _isAnswered = false;
      });
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _session.activePlayer;
    final question = _session.currentQuestion;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.44),
            radius: 1.0,
            colors: [
              Color(0xFF812BBF),
              Color(0xFF33165B),
              Color(0xFF150A2E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                // الشريط العلوي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _openPauseModal,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'الجولة ${_session.currentRoundNumber} من ${_session.totalRounds}',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _secondsLeft <= 5
                              ? [const Color(0xFFE94560), const Color(0xFFFF5252)]
                              : [const Color(0xFF8138E8), const Color(0xFFA35BFF)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: (_secondsLeft <= 5 ? const Color(0xFFE94560) : const Color(0xFFA35BFF))
                                .withValues(alpha: 0.5),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: LammaColors.gold500, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '00:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // لافتة دور اللاعب الحالي
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active.teamColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active.teamColor.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: AssetImage(active.avatar),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'دور اللاعب: ${active.name} (${active.teamName})',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.stars_rounded, color: LammaColors.gold500, size: 18),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // قائمة اللاعبين الفعلية
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _session.players.map((p) {
                      final bool isActive = p.id == active.id;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              const Icon(Icons.workspace_premium_rounded, color: LammaColors.gold500, size: 20)
                            else
                              const SizedBox(height: 20),
                            Container(
                              width: isActive ? 56 : 48,
                              height: isActive ? 56 : 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isActive ? LammaColors.gold500 : p.teamColor.withValues(alpha: 0.6),
                                  width: isActive ? 3 : 2,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: LammaColors.gold500.withValues(alpha: 0.55),
                                          blurRadius: 16,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  p.avatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.name,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                                color: isActive ? Colors.white : Colors.white70,
                              ),
                            ),
                            Text(
                              '${p.score} نقطة',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isActive ? LammaColors.gold500 : const Color(0xFFD9C2FF),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // بطاقة الإفيه السينمائي
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0E3B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.movie_creation_rounded, color: LammaColors.gold500, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            question.explanation ?? 'إفيهات من السينما والدراما',
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: LammaColors.gold500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.prompt,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // الخيارات
                Expanded(
                  child: ListView.separated(
                    itemCount: question.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isSelected = _selectedChoiceIndex == index;
                      final isCorrect = option == question.answer;

                      Color? bgColor;
                      Color borderColor = const Color(0xFFA35BFF).withValues(alpha: 0.3);
                      IconData? statusIcon;
                      Color statusIconColor = Colors.white;

                      if (_isAnswered) {
                        if (isCorrect) {
                          bgColor = const Color(0xFF1E824C);
                          borderColor = const Color(0xFF2ECC71);
                          statusIcon = Icons.check_circle_rounded;
                        } else if (isSelected && !isCorrect) {
                          bgColor = const Color(0xFF962D3E);
                          borderColor = const Color(0xFFE74C3C);
                          statusIcon = Icons.cancel_rounded;
                        }
                      } else if (isSelected) {
                        bgColor = const Color(0xFF6A24C9);
                        borderColor = const Color(0xFFC9A2FF);
                      }

                      return GestureDetector(
                        onTap: () => _onSelectChoice(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: bgColor ?? const Color(0xFF241050),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    option,
                                    style: GoogleFonts.cairo(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (statusIcon != null)
                                Icon(statusIcon, color: statusIconColor, size: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // زر التالي
                GestureDetector(
                  onTap: _onNext,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _session.isLastRound
                            ? [const Color(0xFFFFB800), const Color(0xFFFF8A00)]
                            : [const Color(0xFFB98AFF), const Color(0xFF7A2FE0)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border(
                        bottom: BorderSide(
                          color: _session.isLastRound ? const Color(0xFFB25E00) : const Color(0xFF4A1690),
                          width: 4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA35BFF).withValues(alpha: 0.55),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _session.isLastRound
                              ? 'عرض النتائج النهائية 🏆'
                              : 'التالي (دور ${_session.nextPlayer.name})',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
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
