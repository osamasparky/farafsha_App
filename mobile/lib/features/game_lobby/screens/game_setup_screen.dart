import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class GameSetupScreen extends StatefulWidget {
  final String gameId;
  const GameSetupScreen({super.key, required this.gameId});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _playersCount = 4;
  int _roundsCount = 10;
  String _difficulty = 'متوسط';

  Map<String, dynamic> get _gameMeta {
    switch (widget.gameId) {
      case 'famous-quotes':
        return {
          'title': 'جمل مشهورة',
          'image': 'assets/images/popcorn.png',
          'rules': 'خمّن إفيهات وحوارات الأفلام والمسلسلات الشهيرة قبل انتهاء الوقت!',
          'route': '/game/quotes',
        };
      case 'forbidden-words':
        return {
          'title': 'ممنوع تقول',
          'image': 'assets/images/ic-a.png',
          'rules': 'اشرح الكلمة لفريقك من غير ما تنطق أي كلمة من الكلمات الـ 5 الممنوعة!',
          'route': '/game/taboo',
        };
      case 'draw-guess':
        return {
          'title': 'ارسم وخمّن',
          'image': 'assets/images/ic-photo.png',
          'rules': 'ارسم الكلمة السرية باللمس على الشاشة ولازم فريقك يخمّنها قبل ما الوقت يخلص!',
          'route': '/game/draw',
        };
      case 'amthal-shaabiya':
      default:
        return {
          'title': 'أمثال شعبية',
          'image': 'assets/images/proverb.png',
          'rules': 'يظهر صدر المثل الشعبي وعليك اختيار التكملة الصحيحة من بين الخيارات.',
          'route': '/game/amthal',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _gameMeta;

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
                  meta['title'] as String,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
                  onPressed: () => _showRulesSheet(context, meta),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // صورة غلاف اللعبة
            Center(
              child: Image.asset(
                meta['image'] as String,
                width: 320,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.sports_esports_rounded, size: 100, color: Colors.white),
              ),
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
                    onTap: () {
                      setState(() {
                        _playersCount = (_playersCount % 8) + 2;
                      });
                    },
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                  _buildSettingRow(
                    icon: Icons.layers_rounded,
                    title: 'عدد الجولات',
                    value: '$_roundsCount جولات',
                    onTap: () {
                      setState(() {
                        _roundsCount = _roundsCount == 10 ? 15 : (_roundsCount == 15 ? 5 : 10);
                      });
                    },
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
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
                context.push('/players', extra: meta['route']);
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

  void _showRulesSheet(BuildContext context, Map<String, dynamic> meta) {
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
                'قواعد لعبة ${meta['title']}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              meta['rules'] as String,
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
