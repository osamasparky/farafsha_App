import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/game_session.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/pause_dialog.dart';
import '../../../core/widgets/player_avatar_widget.dart';

class TabooCardItem {
  final int id;
  final String prompt;
  final List<String> forbiddenWords;

  TabooCardItem({
    required this.id,
    required this.prompt,
    required this.forbiddenWords,
  });

  factory TabooCardItem.fromMap(Map<String, dynamic> map) {
    final prompt = map['prompt']?.toString() ?? map['title']?.toString() ?? 'كلمة سرية';
    List<String> forbidden = [];
    if (map['forbidden_words'] is List) {
      forbidden = List<String>.from((map['forbidden_words'] as List).map((e) => e.toString()));
    } else if (map['options'] is List) {
      forbidden = List<String>.from((map['options'] as List).map((e) => e.toString()));
    }
    return TabooCardItem(
      id: map['id'] is int ? map['id'] : 0,
      prompt: prompt,
      forbiddenWords: forbidden,
    );
  }
}

class TabooGameScreen extends StatefulWidget {
  final GameSession? session;
  const TabooGameScreen({super.key, this.session});

  @override
  State<TabooGameScreen> createState() => _TabooGameScreenState();
}

class _TabooGameScreenState extends State<TabooGameScreen> {
  late GameSession _session;
  static const int _turnDurationSeconds = 60;
  int _secondsLeft = _turnDurationSeconds;
  Timer? _timer;

  // إحصائيات الجولة الحالية (Turn)
  int _turnCorrectCount = 0;
  int _turnFoulCount = 0;
  int _skipsLeft = 3;

  // قائمة الكروت
  List<TabooCardItem> _cards = [];
  int _currentCardIndex = 0;
  bool _isLoadingCards = true;

  // الكروت الاحتياطية الأصيلة للتجربة الفورية أوفلاين
  final List<TabooCardItem> _fallbackCards = [
    TabooCardItem(
      id: 1,
      prompt: 'كشري',
      forbiddenWords: ['رز', 'عدس', 'مكرونة', 'صلصة', 'دقة'],
    ),
    TabooCardItem(
      id: 2,
      prompt: 'طعمية',
      forbiddenWords: ['فول', 'زيت', 'خضرة', 'سمسم', 'ساندوتش'],
    ),
    TabooCardItem(
      id: 3,
      prompt: 'ملوخية',
      forbiddenWords: ['شوربة', 'طشة', 'توم', 'أرانب', 'خضرا'],
    ),
    TabooCardItem(
      id: 4,
      prompt: 'أهرامات الجيزة',
      forbiddenWords: ['خوفو', 'فراعنة', 'أبو الهول', 'حجر', 'مصر'],
    ),
    TabooCardItem(
      id: 5,
      prompt: 'الشبشب الطاير',
      forbiddenWords: ['أم', 'رجل', 'ضرب', 'بلاستيك', 'نيشان'],
    ),
    TabooCardItem(
      id: 6,
      prompt: 'توك توك',
      forbiddenWords: ['تلات عجلات', 'مهرجانات', 'شارع', 'سائق', 'صغير'],
    ),
    TabooCardItem(
      id: 7,
      prompt: 'عادل إمام',
      forbiddenWords: ['زعيم', 'كوميديا', 'مسرحية', 'مدرسة المشاغبين', 'ممثل'],
    ),
    TabooCardItem(
      id: 8,
      prompt: 'محمد صلاح',
      forbiddenWords: ['ليفربول', 'كورة', 'فخر العرب', 'هدف', 'منتخب'],
    ),
    TabooCardItem(
      id: 9,
      prompt: 'شاحن الموبايل',
      forbiddenWords: ['سلك', 'بطارية', 'فيشة', 'كهرباء', 'نسبة'],
    ),
    TabooCardItem(
      id: 10,
      prompt: 'فانوس رمضان',
      forbiddenWords: ['صيام', 'شمعة', 'صاج', 'إضاءة', 'وحوي'],
    ),
    TabooCardItem(
      id: 11,
      prompt: 'ميكروباص',
      forbiddenWords: ['أجرة', 'سواق', 'كنبة', 'جنيه', 'محطة'],
    ),
    TabooCardItem(
      id: 12,
      prompt: 'العيدية',
      forbiddenWords: ['فلوس', 'عيد', 'أطفال', 'فلوس جديدة', 'أهل'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? _createDefaultSession();
    _loadCards();
  }

  GameSession _createDefaultSession() {
    return GameSession(
      gameSlug: 'forbidden-words',
      gameTitle: 'ممنوع تقول',
      gameRoute: '/game/taboo',
      totalRounds: 6,
      players: [
        GamePlayer(
          id: '1',
          name: 'أحمد',
          teamName: 'فرفوش',
          avatar: 'assets/images/av-ahmed.webp',
          teamColor: const Color(0xFFA35BFF),
        ),
        GamePlayer(
          id: '2',
          name: 'سارة',
          teamName: 'قفوش',
          avatar: 'assets/images/av-sara.webp',
          teamColor: const Color(0xFFFF8A4C),
        ),
        GamePlayer(
          id: '3',
          name: 'محمود',
          teamName: 'فرفوش',
          avatar: 'assets/images/av-mahmoud.webp',
          teamColor: const Color(0xFFA35BFF),
        ),
        GamePlayer(
          id: '4',
          name: 'منة',
          teamName: 'قفوش',
          avatar: 'assets/images/av-mena.webp',
          teamColor: const Color(0xFFFF8A4C),
        ),
      ],
      questions: [],
    );
  }

  Future<void> _loadCards() async {
    try {
      final rawCards = await ApiService.instance.getGameCards('forbidden-words');
      if (rawCards.isNotEmpty) {
        final parsed = rawCards.map((c) => TabooCardItem.fromMap(c)).toList();
        parsed.shuffle();
        if (mounted) {
          setState(() {
            _cards = parsed;
            _isLoadingCards = false;
          });
          _startTimer();
          return;
        }
      }
    } catch (_) {}

    // استخدام الكروت الاحتياطية عند تعذر الاتصال
    _fallbackCards.shuffle();
    if (mounted) {
      setState(() {
        _cards = List.from(_fallbackCards);
        _isLoadingCards = false;
      });
      _startTimer();
    }
  }

  TabooCardItem get _currentCard {
    if (_cards.isEmpty) {
      return TabooCardItem(
        id: 0,
        prompt: 'مكرونة بشاميل',
        forbiddenWords: ['فرن', 'جبنة', 'صينية', 'لحمة مفرومة', 'مكرونة'],
      );
    }
    return _cards[_currentCardIndex % _cards.length];
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _onTurnEnded();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    if (_secondsLeft > 0) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// عند تخمين الكلمة بنجاح: +1 نقطة للاعب والفريق + كارت جديد فوراً
  void _onCorrect() {
    HapticFeedback.heavyImpact();
    SoundService.instance.playCorrect();

    setState(() {
      _turnCorrectCount++;
      // إضافة نقاط الإجابة من دليل احتساب النقاط في لوحة التحكم
      _session.activePlayer.score += _session.pointsPerCorrect;
      _session.activePlayer.correctAnswers += 1;
      _currentCardIndex++;
    });
  }

  /// عند نطق كلمة ممنوعة: خصم 1 نقطة (أو حسب القواعد) + كارت جديد فوراً
  void _onFoul() {
    HapticFeedback.vibrate();
    SoundService.instance.playWrong();

    setState(() {
      _turnFoulCount++;
      // خصم نقطة من رصيد اللاعب بحيث لا يقل عن 0
      _session.activePlayer.score = max(0, _session.activePlayer.score - 1);
      _currentCardIndex++;
    });
  }

  /// عند التخطي: لا توجد نقاط، كارت جديد مع خصم محاولة تخطي
  void _onSkip() {
    if (_skipsLeft > 0) {
      HapticFeedback.lightImpact();
      SoundService.instance.playClick();
      setState(() {
        _skipsLeft--;
        _currentCardIndex++;
      });
    }
  }

  /// انتهاء وقت جولة الشرح (60 ثانية)
  void _onTurnEnded() {
    SoundService.instance.playWrong();
    _showTurnSummaryDialog();
  }

  /// نافذة ملخص الجولة وانتقال الدور
  void _showTurnSummaryDialog() {
    final activePlayer = _session.activePlayer;
    final isFarfoosh = activePlayer.teamName == 'فرفوش';
    final teamColor = isFarfoosh ? const Color(0xFFA35BFF) : const Color(0xFFFF8A4C);

    final farfooshScore = _session.teamScores['فرفوش'] ?? 0;
    final qafooshScore = _session.teamScores['قفوش'] ?? 0;
    final isLastTurn = _session.isLastRound;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241050),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: teamColor.withOpacity(0.5), width: 2),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teamColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    isFarfoosh ? '🟣' : '🟠',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'انتهى الوقت! ⏰',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'جولة فريق ${activePlayer.teamName} (${activePlayer.name})',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: teamColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // إحصائيات هذه الجولة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '+$_turnCorrectCount',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4FD1A5),
                          ),
                        ),
                        Text(
                          'صح ✅',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 35, color: Colors.white12),
                    Column(
                      children: [
                        Text(
                          '-$_turnFoulCount',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF5252),
                          ),
                        ),
                        Text(
                          'مخالفات 🚫',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 35, color: Colors.white12),
                    Column(
                      children: [
                        Text(
                          '${max(0, _turnCorrectCount - _turnFoulCount)}',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: LammaColors.gold300,
                          ),
                        ),
                        Text(
                          'صافي النقاط ⭐️',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // النتيجة الإجمالية للفريقين
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFA35BFF).withOpacity(0.15),
                      const Color(0xFFFF8A4C).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🟣 فرفوش: $farfooshScore',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFD6B4FF),
                      ),
                    ),
                    Text(
                      'الجولة ${_session.currentRoundNumber} من ${_session.totalRounds}',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.white38),
                    ),
                    Text(
                      'قفوش: $qafooshScore 🟠',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFBE99),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastTurn ? LammaColors.gold500 : teamColor,
                foregroundColor: isLastTurn ? const Color(0xFF1E0E3E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);

                if (isLastTurn) {
                  // انتهاء كامل جولات اللعبة والانتقال للنتائج النهائية والتتويج
                  context.go('/results', extra: _session);
                } else {
                  // بدء الجولة التالية وتسليم الموبايل للاعب التالي
                  setState(() {
                    _session.advanceToNextRound();
                    _secondsLeft = _turnDurationSeconds;
                    _turnCorrectCount = 0;
                    _turnFoulCount = 0;
                    _skipsLeft = 3;
                    _currentCardIndex++;
                  });
                  _startTimer();
                }
              },
              child: Text(
                isLastTurn
                    ? 'عرض النتائج وتتويج الفائز 🏆'
                    : 'سلّم الموبايل لـ ${_session.nextPlayer.name} (${_session.nextPlayer.teamName}) 🚀',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openPauseModal() {
    _pauseTimer();
    final farfoosh = _session.teamScores['فرفوش'] ?? 0;
    final qafoosh = _session.teamScores['قفوش'] ?? 0;

    PauseDialog.show(
      context,
      session: _session,
      currentRound: _session.currentRoundNumber,
      totalRounds: _session.totalRounds,
      gameTitle: 'ممنوع تقول',
      gameSlug: 'forbidden-words',
      violetScore: farfoosh,
      orangeScore: qafoosh,
      onResume: _resumeTimer,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCards) {
      return const Scaffold(
        backgroundColor: Color(0xFF150A2E),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: LammaColors.gold500),
              SizedBox(height: 16),
              Text(
                'جاري تجهيز كروت التحدي...',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),
      );
    }

    final double progress = (_secondsLeft / _turnDurationSeconds).clamp(0.0, 1.0);
    final card = _currentCard;
    final activePlayer = _session.activePlayer;
    final isFarfoosh = activePlayer.teamName == 'فرفوش';
    final teamColor = isFarfoosh ? const Color(0xFFA35BFF) : const Color(0xFFFF8A4C);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.0,
            colors: [
              Color(0xFF3A2CA0),
              Color(0xFF201460),
              Color(0xFF120A30),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Column(
              children: [
                // الشريط العلوي (زر الإيقاف + من يشرح وفريقه + الجولة)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _openPauseModal,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: teamColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: teamColor.withOpacity(0.7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlayerAvatarWidget(
                            avatarPath: activePlayer.avatar,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activePlayer.name} بيشرح · ${activePlayer.teamName}',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'جولة ${_session.currentRoundNumber}/${_session.totalRounds}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD6C8F5),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // صف العداد والإحصائيات الحية
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // عداد الإجابات الصحيحة
                    Container(
                      width: 86,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D3B38).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF4FD1A5).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_turnCorrectCount',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: const Color(0xFF4FD1A5),
                            ),
                          ),
                          Text(
                            'صح (+1)',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB5F2DC),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),

                    // الدائرة التنازلية للوقت
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A0F40).withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: (_secondsLeft <= 10 ? const Color(0xFFFF5252) : const Color(0xFFFF9E4C))
                                .withValues(alpha: 0.28),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6.5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _secondsLeft <= 10 ? const Color(0xFFFF5252) : const Color(0xFFFF9E4C),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_secondsLeft',
                                style: GoogleFonts.cairo(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ثانية',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  color: const Color(0xFFCFC6E4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 18),

                    // عداد المخالفات
                    Container(
                      width: 86,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E182E).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_turnFoulCount',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: const Color(0xFFFF6B7A),
                            ),
                          ),
                          Text(
                            'مخالفة (-1)',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFC1C8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // كارت التابو بتصميم فرفشة ثلاثي الأبعاد
                Expanded(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.01,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 360),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF281154), Color(0xFF170834)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: teamColor.withValues(alpha: 0.65),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: teamColor.withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // رأس الكارت مع الكلمة الرئيسية
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isFarfoosh
                                      ? [const Color(0xFF7B61FF), const Color(0xFF472FD8)]
                                      : [const Color(0xFFFF8A4C), const Color(0xFFD84E16)],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'اشرح الكلمة دي لفريقك 🎯',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      card.prompt,
                                      style: GoogleFonts.cairo(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // قائمة الكلمات الممنوعة
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.block_rounded, color: Color(0xFFFF6B8B), size: 17),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ممنوع تقول (الكلمات المحظورة)',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFFF8DA6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ...card.forbiddenWords.map(
                                    (word) => Container(
                                      margin: const EdgeInsets.only(bottom: 7),
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF351968),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: const Color(0xFFFF5E7E).withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFFF6B8B),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              word,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.cairo(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // صف أزرار التحكم (تخطي، قال ممنوعة، صح!)
                Row(
                  children: [
                    // زر تخطي
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _skipsLeft > 0 ? _onSkip : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _skipsLeft > 0 ? 1.0 : 0.4,
                          child: Container(
                            height: 68,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B1459),
                              borderRadius: BorderRadius.circular(20),
                              border: const Border(
                                bottom: BorderSide(color: Color(0xFF170933), width: 4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'تخطي ($_skipsLeft)',
                                    maxLines: 1,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر قال ممنوعة (مخالفة)
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _onFoul,
                        child: Container(
                          height: 68,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFF5E78), Color(0xFFC8344E)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFF831D31), width: 4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5E78).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'قال ممنوعة (-1)',
                                  maxLines: 1,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر صح! (الكبير والأخضر)
                    Expanded(
                      flex: 4,
                      child: GestureDetector(
                        onTap: _onCorrect,
                        child: Container(
                          height: 68,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF4FD1A5), Color(0xFF2B9C79)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFF1A6B52), width: 4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4FD1A5).withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, color: Color(0xFF0E2A22), size: 24),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'صح! (+1)',
                                  maxLines: 1,
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0E2A22),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
