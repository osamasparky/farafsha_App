import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/game_session.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';
import '../../../core/widgets/pause_dialog.dart';

class AutobusGameScreen extends StatefulWidget {
  final GameSession? session;

  const AutobusGameScreen({
    super.key,
    this.session,
  });

  @override
  State<AutobusGameScreen> createState() => _AutobusGameScreenState();
}

class _AutobusGameScreenState extends State<AutobusGameScreen> with SingleTickerProviderStateMixin {
  late GameSession? _session;
  int _roundIndex = 0;
  int _totalRounds = 8;
  int _secondsLeft = 60;
  final int _roundDuration = 60;
  Timer? _timer;

  bool _isStoppingCountdown = false;
  int _stopSecondsLeft = 10;
  Timer? _stopTimer;

  bool _isInputMode = false;
  bool _showAnswers = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _cards = [];
  Map<String, dynamic>? _currentCard;
  String _currentLetter = 'ب';

  final List<String> _categories = [
    'ولد',
    'بنت',
    'حيوان',
    'نبات',
    'جماد',
    'بلاد',
    'أكلة',
    'مهنة',
  ];

  final Map<String, IconData> _categoryIcons = {
    'ولد': Icons.person_rounded,
    'بنت': Icons.face_3_rounded,
    'حيوان': Icons.pets_rounded,
    'نبات': Icons.eco_rounded,
    'جماد': Icons.category_rounded,
    'بلاد': Icons.public_rounded,
    'أكلة': Icons.restaurant_rounded,
    'مهنة': Icons.work_rounded,
  };

  final Map<String, TextEditingController> _inputControllers = {};
  late AnimationController _letterAnimController;
  late Animation<double> _letterScaleAnim;

  // فرق وافتراضيات اللعب الجماعي إن لم توجد جلسة
  final List<Map<String, dynamic>> _teams = [
    {'name': 'فرفوش', 'score': 0, 'color': const Color(0xFFA35BFF)},
    {'name': 'قفوش', 'score': 0, 'color': const Color(0xFFFF8A4C)},
  ];

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    if (_session != null) {
      _totalRounds = _session!.totalRounds;
      _roundIndex = _session!.currentRoundIndex;
    }

    for (var cat in _categories) {
      _inputControllers[cat] = TextEditingController();
    }

    _letterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _letterScaleAnim = CurvedAnimation(
      parent: _letterAnimController,
      curve: Curves.elasticOut,
    );
    _letterAnimController.forward();

    _loadGameCards();
  }

  Future<void> _loadGameCards() async {
    setState(() => _isLoading = true);
    final cards = await ApiService.instance.getGameCards('autobus-complete');
    if (mounted) {
      setState(() {
        _cards = cards.isNotEmpty ? cards : _getFallbackCards();
        _cards.shuffle();
        _setCurrentRoundCard();
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _setCurrentRoundCard() {
    if (_cards.isNotEmpty) {
      final index = _roundIndex % _cards.length;
      _currentCard = _cards[index];
      final prompt = _currentCard?['prompt']?.toString() ?? 'حرف (ب)';
      final match = RegExp(r'\((.+?)\)').firstMatch(prompt);
      _currentLetter = match != null ? match.group(1)! : (prompt.replaceAll(RegExp(r'[^\u0621-\u064A]'), '').isNotEmpty ? prompt.replaceAll(RegExp(r'[^\u0621-\u064A]'), '')[0] : 'ب');
    } else {
      _currentLetter = 'ب';
    }

    // مسح الحقول عند كل جولة جديدة
    for (var ctrl in _inputControllers.values) {
      ctrl.clear();
    }
    _showAnswers = false;
    _isStoppingCountdown = false;
    _secondsLeft = _roundDuration;

    _letterAnimController.reset();
    _letterAnimController.forward();
  }

  void _startTimer() {
    _timer?.cancel();
    _stopTimer?.cancel();
    _isStoppingCountdown = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _onTimeUp();
      }
    });
  }

  void _pauseGame() {
    _timer?.cancel();
    _stopTimer?.cancel();

    int vScore = _session != null
        ? (_session!.teamScores['فرفوش'] ?? _session!.teamScores['فريق البنفسج'] ?? 0)
        : (_teams[0]['score'] as int);
    int oScore = _session != null
        ? (_session!.teamScores['قفوش'] ?? _session!.teamScores['فريق البرتقان'] ?? 0)
        : (_teams[1]['score'] as int);

    PauseDialog.show(
      context,
      currentRound: _roundIndex + 1,
      totalRounds: _totalRounds,
      gameTitle: 'أتوبيس كومبليت',
      gameSlug: 'autobus-complete',
      violetScore: vScore,
      orangeScore: oScore,
      onResume: () {
        if (_isStoppingCountdown) {
          _resumeStopTimer();
        } else if (_secondsLeft > 0) {
          _startTimer();
        }
      },
    );
  }

  // الضغط على زر "أتوبيس كومبليت!" الشهير
  void _onAutobusCompletePressed() {
    if (_isStoppingCountdown) return;

    SettingsService.instance.triggerHaptic(isHeavy: true);
    SoundService.instance.playCorrect();

    setState(() {
      _isStoppingCountdown = true;
      _stopSecondsLeft = 10;
    });

    _timer?.cancel();
    _stopTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_stopSecondsLeft > 0) {
        setState(() => _stopSecondsLeft--);
        if (_stopSecondsLeft <= 3) {
          HapticFeedback.heavyImpact();
        }
      } else {
        _stopTimer?.cancel();
        _openScoringSheet();
      }
    });
  }

  void _resumeStopTimer() {
    _stopTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_stopSecondsLeft > 0) {
        setState(() => _stopSecondsLeft--);
      } else {
        _stopTimer?.cancel();
        _openScoringSheet();
      }
    });
  }

  void _onTimeUp() {
    SettingsService.instance.triggerHaptic(isHeavy: true);
    SoundService.instance.playWrong();
    _openScoringSheet();
  }

  void _skipLetter() {
    setState(() {
      _cards.shuffle();
      _setCurrentRoundCard();
      _startTimer();
    });
  }

  // التحقق إن كانت الكلمة تبدأ بحرف الجولة
  bool _isWordValid(String word) {
    final clean = word.trim().replaceAll(RegExp(r'^(ال|أل|إل)'), '');
    if (clean.isEmpty) return false;
    final firstChar = clean[0];
    return firstChar == _currentLetter ||
        (_currentLetter == 'أ' && ['ا', 'أ', 'إ', 'آ'].contains(firstChar));
  }

  // فتح كشف رصد النقاط للجولة
  void _openScoringSheet() {
    _timer?.cancel();
    _stopTimer?.cancel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final isSessionTeams = _session != null && _session!.players.isNotEmpty;
          final teamsList = isSessionTeams
              ? _session!.teamScores.keys.toList()
              : _teams.map((t) => t['name'] as String).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF24104B), Color(0xFF14072B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Color(0xFFFF8A4C), width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'رصد نقاط جولة: حرف ($_currentLetter) 📝',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'قاعدة النقاط: 10 للفريدة | 5 للمكررة | 0 للفارغ أو الخطأ',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: const Color(0xFFFFCC80),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),

                // إجابات مقترحة للمذيع
                if (_currentCard?['acceptable_alternatives'] is Map) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أمثلة إجابات صحيحة للمساعدة:',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentCard!['answer']?.toString() ?? '',
                          style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFFD9CCF2)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // بطاقات الفرق لإضافة النقاط بسرعة
                Expanded(
                  child: ListView.builder(
                    itemCount: teamsList.length,
                    itemBuilder: (context, i) {
                      final teamName = teamsList[i];
                      int currentScore = 0;
                      if (isSessionTeams) {
                        currentScore = _session!.teamScores[teamName] ?? 0;
                      } else {
                        currentScore = (_teams[i]['score'] as int);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF341765),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: i == 0 ? const Color(0xFFA35BFF) : const Color(0xFFFF8A4C),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: i == 0 ? const Color(0xFFA35BFF) : const Color(0xFFFF8A4C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teamName,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'النقاط الإجمالية: $currentScore',
                                    style: GoogleFonts.cairo(color: const Color(0xFFD9CCF2), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // أزرار إضافة النقاط السريعة
                            Wrap(
                              spacing: 6,
                              children: [
                                _buildScorePill(
                                  label: '+5',
                                  color: Colors.amber,
                                  onTap: () {
                                    setModalState(() {
                                      _addScoreToTeam(teamName, i, 5);
                                    });
                                  },
                                ),
                                _buildScorePill(
                                  label: '+10',
                                  color: const Color(0xFF35B88E),
                                  onTap: () {
                                    setModalState(() {
                                      _addScoreToTeam(teamName, i, 10);
                                    });
                                  },
                                ),
                                _buildScorePill(
                                  label: '+20',
                                  color: const Color(0xFFFF8A4C),
                                  onTap: () {
                                    setModalState(() {
                                      _addScoreToTeam(teamName, i, 20);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // زر الانتقال للجولة التالية
                GameButton(
                  text: (_roundIndex + 1 >= _totalRounds)
                      ? 'عرض النتائج والفائزين 🏆'
                      : 'الجولة التالية (${_roundIndex + 2}/$_totalRounds) ⏭️',
                  onPressed: () {
                    Navigator.pop(modalContext);
                    _nextRound();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addScoreToTeam(String teamName, int index, int points) {
    SettingsService.instance.triggerHaptic(isHeavy: false);
    SoundService.instance.playCorrect();

    if (_session != null && _session!.players.isNotEmpty) {
      final teamPlayers = _session!.players.where((p) => p.teamName == teamName).toList();
      if (teamPlayers.isNotEmpty) {
        teamPlayers.first.score += points;
        teamPlayers.first.correctAnswers += 1;
      }
    } else {
      setState(() {
        _teams[index]['score'] = (_teams[index]['score'] as int) + points;
      });
    }
  }

  Widget _buildScorePill({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _nextRound() {
    if (_roundIndex + 1 >= _totalRounds) {
      // نهاية اللعبة
      if (_session != null) {
        context.pushReplacement('/results', extra: _session);
      } else {
        final sorted = List<Map<String, dynamic>>.from(_teams)
          ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
        context.pushReplacement('/results', extra: {
          'winnerTeam': sorted[0]['name'],
          'winnerScore': sorted[0]['score'],
          'runnerUpTeam': sorted.length > 1 ? sorted[1]['name'] : 'المنافس',
          'runnerUpScore': sorted.length > 1 ? sorted[1]['score'] : 0,
        });
      }
    } else {
      setState(() {
        _roundIndex++;
        if (_session != null) {
          _session!.currentRoundIndex = _roundIndex;
        }
        _setCurrentRoundCard();
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopTimer?.cancel();
    _letterAnimController.dispose();
    for (var ctrl in _inputControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: LammaColors.gold500))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // شريط الرأس: الجولة، الإيقاف، وتبديل النمط
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.pause_circle_outline_rounded, color: Colors.white, size: 28),
                          onPressed: _pauseGame,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF24104B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: LammaColors.cardBorder),
                          ),
                          child: Text(
                            'الجولة ${_roundIndex + 1} من $_totalRounds',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // زر التبديل بين الكتابة في التطبيق vs المذيع للقعدة
                        IconButton(
                          icon: Icon(
                            _isInputMode ? Icons.groups_rounded : Icons.edit_note_rounded,
                            color: LammaColors.gold300,
                            size: 26,
                          ),
                          tooltip: _isInputMode ? 'وضع اللمّة والمذيع' : 'وضع الكتابة في التطبيق',
                          onPressed: () {
                            setState(() => _isInputMode = !_isInputMode);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // كارت الحرف المركزي العملاق والمؤقت
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B1568), Color(0xFF1B0733)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isStoppingCountdown ? const Color(0xFFFF5252) : const Color(0xFFFF8A4C),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isStoppingCountdown ? const Color(0xFFFF5252) : const Color(0xFFFF8A4C))
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // الحرف بحجم ضخم وحركة ارتداد
                          ScaleTransition(
                            scale: _letterScaleAnim,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF9E40), Color(0xFFFF5400)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _currentLetter,
                                style: GoogleFonts.cairo(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'حرف الجولة',
                                      style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: _skipLetter,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.refresh_rounded, color: LammaColors.gold300, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'تغيير الحرف',
                                            style: GoogleFonts.cairo(
                                              color: LammaColors.gold300,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isStoppingCountdown
                                      ? '🛑 أتوبيس كومبليت! أقلامكم فوق خلال:'
                                      : 'اكتب كلمات تبدأ بحرف ($_currentLetter)',
                                  style: GoogleFonts.cairo(
                                    color: _isStoppingCountdown ? const Color(0xFFFFB4B4) : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // عداد الثواني
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_rounded,
                                      size: 16,
                                      color: _isStoppingCountdown
                                          ? const Color(0xFFFF5252)
                                          : (_secondsLeft <= 10 ? Colors.redAccent : LammaColors.gold500),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isStoppingCountdown
                                          ? '$_stopSecondsLeft ثوانٍ متبقية!'
                                          : '00:${_secondsLeft.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: _isStoppingCountdown
                                            ? const Color(0xFFFF5252)
                                            : (_secondsLeft <= 10 ? Colors.redAccent : LammaColors.gold500),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // التلميح أو المعلومة الخفيفة
                    if (_currentCard?['explanation'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: LammaColors.gold500, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentCard!['explanation'].toString(),
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: const Color(0xFFD9CCF2),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // قائمة التصنيفات الثمانية
                    Expanded(
                      child: _isInputMode ? _buildInteractiveInputList() : _buildPartyCategoryGrid(),
                    ),

                    const SizedBox(height: 10),

                    // زر أتوبيس كومبليت العملاق التفاعلي
                    GestureDetector(
                      onTap: _onAutobusCompletePressed,
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFD81B60)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: const Border(
                            top: BorderSide(color: Colors.white60, width: 2),
                            bottom: BorderSide(color: Color(0xFF880E4F), width: 5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E00).withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🚌', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 8),
                            Text(
                              'أتوبيس كومبليت! 🛑',
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
      ),
    );
  }

  // شبكة التصنيفات في وضع المذيع واللمّة الجماعية
  Widget _buildPartyCategoryGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final icon = _categoryIcons[category] ?? Icons.stars_rounded;

        String? sampleAnswer;
        if (_currentCard?['acceptable_alternatives'] is Map) {
          sampleAnswer = _currentCard!['acceptable_alternatives'][category]?.toString();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF261048),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LammaColors.cardBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: LammaColors.violet500.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: LammaColors.gold300, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (_showAnswers && sampleAnswer != null)
                      Text(
                        sampleAnswer,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF69F0AE),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // قائمة إدخال الكلمات التفاعلية
  Widget _buildInteractiveInputList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final icon = _categoryIcons[category] ?? Icons.stars_rounded;
        final ctrl = _inputControllers[category]!;
        final text = ctrl.text;
        final bool hasText = text.trim().isNotEmpty;
        final bool isValid = _isWordValid(text);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF24104B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasText
                  ? (isValid ? const Color(0xFF35B88E) : const Color(0xFFE57373))
                  : LammaColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: LammaColors.gold300, size: 20),
              const SizedBox(width: 10),
              SizedBox(
                width: 55,
                child: Text(
                  category,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'كلمة تبدأ بـ ($_currentLetter)...',
                    hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (hasText)
                Icon(
                  isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isValid ? const Color(0xFF35B88E) : const Color(0xFFE57373),
                  size: 20,
                ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFallbackCards() {
    return [
      {
        'prompt': 'حرف (ب)',
        'answer': 'ولد: باسل | بنت: بسمة | حيوان: بطريق | نبات: بطيخ | جماد: برواز | بلاد: بيروت | أكلة: بامية | مهنة: بحار',
        'acceptable_alternatives': {
          'ولد': 'باسل',
          'بنت': 'بسمة',
          'حيوان': 'بطريق',
          'نبات': 'بطيخ',
          'جماد': 'برواز',
          'بلاد': 'بيروت',
          'أكلة': 'بامية',
          'مهنة': 'بحار',
        },
        'explanation': 'البطاطس والبامية أشهر الأكلات، دور على فكرة نادرة تكسب 10 نقاط!',
      },
      {
        'prompt': 'حرف (م)',
        'answer': 'ولد: محمود | بنت: مريم | حيوان: ماعز | نبات: مانجو | جماد: مكتب | بلاد: مصر | أكلة: ملوخية | مهنة: مهندس',
        'acceptable_alternatives': {
          'ولد': 'محمود',
          'بنت': 'مريم',
          'حيوان': 'ماعز',
          'نبات': 'مانجو',
          'جماد': 'مكتب',
          'بلاد': 'مصر',
          'أكلة': 'ملوخية',
          'مهنة': 'مهندس',
        },
        'explanation': 'الملوخية والمحشي.. إجابات مصرية أصيلة لحرف الميم!',
      },
      {
        'prompt': 'حرف (س)',
        'answer': 'ولد: سامح | بنت: سلمى | حيوان: سمكة | نبات: سمسم | جماد: سرير | بلاد: سوريا | أكلة: سمبوسك | مهنة: سائق',
        'acceptable_alternatives': {
          'ولد': 'سامح',
          'بنت': 'سلمى',
          'حيوان': 'سمكة',
          'نبات': 'سمسم',
          'جماد': 'سرير',
          'بلاد': 'سوريا',
          'أكلة': 'سمبوسك',
          'مهنة': 'سائق',
        },
        'explanation': 'السوشي والسبانخ خيارات أكلة ممتازة لحرف السين.',
      },
      {
        'prompt': 'حرف (ك)',
        'answer': 'ولد: كريم | بنت: كارما | حيوان: كلب | نبات: كمثرى | جماد: كرسي | بلاد: كندا | أكلة: كشري | مهنة: كاتب',
        'acceptable_alternatives': {
          'ولد': 'كريم',
          'بنت': 'كارما',
          'حيوان': 'كلب',
          'نبات': 'كمثرى',
          'جماد': 'كرسي',
          'بلاد': 'كندا',
          'أكلة': 'كشري',
          'مهنة': 'كاتب',
        },
        'explanation': 'الكشري والكفتة والكنافة.. خيارات الأكلة في الكاف لا تنتهي!',
      },
    ];
  }
}
