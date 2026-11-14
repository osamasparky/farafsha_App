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
      // إضافة نقطة للاعب والفريق
      _session.activePlayer.score += 1;
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
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: AssetImage(activePlayer.avatar),
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_turnCorrectCount',
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4FD1A5),
                          ),
                        ),
                        Text(
                          'صح (+1)',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFCFC6E4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // الدائرة التنازلية للوقت
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 7,
                            backgroundColor: const Color(0xFF1A0F40),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _secondsLeft <= 10 ? const Color(0xFFFF5252) : const Color(0xFFFF9E4C),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_secondsLeft',
                                style: GoogleFonts.cairo(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'ثانية',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFCFC6E4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // عداد المخالفات
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_turnFoulCount',
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF5252),
                          ),
                        ),
                        Text(
                          'مخالفة (-1)',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFCFC6E4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // كارت التابو المائل
                Expanded(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.015,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 360),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: teamColor.withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // رأس الكارت مع الكلمة الرئيسية
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isFarfoosh
                                      ? [const Color(0xFF6A5AF0), const Color(0xFF3B2CB0)]
                                      : [const Color(0xFFFF7A3D), const Color(0xFFD64D12)],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'اشرح الكلمة دي لفريقك:',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF1EDFF),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.prompt,
                                    style: GoogleFonts.cairo(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            // قائمة الكلمات الممنوعة
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.block_rounded, color: Color(0xFFA3264F), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ممنوع تقول (الكلمات المحظورة):',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFA3264F),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...card.forbiddenWords.map(
                                    (word) => Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDE3EE),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFCADB)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          word,
                                          style: GoogleFonts.cairo(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF8E1F4E),
                                          ),
                                        ),
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // زر تخطي
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _skipsLeft > 0 ? _onSkip : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _skipsLeft > 0 ? 1.0 : 0.4,
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                                const SizedBox(height: 2),
                                Text(
                                  'تخطي ($_skipsLeft)',
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
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
                      flex: 1,
                      child: GestureDetector(
                        onTap: _onFoul,
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFE0566B), Color(0xFFB23A50)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFF7A2236), width: 4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE0566B).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                              const SizedBox(height: 2),
                              Text(
                                'قال ممنوعة (-1)',
                                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر صح! (الكبير والأخضر)
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _onCorrect,
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF4FD1A5), Color(0xFF2E9D7B)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFF1A6B52), width: 5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4FD1A5).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, color: Color(0xFF0E2A22), size: 28),
                              const SizedBox(height: 2),
                              Text(
                                'صح! (+1)',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0E2A22),
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
