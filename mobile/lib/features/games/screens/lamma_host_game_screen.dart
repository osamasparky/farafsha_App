import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

/// شاشة طريقة اللمّة (المذيع / Host Mode)
/// حيث يحمل شخص واحد الهاتف ويقرأ الأسئلة للقعدة
/// 1. نمط "كلنا واحد": بدون فرق وبدون نقاط، قراءة وتسلية جماعية
/// 2. نمط "فرق وتحدي": يضيف الفرق ويضغط على الفرقة التي تجاوب صح لحساب النقاط
class LammaHostGameScreen extends StatefulWidget {
  final String gameSlug;
  final String subMode; // 'all_in_one' or 'teams'
  final List<Map<String, dynamic>> initialTeams;
  final int totalQuestions;

  const LammaHostGameScreen({
    super.key,
    required this.gameSlug,
    this.subMode = 'teams',
    this.initialTeams = const [],
    this.totalQuestions = 50,
  });

  @override
  State<LammaHostGameScreen> createState() => _LammaHostGameScreenState();
}

class _LammaHostGameScreenState extends State<LammaHostGameScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  bool _isAnswerRevealed = true; // للمذيع لرؤية الإجابة
  bool _isGameOver = false;

  late List<Map<String, dynamic>> _teams;
  String? _lastScoredTeam;

  @override
  void initState() {
    super.initState();
    _teams = widget.initialTeams.isNotEmpty
        ? widget.initialTeams.map((t) => Map<String, dynamic>.from(t)).toList()
        : [
            {'name': 'فرفوش', 'score': 0, 'color': const Color(0xFFA35BFF)},
            {'name': 'قفوش', 'score': 0, 'color': const Color(0xFFFF8A4C)},
          ];
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final cards = await ApiService.instance.getGameCards(widget.gameSlug, limit: widget.totalQuestions);
    if (mounted) {
      setState(() {
        _questions = cards.isNotEmpty ? cards : _fallbackQuestions();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _fallbackQuestions() {
    return [
      {
        'prompt': 'اللي اختشوا ...',
        'answer': 'ماتوا',
        'explanation': 'يُضرب لمن فقد الحياء وأصبح لا يبالي بعواقب أفعاله.',
      },
      {
        'prompt': 'القرد في عين أمه ...',
        'answer': 'غزال',
        'explanation': 'يُضرب في حب الأم الفطري الذي يجعلها ترى ابنها الأجمل.',
      },
      {
        'prompt': 'على قد لحافك ...',
        'answer': 'مد رجليك',
        'explanation': 'يُضرب في تدبير المعيشة والإنفاق بحسب الإمكانيات.',
      },
      {
        'prompt': 'باب النجار ...',
        'answer': 'مخلّع',
        'explanation': 'يُضرب لمن ينفع الناس ويهمل شؤونه الخاصة.',
      },
      {
        'prompt': 'اطبخ يا جارية كلف يا ...',
        'answer': 'سيدي',
        'explanation': 'يُضرب في أن العمل المتقن يتطلب توفير المتطلبات.',
      },
    ];
  }

  void _scoreForTeam(int teamIndex) {
    SettingsService.instance.triggerHaptic(isHeavy: true);
    SoundService.instance.playCorrect();
    setState(() {
      _teams[teamIndex]['score'] = (_teams[teamIndex]['score'] as int) + 1;
      _lastScoredTeam = _teams[teamIndex]['name'] as String;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars_rounded, color: LammaColors.gold500),
            const SizedBox(width: 8),
            Text(
              '+1 نقطة لـ ${_teams[teamIndex]['name']} 🎉',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2B1458),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextQuestion() {
    SettingsService.instance.triggerHaptic();
    final total = _questions.isNotEmpty
        ? (_questions.length < widget.totalQuestions ? _questions.length : widget.totalQuestions)
        : widget.totalQuestions;
    if (_currentIndex + 1 >= total) {
      SoundService.instance.playWin();
      setState(() => _isGameOver = true);
    } else {
      SoundService.instance.playClick();
      setState(() {
        _currentIndex++;
        _lastScoredTeam = null;
        _isAnswerRevealed = false;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _lastScoredTeam = null;
        _isAnswerRevealed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGameOver) {
      return _buildResultsView();
    }

    return LammaScaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: LammaColors.violet500),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // الشريط العلوي (المذيع، التراجع، رقم السؤال)
                    _buildHeader(),

                    const SizedBox(height: 12),

                    // بطاقة المذيع الكبرى التي تحوي السؤال والإجابة
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHostCard(),
                            const SizedBox(height: 14),
                            if (widget.subMode == 'teams') ...[
                              _buildTeamsScoringSection(),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // أزرار التحكم السفلية (السؤال التالي، السابق، تخطي)
                    _buildBottomControls(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          onPressed: () => _confirmExit(),
        ),

        // بادج نمط اللمّة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1458),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LammaColors.cardBorder, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.record_voice_over_rounded, color: LammaColors.gold500, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.subMode == 'all_in_one' ? 'اللمّة · كلنا واحد' : 'اللمّة · فرق وتحدي',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // زر كتم أو تشغيل المؤثرات الصوتية
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final sound = SoundService.instance;
            sound.setEnabled(!sound.isEnabled);
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SoundService.instance.isEnabled
                  ? const Color(0xFF25D366).withValues(alpha: 0.18)
                  : Colors.redAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: SoundService.instance.isEnabled ? const Color(0xFF25D366) : Colors.redAccent,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  SoundService.instance.isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: SoundService.instance.isEnabled ? const Color(0xFF25D366) : Colors.redAccent,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  SoundService.instance.isEnabled ? 'الصوت' : 'مكتوم',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: SoundService.instance.isEnabled ? const Color(0xFF25D366) : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),

        // عداد الأسئلة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_currentIndex + 1} / ${_questions.isNotEmpty ? (_questions.length < widget.totalQuestions ? _questions.length : widget.totalQuestions) : widget.totalQuestions}',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: LammaColors.gold500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHostCard() {
    final q = _questions[_currentIndex];
    final prompt = (q['prompt'] ?? q['question'] ?? 'سؤال اللمّة').toString();
    final answer = (q['answer'] ?? '').toString();
    final explanation = (q['explanation'] ?? q['notes'] ?? '').toString();

    final double promptFontSize = prompt.length > 70
        ? 18.0
        : (prompt.length > 35 ? 20.0 : 23.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF281154), Color(0xFF190838)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط تنبيه المذيع الفاخر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: Color(0xFFFFD166), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'اقرأ السؤال بصوت عالي للقعدة 📢',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFE59E),
                      ),
                    ),
                  ],
                ),
              ),

              // زر إظهار/إخفاء الإجابة
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isAnswerRevealed ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: const Color(0xFFFFD166),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isAnswerRevealed = !_isAnswerRevealed),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // نص السؤال في كارت عريض مع احتواء تلقائي كامل
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              prompt,
              textAlign: TextAlign.center,
              softWrap: true,
              style: GoogleFonts.cairo(
                fontSize: promptFontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // صندوق الإجابة الخاص بالمذيع مع احتواء هندسي كامل يمنع أي overflow
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isAnswerRevealed
                  ? const Color(0xFF064E3B).withOpacity(0.85)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isAnswerRevealed ? const Color(0xFF10B981) : Colors.white24,
                width: 1.5,
              ),
              boxShadow: _isAnswerRevealed
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: _isAnswerRevealed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // شارة توضيحية للإجابة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  'الإجابة المعتمدة للتحكيم',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFA7F3D0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'للمذيع فقط 👁️',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6EE7B7),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // نص الإجابة في كارت مستقل يلتف بسلاسة مهما بلغ طوله
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          answer,
                          textAlign: TextAlign.start,
                          softWrap: true,
                          style: GoogleFonts.cairo(
                            fontSize: answer.length > 60 ? 15.0 : (answer.length > 30 ? 17.0 : 20.0),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.45,
                          ),
                        ),
                      ),

                      // شرح أو كواليس الإجابة إذا توفرت
                      if (explanation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B0C38).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.info_outline_rounded, color: Color(0xFFFFD27A), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  explanation,
                                  softWrap: true,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE4DCF9),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'الإجابة مخفية (اضغط أيقونة العين بالأعلى للكشف)',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white60),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsScoringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'مين جاوب صح في القعدة؟ (اضغط لاحتساب النقطة)',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: LammaColors.gold500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_teams.length} فرق',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // شبكة أزرار الفرق التفاعلية
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_teams.length, (i) {
            final team = _teams[i];
            final Color color = team['color'] is Color
                ? team['color'] as Color
                : Color(team['color'] as int);
            final bool justScored = _lastScoredTeam == team['name'];

            final Color bevelColor = color == const Color(0xFFA35BFF)
                ? const Color(0xFF6B21A8)
                : const Color(0xFFC2410C);

            return GestureDetector(
              onTap: () => _scoreForTeam(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                  minWidth: (MediaQuery.of(context).size.width - 56) / 2,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: justScored
                        ? [color, color.withOpacity(0.8)]
                        : [color.withOpacity(0.35), color.withOpacity(0.18)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: justScored ? Colors.white : color.withOpacity(0.8),
                    width: justScored ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bevelColor,
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: color.withOpacity(justScored ? 0.6 : 0.25),
                      blurRadius: justScored ? 18 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      team['name'] == 'فرفوش' ? '🟣' : '🟠',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team['name'] as String,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '${team['score']} نقطة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFD166),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(justScored ? 0.35 : 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+1',
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
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Row(
      children: [
        if (_currentIndex > 0) ...[
          IconButton(
            onPressed: _previousQuestion,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: GameButton(
            text: (_currentIndex + 1 >= _questions.length || _currentIndex + 1 >= widget.totalQuestions)
                ? 'إنهاء اللمّة والنتائج'
                : 'السؤال التالي',
            onPressed: _nextQuestion,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    // ترتيب الفرق حسب النقاط
    final sortedTeams = List<Map<String, dynamic>>.from(_teams)
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final winner = sortedTeams.isNotEmpty ? sortedTeams.first : null;

    return LammaScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.emoji_events_rounded, color: Color(0xFF2A1050), size: 54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خلصت الجولة! 🎉',
                    style: GoogleFonts.cairo(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.subMode == 'all_in_one'
                        ? 'عاش يا لمتنا! لعبتوا واستمتعتوا مع بعض'
                        : '🎉 ${winner?['name']} كسب بالمركز الأول!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: LammaColors.gold300,
                    ),
                  ),
                ],
              ),

              // عرض الفرق ونتائجها
              if (widget.subMode == 'teams') ...[
                Column(
                  children: List.generate(sortedTeams.length, (idx) {
                    final t = sortedTeams[idx];
                    final Color color = t['color'] is Color
                        ? t['color'] as Color
                        : Color(t['color'] as int);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? color.withValues(alpha: 0.35)
                            : const Color(0xFF1E0C3F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: idx == 0 ? color : LammaColors.cardBorder,
                          width: idx == 0 ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '#${idx + 1}',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: LammaColors.gold500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t['name'] as String,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${t['score']} نقطة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: LammaColors.gold300,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],

              // أزرار النهاية
              Column(
                children: [
                  GameButton(
                    text: 'العب تاني من الأول',
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _isGameOver = false;
                        for (var t in _teams) {
                          t['score'] = 0;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'العودة للرئيسية',
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF200F44),
        title: Text(
          'الخروج من اللمّة؟',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'هل تريد إنهاء الجولة الحالية والعودة؟',
          style: GoogleFonts.cairo(color: const Color(0xFFD9C2FF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LammaColors.pink500),
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('خروج', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

