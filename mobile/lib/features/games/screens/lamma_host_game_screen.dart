import 'package:flutter/material.dart';
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
    this.totalQuestions = 10,
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
            {'name': 'فريق البنفسج', 'score': 0, 'color': const Color(0xFFA35BFF)},
            {'name': 'فريق البرتقان', 'score': 0, 'color': const Color(0xFFFF8A4C)},
          ];
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final cards = await ApiService.instance.getGameCards(widget.gameSlug);
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
    if (_currentIndex + 1 >= _questions.length || _currentIndex + 1 >= widget.totalQuestions) {
      SoundService.instance.playWin();
      setState(() => _isGameOver = true);
    } else {
      SoundService.instance.playClick();
      setState(() {
        _currentIndex++;
        _lastScoredTeam = null;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _lastScoredTeam = null;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1458),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LammaColors.cardBorder, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_rounded, color: LammaColors.gold500, size: 18),
              const SizedBox(width: 6),
              Text(
                widget.subMode == 'all_in_one' ? 'اللمّة · كلنا واحد' : 'اللمّة · فرق وتحدي',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // عداد الأسئلة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_currentIndex + 1} / ${widget.totalQuestions}',
            style: GoogleFonts.cairo(
              fontSize: 14,
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
    final prompt = q['prompt'] ?? q['question'] ?? 'سؤال اللمّة';
    final answer = q['answer'] ?? '';
    final explanation = q['explanation'] ?? q['notes'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF190C36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LammaColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LammaColors.glow.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط تنبيه المذيع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: LammaColors.orange500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up_rounded, color: LammaColors.orange300, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'اقرأ السؤال بصوت عالي للقعدة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LammaColors.orange300,
                      ),
                    ),
                  ],
                ),
              ),

              // زر إظهار/إخفاء الإجابة
              IconButton(
                icon: Icon(
                  _isAnswerRevealed ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: const Color(0xFFD9C2FF),
                  size: 20,
                ),
                onPressed: () => setState(() => _isAnswerRevealed = !_isAnswerRevealed),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // نص السؤال في كارت عريض
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF26124D), Color(0xFF1E0C3F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              prompt,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // صندوق الإجابة الخاص بالمذيع
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isAnswerRevealed
                  ? const Color(0xFF133829).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isAnswerRevealed ? LammaColors.success : Colors.white24,
                width: 1.2,
              ),
            ),
            child: _isAnswerRevealed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: LammaColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'الإجابة الصحيحة:',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: LammaColors.successLight,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            answer,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (explanation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          explanation,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFFD6C8F5),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  )
                : Center(
                    child: Text(
                      'الإجابة مخفية (اضغط أيقونة العين بالأعلى للكشف)',
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.white60),
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
            Text(
              'مين جاوب صح في القعدة؟ (اضغط لاحتساب النقطة)',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: LammaColors.gold500,
              ),
            ),
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

            return InkWell(
              onTap: () => _scoreForTeam(i),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                constraints: BoxConstraints(
                  minWidth: (MediaQuery.of(context).size.width - 56) / 2,
                ),
                decoration: BoxDecoration(
                  color: justScored ? color : color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: justScored ? Colors.white : color,
                    width: justScored ? 2.0 : 1.2,
                  ),
                  boxShadow: justScored
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team['name'] as String,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${team['score']} نقطة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: LammaColors.gold300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
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
                          Text(
                            t['name'] as String,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
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

