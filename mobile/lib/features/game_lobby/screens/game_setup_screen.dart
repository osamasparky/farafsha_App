import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class GameSetupScreen extends StatefulWidget {
  final String gameId;
  final Map<String, dynamic>? initialGameData;

  const GameSetupScreen({
    super.key,
    required this.gameId,
    this.initialGameData,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _playersCount = 4;
  int _roundsCount = 10;
  String _difficulty = 'متوسط';
  Map<String, dynamic>? _game;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGameData;
    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    if (_game == null || _game!['cover_image_url'] == null) {
      final data = await ApiService.instance.getGameBySlug(widget.gameId);
      if (mounted && data != null) {
        setState(() {
          _game = data;
        });
      }
    }
  }

  String _getDefaultAssetForSlug(String slug) {
    switch (slug) {
      case 'amthal-shaabiya':
        return 'assets/images/proverb.png';
      case 'famous-quotes':
        return 'assets/images/popcorn.png';
      case 'who-am-i':
        return 'assets/images/ic-mask.png';
      case 'forbidden-words':
        return 'assets/images/ic-a.png';
      case 'speed-trivia':
        return 'assets/images/ic-bulb.png';
      case 'two-truths-and-lie':
        return 'assets/images/ic-dice.png';
      default:
        return 'assets/images/proverb.png';
    }
  }

  Widget _buildCoverImage() {
    final coverUrl = _game?['cover_image_url'] as String?;
    final defaultAsset = _getDefaultAssetForSlug(widget.gameId);

    if (coverUrl != null && coverUrl.isNotEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            coverUrl,
            height: 250,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              defaultAsset,
              height: 250,
              fit: BoxFit.contain,
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(color: LammaColors.violet500),
                ),
              );
            },
          ),
        ),
      );
    }

    return Image.asset(
      defaultAsset,
      height: 250,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameTitle = _game?['name'] ?? 'إعداد اللعبة';

    return LammaScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الشريط العلوي (رجوع وأيقونة الشرح)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                  onPressed: () => context.pop(),
                ),
                Text(
                  gameTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
                  onPressed: () => _showRulesSheet(context),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // صورة كارت اللعبة القادمة من الباك إند
            Center(
              child: _buildCoverImage(),
            ),

            const SizedBox(height: 10),

            // كارت إعدادات اللعبة (عدد اللاعبين، الجولات، الصعوبة)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF150B2B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LammaColors.cardBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.group_rounded,
                    title: 'عدد اللاعبين',
                    value: '$_playersCount لاعبين',
                    onTap: () => _showPlayersCountPicker(context),
                  ),
                  const Divider(color: LammaColors.cardBorder, height: 1),
                  _buildSettingRow(
                    icon: Icons.layers_rounded,
                    title: 'عدد الجولات',
                    value: '$_roundsCount جولات',
                    onTap: () {
                      setState(() {
                        _roundsCount = _roundsCount >= 15 ? 5 : _roundsCount + 5;
                      });
                    },
                  ),
                  const Divider(color: LammaColors.cardBorder, height: 1),
                  _buildSettingRow(
                    icon: Icons.bar_chart_rounded,
                    title: 'مستوى الصعوبة',
                    value: _difficulty,
                    onTap: () {
                      setState(() {
                        _difficulty = _difficulty == 'متوسط' ? 'حريف' : (_difficulty == 'حريف' ? 'سهل' : 'متوسط');
                      });
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // زر ابدأ اللعبة (ينتقل لشاشة اختيار الفرق واللاعبين 14-Players)
            GameButton(
              text: 'ابدأ اللعبة',
              onPressed: () {
                context.push('/players', extra: {
                  'targetRoute': '/game/${widget.gameId == 'famous-quotes' ? 'quotes' : 'amthal'}',
                  'gameSlug': widget.gameId,
                  'gameTitle': _game?['name'] ?? (widget.gameId == 'famous-quotes' ? 'جمل مشهورة' : 'أمثال شعبية'),
                  'totalRounds': _roundsCount,
                  'playersCount': _playersCount,
                  'difficulty': _difficulty,
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD9C2FF), size: 22),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            const Spacer(),
            Text(value, style: const TextStyle(color: LammaColors.gold500, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCFC6E4), size: 14),
          ],
        ),
      ),
    );
  }

  void _showPlayersCountPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Color(0xFF1C0D38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFFB98AFF), width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر عدد اللاعبين (حتى 14 لاعب)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14].map((count) {
                final isSelected = _playersCount == count;
                return GestureDetector(
                  onTap: () {
                    setState(() => _playersCount = count);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected ? LammaColors.gold500 : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? LammaColors.gold300 : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? const Color(0xFF2A0E35) : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRulesSheet(BuildContext context) {
    final instructions = _game?['instructions'] ??
        '1. يظهر صدر المثل الشعبي وتختار التكملة الصحيحة.\n'
        '2. العداد التنازلي 20 ثانية لكل دور.\n'
        '3. 3 نقاط للإجابة الصحيحة المباشرة، ونقطتان بعد التلميح.\n'
        '4. الفائز هو الفريق صاحب أعلى رصيد نقاط في ختام الجولات.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: LammaColors.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: LammaColors.cardBorder, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'قواعد لعبة ${_game?['name'] ?? 'اللمّة'}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              instructions,
              style: const TextStyle(fontSize: 15, color: Color(0xFFEADFFF), height: 1.8),
            ),
            const SizedBox(height: 20),
            GameButton(
              text: 'فهمت القواعد',
              showArrow: false,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
