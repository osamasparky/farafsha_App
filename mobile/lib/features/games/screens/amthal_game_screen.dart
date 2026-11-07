import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/game_session.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';

class AmthalGameScreen extends StatefulWidget {
  final GameSession? session;
  const AmthalGameScreen({super.key, this.session});

  @override
  State<AmthalGameScreen> createState() => _AmthalGameScreenState();
}

class _AmthalGameScreenState extends State<AmthalGameScreen> {
  late GameSession _session;
  int _secondsLeft = 20;
  Timer? _timer;
  int? _selectedOptionIndex;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? _createDefaultSession();
    _startTimer();
  }

  GameSession _createDefaultSession() {
    return GameSession(
      gameSlug: 'amthal-shaabiya',
      gameTitle: 'أمثال شعبية',
      gameRoute: '/game/amthal',
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
          prompt: 'اللي اختشوا …',
          answer: 'ماتوا',
          options: ['ماتوا', 'هربوا', 'سكتوا'],
        ),
        GameQuestion(
          prompt: 'القرد في عين أمه …',
          answer: 'غزال',
          options: ['غزال', 'سلطان', 'جميل'],
        ),
        GameQuestion(
          prompt: 'على قد لحافك …',
          answer: 'مد رجليك',
          options: ['مد رجليك', 'نام وارتاح', 'غطي نفسك'],
        ),
        GameQuestion(
          prompt: 'باب النجار …',
          answer: 'مخلّع',
          options: ['مخلّع', 'مكسور', 'مفتوح'],
        ),
        GameQuestion(
          prompt: 'اطبخ يا جارية كلف يا …',
          answer: 'سيدي',
          options: ['سيدي', 'مولاي', 'معلم'],
        ),
        GameQuestion(
          prompt: 'حبل الكذب …',
          answer: 'قصير',
          options: ['قصير', 'طويل', 'مقطوع'],
        ),
        GameQuestion(
          prompt: 'اللي على راسه بطحة …',
          answer: 'يحسس عليها',
          options: ['يحسس عليها', 'يخبيها', 'ينساها'],
        ),
        GameQuestion(
          prompt: 'يا خبر بفلوس بكرة …',
          answer: 'يبقى ببلاش',
          options: ['يبقى ببلاش', 'ينتشر', 'يخلص'],
        ),
        GameQuestion(
          prompt: 'الصبر مفتاح …',
          answer: 'الفرج',
          options: ['الفرج', 'النجاح', 'السعادة'],
        ),
        GameQuestion(
          prompt: 'عصفور في اليد خير من …',
          answer: 'عشرة على الشجرة',
          options: ['عشرة على الشجرة', 'مية طايرين', 'صيد الغابة'],
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

  void _onSelectOption(int index) {
    if (_isAnswered) return;
    _timer?.cancel();

    final question = _session.currentQuestion;
    final isCorrect = question.options[index] == question.answer;

    setState(() {
      _selectedOptionIndex = index;
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
    final scores = _session.teamScores;
    final entries = scores.entries.toList();

    PauseDialog.show(
      context,
      currentRound: _session.currentRoundNumber,
      totalRounds: _session.totalRounds,
      violetScore: entries.isNotEmpty ? entries.first.value : 0,
      orangeScore: entries.length > 1 ? entries[1].value : 0,
      onResume: _resumeTimer,
      onRestartRound: () {
        setState(() {
          _secondsLeft = 20;
          _selectedOptionIndex = null;
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
      // الانتقال للجولة التالية
      _session.advanceToNextRound();

      // فتح شاشة التسليم للّاعب التالي الحقيقي
      await context.push('/handoff', extra: _session);

      if (!mounted) return;

      // عند عودة التحكم بعد نقر اللاعب التالي على "اكشف الكارت"
      setState(() {
        _secondsLeft = 20;
        _selectedOptionIndex = null;
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
            center: Alignment(0.0, -0.3),
            radius: 1.0,
            colors: [
              Color(0xFF4A2290),
              Color(0xFF241050),
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
                // الشريط العلوي (زر الإيقاف، رقم الجولة، المؤقت)
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

                // لافتة اللاعب النشط لدور هذه الجولة
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

                // شريط اللاعبين الفعليين والنقاط
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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

                // بطاقة المثل الشعبي التراثية البردية
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1850),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'كمّل المثل الشعبي 📜',
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF6E3B8), Color(0xFFE8C98A)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFB88746), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8C5A1E).withValues(alpha: 0.35),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            question.prompt,
                            style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3E2410),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // خيارات الإجابة
                Expanded(
                  child: ListView.separated(
                    itemCount: question.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isSelected = _selectedOptionIndex == index;
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
                          statusIconColor = Colors.white;
                        } else if (isSelected && !isCorrect) {
                          bgColor = const Color(0xFF962D3E);
                          borderColor = const Color(0xFFE74C3C);
                          statusIcon = Icons.cancel_rounded;
                          statusIconColor = Colors.white;
                        }
                      } else if (isSelected) {
                        bgColor = const Color(0xFF6A24C9);
                        borderColor = const Color(0xFFC9A2FF);
                      }

                      return GestureDetector(
                        onTap: () => _onSelectOption(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: bgColor ?? const Color(0xFF2A1850),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFA35BFF).withValues(alpha: 0.55),
                                      blurRadius: 16,
                                    ),
                                  ]
                                : null,
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

                // زر التالي (ينتقل للجولة التالية أو شاشة النتائج)
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
