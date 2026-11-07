import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class OnlineGameplayScreen extends StatefulWidget {
  final String roomCode;
  final String? playerToken;
  final bool isHost;

  const OnlineGameplayScreen({
    super.key,
    required this.roomCode,
    this.playerToken,
    this.isHost = false,
  });

  @override
  State<OnlineGameplayScreen> createState() => _OnlineGameplayScreenState();
}

class _OnlineGameplayScreenState extends State<OnlineGameplayScreen> with SingleTickerProviderStateMixin {
  late String _code;
  late String? _playerToken;
  late bool _isHost;

  Timer? _countdownTimer;
  Timer? _syncTimer;

  bool _isLoading = true;
  int _currentRound = 1;
  int _totalRounds = 10;
  int _roundDuration = 20;
  int _remainingSeconds = 20;

  Map<String, dynamic>? _card;
  List<String> _choices = [];
  String? _mySelectedAnswer;
  bool _hasSubmitted = false;
  bool _isSubmitting = false;

  bool _roundEnded = false;
  String? _revealedAnswer;
  String? _explanation;
  int _pointsEarned = 0;
  bool? _isCorrect;

  List<Map<String, dynamic>> _leaderboard = [];
  int _answeredCount = 0;
  int _totalPlayers = 0;

  bool _isGameOver = false;
  bool _isNextRoundLoading = false;

  // ألوان وأشكال كاهوت الشهيرة بتنسيق فرفشة الفاخر
  final List<Color> _choiceColors = const [
    Color(0xFFE21B3C), // أحمر (مثلث)
    Color(0xFF1368CE), // أزرق (معين)
    Color(0xFFD89E00), // ذهبي / أصفر (دائرة)
    Color(0xFF26890C), // أخضر (مربع)
  ];

  final List<IconData> _choiceIcons = const [
    Icons.change_history_rounded, // مثلث
    Icons.diamond_outlined,       // معين
    Icons.circle_outlined,         // دائرة
    Icons.crop_square_rounded,     // مربع
  ];

  @override
  void initState() {
    super.initState();
    _code = widget.roomCode;
    _playerToken = widget.playerToken;
    _isHost = widget.isHost;

    _fetchState();

    // مؤقت مزامنة حالة الغرفة الذكية كل ثانية ونصف
    _syncTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _fetchState();
    });

    // عداد الوقت التنازلي التفاعلي
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0 && !_roundEnded && !_isGameOver) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds == 0 && _isHost) {
          _triggerTimeout();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchState() async {
    if (!mounted) return;

    try {
      final res = await ApiService.instance.getRoomState(_code, token: _playerToken);
      if (!mounted) return;

      final room = res['room'] as Map<String, dynamic>? ?? {};
      final serverRound = (room['current_round'] as int?) ?? 1;
      final serverTotalRounds = (room['total_rounds'] as int?) ?? 10;
      final serverDuration = (room['round_duration_seconds'] as int?) ?? 20;
      final serverRoundEnded = room['round_ended'] == true;
      final isOver = res['is_game_over'] == true;

      final cardData = res['card'] as Map<String, dynamic>?;
      final choicesRaw = cardData?['choices'] as List<dynamic>? ?? [];
      final newChoices = choicesRaw.map((e) => e.toString()).toList();

      final leaderboardRaw = res['leaderboard'] as List<dynamic>? ?? [];
      final newLeaderboard = leaderboardRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final myAns = res['my_answer'] as Map<String, dynamic>?;

      setState(() {
        _isLoading = false;
        _totalRounds = serverTotalRounds;
        _roundDuration = serverDuration;
        _totalPlayers = (room['total_players'] as int?) ?? 1;
        _answeredCount = (room['answered_count'] as int?) ?? 0;
        _isGameOver = isOver;

        // في حال تم الانتقال لجولة جديدة على السيرفر
        if (serverRound != _currentRound) {
          _currentRound = serverRound;
          _card = cardData;
          _choices = newChoices;
          _remainingSeconds = serverDuration;
          _mySelectedAnswer = null;
          _hasSubmitted = false;
          _roundEnded = false;
          _revealedAnswer = null;
          _explanation = null;
          _isCorrect = null;
          _pointsEarned = 0;
        } else {
          _card = cardData;
          if (_choices.isEmpty && newChoices.isNotEmpty) {
            _choices = newChoices;
          }
        }

        // تحديث إجابتي إذا كانت مسجلة مسبقاً
        if (myAns != null && !_hasSubmitted) {
          _hasSubmitted = true;
          _mySelectedAnswer = myAns['answer']?.toString();
          _isCorrect = myAns['is_correct'] as bool?;
          _pointsEarned = (myAns['points'] as int?) ?? 0;
        }

        // في حال انتهت الجولة
        if (serverRoundEnded && !_roundEnded) {
          _roundEnded = true;
          _revealedAnswer = res['revealed_answer']?.toString();
          _explanation = res['explanation']?.toString();
          if (myAns != null) {
            _isCorrect = myAns['is_correct'] as bool?;
            _pointsEarned = (myAns['points'] as int?) ?? 0;
          }
        }

        _leaderboard = newLeaderboard;
      });
    } catch (_) {}
  }

  Future<void> _submitAnswer(String answer) async {
    if (_hasSubmitted || _roundEnded || _isSubmitting || _playerToken == null) return;

    setState(() {
      _mySelectedAnswer = answer;
      _hasSubmitted = true;
      _isSubmitting = true;
    });

    HapticFeedback.heavyImpact();

    try {
      final timeTaken = (_roundDuration - _remainingSeconds).toDouble();
      final res = await ApiService.instance.submitRoomAnswer(
        code: _code,
        playerToken: _playerToken!,
        answer: answer,
        timeTakenSeconds: timeTaken,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isCorrect = res['is_correct'] as bool?;
          _pointsEarned = (res['points_earned'] as int?) ?? 0;
          if (res['round_ended'] == true) {
            _roundEnded = true;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _triggerTimeout() async {
    try {
      await ApiService.instance.timeoutRoom(_code);
    } catch (_) {}
  }

  Future<void> _handleNextRound() async {
    if (_isNextRoundLoading) return;
    setState(() => _isNextRoundLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await ApiService.instance.nextRoomRound(_code);
      if (mounted) {
        setState(() => _isNextRoundLoading = false);
        _fetchState();
      }
    } catch (e) {
      if (mounted) setState(() => _isNextRoundLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.6),
              radius: 1.0,
              colors: [Color(0xFF4A2290), Color(0xFF241050), Color(0xFF150A2E)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: LammaColors.gold500),
          ),
        ),
      );
    }

    if (_isGameOver) {
      return _buildPodiumView();
    }

    if (_roundEnded) {
      return _buildRoundLeaderboardView();
    }

    return _buildQuestionView();
  }

  /// 1. شاشة السؤال والخيارات المتزامنة
  Widget _buildQuestionView() {
    final progress = _remainingSeconds / (_roundDuration > 0 ? _roundDuration : 20);
    final isUrgent = _remainingSeconds <= 5;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.0,
            colors: [Color(0xFF4A2290), Color(0xFF241050), Color(0xFF150A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Column(
              children: [
                // الشريط العلوي (الجولة + العداد التنازلي)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1850),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'الجولة $_currentRound من $_totalRounds',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: LammaColors.gold500,
                        ),
                      ),
                    ),
                    // المؤقت الدائري المتوهج
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUrgent ? Colors.redAccent.withValues(alpha: 0.25) : const Color(0xFF2A1850),
                        border: Border.all(
                          color: isUrgent ? Colors.redAccent : LammaColors.gold500,
                          width: 2.5,
                        ),
                        boxShadow: isUrgent
                            ? [
                                const BoxShadow(
                                  color: Colors.redAccent,
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$_remainingSeconds',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isUrgent ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1850),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'أجاب: $_answeredCount/$_totalPlayers',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFCFC6E4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // شريط الوقت التنازلي الأفقي
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUrgent ? Colors.redAccent : LammaColors.gold500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // بطاقة السؤال الرئيسية
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 140),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241050),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.5), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA35BFF).withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _card?['prompt']?.toString() ?? 'جاري تجهيز السؤال...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // بطاقة التأكيد بعد الإجابة
                if (_hasSubmitted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF25D366), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'تم تسجيل إجابتك بنجاح! في انتظار باقي اللاعبين...',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                // شبكة الخيارات الأربعة (كاهوت ستايل ملونة وتفاعلية)
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(_choices.length, (index) {
                      final choice = _choices[index];
                      final isSelected = _mySelectedAnswer == choice;
                      final color = _choiceColors[index % _choiceColors.length];
                      final icon = _choiceIcons[index % _choiceIcons.length];

                      return GestureDetector(
                        onTap: () => _submitAnswer(choice),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withValues(alpha: _hasSubmitted ? 0.45 : 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 3.5 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: Colors.white, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                choice,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 2. شاشة كشف النتيجة ولوحة الصدارة بعد كل سؤال (Kahoot-style Leaderboard)
  Widget _buildRoundLeaderboardView() {
    final correct = _isCorrect == true;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.0,
            colors: [Color(0xFF4A2290), Color(0xFF241050), Color(0xFF150A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Column(
              children: [
                // بنر هل إجابتك صحيحة أم خاطئة؟
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: correct ? const Color(0xFF26890C) : const Color(0xFFE21B3C),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (correct ? const Color(0xFF26890C) : const Color(0xFFE21B3C)).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              correct ? 'إجابة صحيحة! 🎉' : 'إجابة خاطئة! ❌',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              correct
                                  ? 'أحسنت! حصلت على +$_pointsEarned نقطة سرعة'
                                  : 'الإجابة الصحيحة كانت: ${_revealedAnswer ?? ""}',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                            if (_explanation != null && _explanation!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _explanation!,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // عنوان لوحة الصدارة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'لوحة الصدارة الحية 🏆',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'نهاية الجولة $_currentRound',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LammaColors.gold500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // قائمة الصدارة المباشرة مع أنيميشن الترتيب
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _leaderboard.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = _leaderboard[index];
                      final rank = p['rank'] ?? (index + 1);
                      final isFirst = rank == 1;
                      final earned = p['last_points_earned'] as int? ?? 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xFF4A2090)
                              : const Color(0xFF26144D).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isFirst ? LammaColors.gold500 : const Color(0xFFA35BFF).withValues(alpha: 0.3),
                            width: isFirst ? 2 : 1,
                          ),
                          boxShadow: isFirst
                              ? [
                                  BoxShadow(
                                    color: LammaColors.gold500.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // الميدالية أو رقم الترتيب
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFirst ? LammaColors.gold500 : Colors.white12,
                              ),
                              child: Center(
                                child: Text(
                                  '$rank',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isFirst ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // اسم اللاعب
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['player_name']?.toString() ?? 'لاعب',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (earned > 0)
                                    Text(
                                      '+$earned نقطة في هذه الجولة ⚡',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6FD9B5),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // إجمالي النقاط
                            Text(
                              '${p['score']} نقطة',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: LammaColors.gold500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // زر السؤال التالي للمضيف أو رسالة الانتظار
                if (_isHost)
                  GameButton(
                    text: _isNextRoundLoading ? 'جاري الانتقال...' : 'السؤال التالي ➡️',
                    showArrow: false,
                    height: 58,
                    onPressed: _isNextRoundLoading ? () {} : _handleNextRound,
                  )
                else
                  Container(
                    height: 56,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B0E38),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: LammaColors.gold500.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: LammaColors.gold500),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'في انتظار المضيف للانتقال للسؤال القادم... ⏳',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: LammaColors.gold500,
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

  /// 3. شاشة التتويج النهائية (Final Podium)
  Widget _buildPodiumView() {
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.0,
            colors: [Color(0xFF4A2290), Color(0xFF241050), Color(0xFF150A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'انتهت اللعبة! 🎉',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'منصة تتويج الأبطال في فرفشة 👑',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LammaColors.gold500,
                  ),
                ),
                const SizedBox(height: 24),

                // منصة التتويج الثلاثية (Podium)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // المركز الثاني (فضة)
                      if (second != null)
                        _buildPodiumStep(
                          player: second,
                          rank: 2,
                          height: 150,
                          color: const Color(0xFFC0C0C0),
                          trophy: '🥈',
                        ),
                      const SizedBox(width: 8),

                      // المركز الأول (ذهب)
                      if (first != null)
                        _buildPodiumStep(
                          player: first,
                          rank: 1,
                          height: 200,
                          color: LammaColors.gold500,
                          trophy: '👑',
                        ),
                      const SizedBox(width: 8),

                      // المركز الثالث (برونز)
                      if (third != null)
                        _buildPodiumStep(
                          player: third,
                          rank: 3,
                          height: 120,
                          color: const Color(0xFFCD7F32),
                          trophy: '🥉',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // زر العودة للرئيسية
                GameButton(
                  text: 'العودة للرئيسية 🏠',
                  showArrow: false,
                  height: 58,
                  onPressed: () {
                    context.go('/home');
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumStep({
    required Map<String, dynamic> player,
    required int rank,
    required double height,
    required Color color,
    required String trophy,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trophy, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            player['player_name']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            '${player['score']} نقطة',
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: LammaColors.gold500),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
