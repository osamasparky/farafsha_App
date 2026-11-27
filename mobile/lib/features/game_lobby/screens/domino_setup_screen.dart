import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

/// شاشة إعداد لعبة الدومينو (مطابقة لتصميم 01-DominoSetup)
class DominoSetupScreen extends StatefulWidget {
  const DominoSetupScreen({super.key});

  @override
  State<DominoSetupScreen> createState() => _DominoSetupScreenState();
}

class _DominoSetupScreenState extends State<DominoSetupScreen> {
  int _playersCount = 2; // 2, 3, 4
  String _playMode = 'draw'; // draw (سحب), block (بلوك)
  bool _teamMode = true; // في حالة 4 لاعبين: فرق 2 ضد 2 أو فردي
  int _targetScore = 101; // 101, 151, 201
  bool _isCreating = false;
  late final TextEditingController _hostNameController;

  @override
  void initState() {
    super.initState();
    final authName = AuthService.instance.userName.trim();
    final apiName = ApiService.instance.currentUser?['name']?.toString().trim() ?? '';
    final resolved = (authName.isNotEmpty && authName != 'زائر فرفشة')
        ? authName
        : (apiName.isNotEmpty ? apiName : '');
    _hostNameController = TextEditingController(text: resolved);
  }

  @override
  void dispose() {
    _hostNameController.dispose();
    super.dispose();
  }

  String get _dealSummary {
    final boneyard = _playMode == 'block'
        ? 0
        : (_playersCount == 2 ? 14 : (_playersCount == 3 ? 7 : 0));
    final modeText = _playMode == 'draw' && boneyard > 0
        ? 'المخزن $boneyard قطعة، واللي مش معاه يسحب.'
        : 'مفيش سحب، واللي مش معاه يدق.';
    final teamText = _playersCount == 4
        ? (_teamMode ? ' (فرق 2 ضد 2) ' : ' (فردي) ')
        : ' ';
    return 'كل لاعب 7 قطع$teamText· $modeText أول ما حد يخلّص قطعه ياخد مجموع نقط اللي معاهم.';
  }

  Future<void> _startOnlineRoom() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    HapticFeedback.heavyImpact();

    try {
      final typedName = _hostNameController.text.trim();
      final authName = AuthService.instance.userName.trim();
      final apiName = ApiService.instance.currentUser?['name']?.toString().trim() ?? '';
      final hostName = typedName.isNotEmpty
          ? typedName
          : (authName.isNotEmpty && authName != 'زائر فرفشة')
              ? authName
              : apiName;

      final res = await ApiService.instance.createRoom(
        gameSlug: 'domino',
        hostName: hostName.isNotEmpty ? hostName : null,
        maxPlayers: _playersCount,
        roundDurationSeconds: 25,
        teamMode: _playersCount == 4 && _teamMode,
        targetScore: _targetScore,
        playMode: _playMode,
      );

      final code = res['room']?['code']?.toString() ?? '';
      final token = res['token']?.toString();

      if (code.isEmpty) {
        throw Exception('تعذر استلام رمز الغرفة من السيرفر');
      }

      if (mounted) {
        context.pushReplacement('/online-room', extra: {
          'code': code,
          'token': token,
          'isHost': true,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _matchmakeRandom() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    HapticFeedback.heavyImpact();

    try {
      final typedName = _hostNameController.text.trim();
      final res = await ApiService.instance.matchmakeRoom(
        gameSlug: 'domino',
        playerName: typedName.isNotEmpty ? typedName : null,
        maxPlayers: _playersCount,
        teamMode: _playersCount == 4 && _teamMode,
        targetScore: _targetScore,
        playMode: _playMode,
      );

      final code = res['room']?['code']?.toString() ?? '';
      final token = res['token']?.toString();
      final isHost = res['player']?['is_host'] == true || res['player']?['is_host'] == 1;

      if (mounted && code.isNotEmpty) {
        context.pushReplacement('/online-room', extra: {
          'code': code,
          'token': token,
          'isHost': isHost,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _startLocalVsBots() {
    HapticFeedback.heavyImpact();
    context.push('/local-domino', extra: {
      'playersCount': _playersCount,
      'playMode': _playMode,
      'teamMode': _playersCount == 4 && _teamMode,
      'targetScore': _targetScore,
      'playerName': _hostNameController.text.trim().isNotEmpty ? _hostNameController.text.trim() : 'أنت',
    });
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F0F42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFA35BFF), width: 1.5),
        ),
        title: Text(
          'قوانين الدومينو في فرفشة',
          style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '• مجموعة من 28 قطعة (0|0 إلى 6|6)، لكل لاعب 7 قطع.\n'
          '• الدبل يتحط بالعرض على الطاولة.\n'
          '• السحب: لو معندكش قطعة تركب تسحب من المخزن.\n'
          '• بلوك: مفيش سحب، اللي مش معاه يدق.\n'
          '• أول ما لاعب يخلّص قطعه أو الطاولة تقفل، الفائز ياخد مجموع نقط الخصوم حتى $_targetScore نقطة!',
          style: GoogleFonts.cairo(color: Colors.white70, height: 1.7, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('فهمت 👍', style: GoogleFonts.cairo(color: LammaColors.gold500, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.5),
            radius: 1.1,
            colors: [Color(0xFF4E2590), Color(0xFF2A1458), Color(0xFF170B30)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // الشريط العلوي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 30),
                      onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 24),
                      onPressed: _showRulesDialog,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // أيقونة الثلاث بلاطات ثلاثية الأبعاد + العنوان
                      Center(
                        child: SizedBox(
                          height: 112,
                          width: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.translate(
                                offset: const Offset(-46, 6),
                                child: Transform.rotate(
                                  angle: -10 * math.pi / 180,
                                  child: const _MiniHeroTile(a: 5, b: 2),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(46, 8),
                                child: Transform.rotate(
                                  angle: 10 * math.pi / 180,
                                  child: const _MiniHeroTile(a: 1, b: 4),
                                ),
                              ),
                              const _MiniHeroTile(a: 6, b: 6, isGold: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'دومينو',
                          style: GoogleFonts.cairo(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 1. عدد اللاعبين
                      Text(
                        'عدد اللاعبين',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFCFC6E4)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildOptionCard(
                            selected: _playersCount == 2,
                            title: '2',
                            subtitle: 'وش لوش',
                            onTap: () => setState(() => _playersCount = 2),
                          ),
                          const SizedBox(width: 8),
                          _buildOptionCard(
                            selected: _playersCount == 3,
                            title: '3',
                            subtitle: 'كل واحد لنفسه',
                            onTap: () => setState(() => _playersCount = 3),
                          ),
                          const SizedBox(width: 8),
                          _buildOptionCard(
                            selected: _playersCount == 4,
                            title: '4',
                            subtitle: 'فرق أو فردي',
                            onTap: () => setState(() => _playersCount = 4),
                          ),
                        ],
                      ),

                      if (_playersCount == 4) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildOptionCard(
                              selected: _teamMode,
                              title: 'فرق (2 ضد 2)',
                              subtitle: 'إحنا × هم',
                              onTap: () => setState(() => _teamMode = true),
                            ),
                            const SizedBox(width: 8),
                            _buildOptionCard(
                              selected: !_teamMode,
                              title: 'فردي',
                              subtitle: 'كل واحد لنفسه',
                              onTap: () => setState(() => _teamMode = false),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 2. طريقة اللعب
                      Text(
                        'طريقة اللعب',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFCFC6E4)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildOptionCard(
                            selected: _playMode == 'draw',
                            title: 'سحب',
                            subtitle: 'اللي مش معاه يسحب من المخزن',
                            onTap: () => setState(() => _playMode = 'draw'),
                          ),
                          const SizedBox(width: 8),
                          _buildOptionCard(
                            selected: _playMode == 'block',
                            title: 'بلوك',
                            subtitle: 'مفيش سحب، اللي مش معاه يدق',
                            onTap: () => setState(() => _playMode = 'block'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 3. الجيم بيخلص عند
                      Text(
                        'الجيم بيخلص عند',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFCFC6E4)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [101, 151, 201].map((score) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: score == 201 ? 0 : 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _targetScore = score),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: _targetScore == score
                                        ? const LinearGradient(colors: [Color(0xFFB98AFF), Color(0xFF7A2FE0)])
                                        : null,
                                    color: _targetScore == score ? null : const Color(0xFF221142),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _targetScore == score ? Colors.white60 : const Color(0x44A35BFF),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$score',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // اسم المضيف (تلقائي من الحساب مع إمكانية التعديل)
                      Text(
                        'اسمك في الغرفة (المضيف 👑)',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFCFC6E4)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _hostNameController,
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: 'اكتب اسمك...',
                          hintStyle: GoogleFonts.cairo(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.28),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0x44A35BFF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0x44A35BFF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: LammaColors.gold500, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ملخص القواعد المباشر
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          _dealSummary,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEADFFF),
                            height: 1.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      GameButton(
                        text: _isCreating ? 'جاري فتح الغرفة...' : 'لعب أونلاين (إنشاء غرفة) ◀',
                        showArrow: false,
                        height: 54,
                        onPressed: _isCreating ? () {} : _startOnlineRoom,
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF35B88E), width: 1.5),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _startLocalVsBots,
                              icon: const Icon(Icons.smart_toy_rounded, color: Color(0xFF6FD9B5), size: 18),
                              label: Text(
                                'لعب محلي (ضد البوت)',
                                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFA35BFF), width: 1.5),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isCreating ? null : _matchmakeRandom,
                              icon: const Icon(Icons.public_rounded, color: LammaColors.gold500, size: 18),
                              label: Text(
                                'لاعب عشوائي 🌐',
                                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context.push('/join-room'),
                        child: Text(
                          'عندك كود غرفة؟ انضم لأصحابك 🚀',
                          style: GoogleFonts.cairo(
                            color: LammaColors.gold300,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB98AFF), Color(0xFF7A2FE0)],
                  )
                : null,
            color: selected ? null : const Color(0xFF221142),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.white70 : const Color(0x44A35BFF),
              width: 1.5,
            ),
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFFA35BFF).withValues(alpha: 0.45), blurRadius: 12)]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFFCFC6E4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniHeroTile extends StatelessWidget {
  final int a;
  final int b;
  final bool isGold;

  const _MiniHeroTile({required this.a, required this.b, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGold ? LammaColors.gold500 : const Color(0xFFD6C7AE),
          width: isGold ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isGold ? LammaColors.gold500.withValues(alpha: 0.4) : Colors.black38,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                '$a',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isGold ? const Color(0xFFD97706) : const Color(0xFF1F1638),
                ),
              ),
            ),
          ),
          Container(height: 1.5, width: 34, color: const Color(0xFF9E8E76)),
          Expanded(
            child: Center(
              child: Text(
                '$b',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isGold ? const Color(0xFFD97706) : const Color(0xFF1F1638),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
