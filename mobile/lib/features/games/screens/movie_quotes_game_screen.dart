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
          teamName: 'فرفوش',
          avatar: 'assets/images/av-ahmed.png',
          teamColor: const Color(0xFFA35BFF),
        ),
        GamePlayer(
          id: '2',
          name: 'سارة',
          teamName: 'قفوش',
          avatar: 'assets/images/av-sara.png',
          teamColor: const Color(0xFFFF8A4C),
        ),
        GamePlayer(
          id: '3',
          name: 'محمود',
          teamName: 'فرفوش',
          avatar: 'assets/images/av-mahmoud.png',
          teamColor: const Color(0xFFA35BFF),
        ),
        GamePlayer(
          id: '4',
          name: 'منة',
          teamName: 'قفوش',
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
      // تصفير حالة الإجابة فوراً قبل الانتقال للجولة التالية لمنع وميض الإجابة بالأخضر
      setState(() {
        _selectedChoiceIndex = null;
        _isAnswered = false;
        _secondsLeft = 15;
      });

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
                      behavior: HitTestBehavior.opaque,
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

                // بطاقة الإفيه السينمائي الفاخرة بنمط تذكرة السينما الذهبية
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2A0F54), Color(0xFF1B0738)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // شريط كلاكيت السينما
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.movie_filter_rounded, color: Color(0xFFFFD166), size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                question.explanation ?? 'إفيهات من السينما والدراما المصرية',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFE59E),
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // نص الإفيه السينمائي البارز
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: Column(
                          children: [
                            Text(
                              question.prompt,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: GoogleFonts.cairo(
                                fontSize: question.prompt.length > 60
                                    ? 19.0
                                    : (question.prompt.length > 30 ? 22.0 : 26.0),
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.35,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // خيارات الإجابة بنمط كروت 3D لمسية
                Expanded(
                  child: ListView.separated(
                    itemCount: question.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isSelected = _selectedChoiceIndex == index;
                      final isCorrect = option == question.answer;

                      final List<String> letters = ['أ', 'ب', 'ج', 'د'];
                      final letter = index < letters.length ? letters[index] : '${index + 1}';

                      Color bgColor = const Color(0xFF24104D);
                      Color bevelColor = const Color(0xFF170836);
                      Color borderColor = Colors.white.withOpacity(0.12);
                      Color badgeBg = Colors.white.withOpacity(0.12);
                      Color badgeText = Colors.white70;
                      IconData? statusIcon;
                      Color statusIconColor = Colors.white;

                      if (_isAnswered) {
                        if (isCorrect) {
                          bgColor = const Color(0xFF059669);
                          bevelColor = const Color(0xFF04533C);
                          borderColor = const Color(0xFF34D399);
                          badgeBg = Colors.white.withOpacity(0.25);
                          badgeText = Colors.white;
                          statusIcon = Icons.check_circle_rounded;
                          statusIconColor = Colors.white;
                        } else if (isSelected && !isCorrect) {
                          bgColor = const Color(0xFFDC2626);
                          bevelColor = const Color(0xFF991B1B);
                          borderColor = const Color(0xFFF87171);
                          badgeBg = Colors.white.withOpacity(0.25);
                          badgeText = Colors.white;
                          statusIcon = Icons.cancel_rounded;
                          statusIconColor = Colors.white;
                        }
                      } else if (isSelected) {
                        bgColor = const Color(0xFF7A3BE0);
                        bevelColor = const Color(0xFF501FB0);
                        borderColor = const Color(0xFFD6B4FF);
                        badgeBg = const Color(0xFFFFD166);
                        badgeText = const Color(0xFF1E0E3E);
                      }

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onSelectChoice(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: bevelColor,
                                offset: const Offset(0, 4),
                                blurRadius: 0,
                              ),
                              if (isSelected || (_isAnswered && isCorrect))
                                BoxShadow(
                                  color: (isCorrect ? const Color(0xFF059669) : const Color(0xFFA35BFF))
                                      .withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // شارة الحرف
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.start,
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
                  behavior: HitTestBehavior.opaque,
                  onTap: _onNext,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _session.isLastRound
                            ? [const Color(0xFFFFC043), const Color(0xFFFF9500)]
                            : [const Color(0xFFA866FF), const Color(0xFF742BE0)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _session.isLastRound ? const Color(0xFFB36700) : const Color(0xFF4C179C),
                          offset: const Offset(0, 5),
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: (_session.isLastRound ? const Color(0xFFFF9500) : const Color(0xFFA35BFF))
                              .withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
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
