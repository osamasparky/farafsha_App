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

class _TabooGameScreenState extends State<TabooGameScreen> with SingleTickerProviderStateMixin {
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
      _session.activePlayer.score += 1;
      _session.activePlayer.correctAnswers += 1;
      _currentCardIndex++;
    });
  }

  /// عند نطق كلمة ممنوعة: خصم 1 نقطة + كارت جديد فوراً
  void _onFoul() {
    HapticFeedback.vibrate();
    SoundService.instance.playWrong();

    setState(() {
      _turnFoulCount++;
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
    final isLastTurn = _session.isLastRound;

    final farfooshScore = _session.teamScores['فرفوش'] ?? 0;
    final qafooshScore = _session.teamScores['قفوش'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241050),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: teamColor.withOpacity(0.5), width: 2),
          ),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teamColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    isFarfoosh ? '🟣' : '🟠',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'انتهى الوقت! ⏰',
                style: GoogleFonts.cairo(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'جولة فريق ${activePlayer.teamName} (${activePlayer.name})',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: teamColor,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // إحصائيات هذه الجولة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '+$_turnCorrectCount',
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4FD1A5),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'صح ✅',
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white12),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '-$_turnFoulCount',
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFF5252),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'مخالفات 🚫',
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white12),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${max(0, _turnCorrectCount - _turnFoulCount)}',
                              style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: LammaColors.gold300,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'صافي النقاط ⭐️',
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // النتيجة الإجمالية للفريقين
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    children: [
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerRight,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '🟣 فرفوش: $farfooshScore',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD6B4FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الجولة ${_session.currentRoundNumber}/${_session.totalRounds}',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.white38),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'قفوش: $qafooshScore 🟠',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFBE99),
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

    // حساب نقاط الفريقين
    final farfooshScore = _session.teamScores['فرفوش'] ?? 0;
    final qafooshScore = _session.teamScores['قفوش'] ?? 0;

    // ألوان المؤقت الديناميكية بحسب الوقت المتبقي
    final Color timerColor = _secondsLeft <= 10
        ? const Color(0xFFFF3B30)
        : _secondsLeft <= 20
            ? const Color(0xFFFF9500)
            : const Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: const Color(0xFF13092A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF26124B),
              Color(0xFF180A35),
              Color(0xFF0F0622),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              children: [
                // 1. الشريط العلوي (HUD Header)
                _buildHeader(teamColor, isFarfoosh, activePlayer),

                const SizedBox(height: 10),

                // 2. لوحة المؤقت والمواجهة الحية (فرفوش ضد قفوش)
                _buildLiveRivalryBar(
                  farfooshScore: farfooshScore,
                  qafooshScore: qafooshScore,
                  progress: progress,
                  timerColor: timerColor,
                ),

                const SizedBox(height: 10),

                // 3. كارت التابو الأسطوري بتصميم بطاقة لعب فيزيائية
                Expanded(
                  child: _buildTabooCard(card, teamColor, isFarfoosh),
                ),

                const SizedBox(height: 12),

                // 4. منطقة التحكم والأزرار التفاعلية المعاد تصميمها كلياً
                _buildActionControlPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. الشريط العلوي: زر الإيقاف + هوية الشارح + رقم الجولة
  Widget _buildHeader(Color teamColor, bool isFarfoosh, GamePlayer activePlayer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // زر الإيقاف المؤقت
        GestureDetector(
          onTap: _openPauseModal,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.pause_rounded, color: Colors.white, size: 22),
          ),
        ),

        // بادج اللاعب الذي يشرح الآن
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: teamColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: teamColor.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: teamColor.withOpacity(0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundImage: AssetImage(activePlayer.avatar),
              ),
              const SizedBox(width: 8),
              Text(
                '${activePlayer.name} بيشرح',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: teamColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  activePlayer.teamName,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // مؤشر رقم الجولة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style_rounded, size: 14, color: Color(0xFFD6C8F5)),
              const SizedBox(width: 4),
              Text(
                '${_session.currentRoundNumber}/${_session.totalRounds}',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE4DAFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. لوحة النتائج المباشرة والمؤقت التنازلي التفاعلي
  Widget _buildLiveRivalryBar({
    required int farfooshScore,
    required int qafooshScore,
    required double progress,
    required Color timerColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F113D).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // فريق فرفوش (النقاط)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFA35BFF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA35BFF).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🟣', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فرفوش',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD6B4FF),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '$farfooshScore',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // عداد الوقت الدائري التنازلي في المنتصف
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFF2C1656),
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF13092A),
                    boxShadow: [
                      BoxShadow(
                        color: timerColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_secondsLeft',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: timerColor,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'ثانية',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white60,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // فريق قفوش (النقاط)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A4C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF8A4C).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🟠', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قفوش',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFBE99),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '$qafooshScore',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. كارت التابو الأسطوري
  Widget _buildTabooCard(TabooCardItem card, Color teamColor, bool isFarfoosh) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey<int>(_currentCardIndex),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 390),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isFarfoosh ? const Color(0xFFC49BFD) : const Color(0xFFFFB88E),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: teamColor.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // ترويسة الكارت الفاخرة (الكلمة المستهدفة للشرح)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isFarfoosh
                      ? [const Color(0xFF7A42E4), const Color(0xFF4C1D95)]
                      : [const Color(0xFFFF7235), const Color(0xFFC2410C)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'اشرح الكلمة دي لفريقك بدون ما تقول المحظورات',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF3EDFF),
                          ),
                        ),
                      ],
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
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // قسم الكلمات المحظورة "ممنوع تقول"
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    // شريط التحذير
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'ممنوع تقول (الكلمات المحظورة):',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // الكلمات الممنوعة الخمس في كروت خطر واضحة وأنيقة
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: card.forbiddenWords.map((word) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDA4AF), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF43F5E).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.close_rounded, size: 13, color: Color(0xFFE11D48)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    word,
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF881337),
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. منطقة التحكم والأزرار التفاعلية المعاد تصميمها كلياً
  Widget _buildActionControlPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زر التخطي كشريط ذكي وأنيق يوضح الفرص المتبقية
        GestureDetector(
          onTap: _skipsLeft > 0 ? _onSkip : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _skipsLeft > 0 ? 1.0 : 0.45,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _skipsLeft > 0 ? Colors.white.withOpacity(0.2) : Colors.white10,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fast_forward_rounded,
                        color: _skipsLeft > 0 ? const Color(0xFFFFD166) : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تخطي الكارت الحالية',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _skipsLeft > 0 ? Colors.white : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  // مؤشرات محاولات التخطي المتبقية
                  Row(
                    children: [
                      Text(
                        'متبقي ($_skipsLeft/3)',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFD166),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...List.generate(3, (index) {
                        final isAvailable = index < _skipsLeft;
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAvailable ? const Color(0xFFFFD166) : Colors.white24,
                            boxShadow: isAvailable
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFD166).withOpacity(0.6),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // زرا التحكم الرئيسيان في اللعبة (صح! على اليمين + قال ممنوع! على اليسار)
        Row(
          children: [
            // زر "صح! (+1)" - الزر الإيجابي الرئيسي على اليمين
            Expanded(
              flex: 1,
              child: _TactileActionButton(
                title: 'صح! 🎉',
                subtitle: '+1 نقطة',
                gradientColors: const [Color(0xFF34D399), Color(0xFF059669)],
                shadowColor: const Color(0xFF059669),
                bevelColor: const Color(0xFF065F46),
                icon: Icons.check_circle_rounded,
                onPressed: _onCorrect,
              ),
            ),

            const SizedBox(width: 12),

            // زر "قال ممنوع! (-1)" - زر المخالفة / البازر على اليسار
            Expanded(
              flex: 1,
              child: _TactileActionButton(
                title: 'قال ممنوع!',
                subtitle: '-1 مخالفة',
                gradientColors: const [Color(0xFFFF4D4D), Color(0xFFDC2626)],
                shadowColor: const Color(0xFFDC2626),
                bevelColor: const Color(0xFF991B1B),
                icon: Icons.cancel_rounded,
                onPressed: _onFoul,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ودجت الزر الفيزيائي التفاعلي الممتع (3D Tactile Button)
class _TactileActionButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color shadowColor;
  final Color bevelColor;
  final IconData icon;
  final VoidCallback onPressed;

  const _TactileActionButton({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.shadowColor,
    required this.bevelColor,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_TactileActionButton> createState() => _TactileActionButtonState();
}

class _TactileActionButtonState extends State<_TactileActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        height: 70,
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.gradientColors,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: widget.shadowColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.bevelColor,
                    offset: const Offset(0, 5),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: widget.shadowColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.title,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.subtitle,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.1,
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
    );
  }
}
