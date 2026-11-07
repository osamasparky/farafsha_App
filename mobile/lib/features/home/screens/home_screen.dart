import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: الألعاب, 1: التحديات, 2: المفضلة
  int _currentNavIndex = 2; // 0: الرئيسية, 1: الأصدقاء, 2: الألعاب (الوسطى), 3: الترتيب, 4: الملف
  bool _isLoading = false;
  List<Map<String, dynamic>> _games = [];

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    setState(() => _isLoading = true);
    final games = await ApiService.instance.getGames();
    if (mounted) {
      setState(() {
        _games = games.isNotEmpty ? games : _fallbackGames();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _fallbackGames() {
    return [
      {
        'id': 1,
        'slug': 'amthal-shaabiya',
        'name': 'أمثال شعبية',
        'subtitle': 'كمّل المثل الشعبي',
        'category': 'أمثال',
        'icon': 'assets/images/ic-quote.png',
      },
      {
        'id': 2,
        'slug': 'famous-quotes',
        'name': 'جمل مشهورة',
        'subtitle': 'من الأفلام والمسلسلات',
        'category': 'إفيهات',
        'icon': 'assets/images/ic-film.png',
      },
      {
        'id': 3,
        'slug': 'forbidden-words',
        'name': 'خمن الكلمة',
        'subtitle': 'ممنوع تقول',
        'category': 'ذكاء وسرعة',
        'icon': 'assets/images/ic-a.png',
      },
      {
        'id': 4,
        'slug': 'speed-trivia',
        'name': 'معلومات عامة',
        'subtitle': 'سؤال على السريع',
        'category': 'معلومات عامة',
        'icon': 'assets/images/ic-bulb.png',
      },
      {
        'id': 5,
        'slug': 'guess-song',
        'name': 'خمن الأغنية',
        'subtitle': 'من التلميحات',
        'category': 'فن',
        'icon': 'assets/images/ic-music.png',
      },
      {
        'id': 6,
        'slug': 'draw-guess',
        'name': 'خمن الصورة',
        'subtitle': 'ارسم وخمّن',
        'category': 'رسم',
        'icon': 'assets/images/ic-photo.png',
      },
      {
        'id': 7,
        'slug': 'who-am-i',
        'name': 'مين أنا؟',
        'subtitle': 'شخصيات وأشياء',
        'category': 'تخمين',
        'icon': 'assets/images/ic-mask.png',
      },
      {
        'id': 8,
        'slug': 'random-challenge',
        'name': 'تحديات عشوائية',
        'subtitle': 'مفاجآت كل جولة',
        'category': 'تحدي',
        'icon': 'assets/images/ic-dice.png',
      },
    ];
  }

  List<Color> _getGameColors(String slug) {
    switch (slug) {
      case 'amthal-shaabiya':
        return const [Color(0xFFD2566A), Color(0xFF8E2A4E)];
      case 'famous-quotes':
        return const [Color(0xFF8F3BD0), Color(0xFF561C94)];
      case 'forbidden-words':
        return const [Color(0xFF4846BE), Color(0xFF2B2580)];
      case 'speed-trivia':
        return const [Color(0xFF2F6E7A), Color(0xFF1B3F52)];
      case 'guess-song':
        return const [Color(0xFFB23A72), Color(0xFF6E1C4E)];
      case 'draw-guess':
        return const [Color(0xFF4740B0), Color(0xFF28226E)];
      case 'who-am-i':
        return const [Color(0xFF7A6A3A), Color(0xFF3F3420)];
      default:
        return const [Color(0xFF8C3468), Color(0xFF531B44)];
    }
  }

  String _getGameIcon(String slug) {
    switch (slug) {
      case 'amthal-shaabiya': return 'assets/images/ic-quote.png';
      case 'famous-quotes': return 'assets/images/ic-film.png';
      case 'forbidden-words': return 'assets/images/ic-a.png';
      case 'speed-trivia': return 'assets/images/ic-bulb.png';
      case 'guess-song': return 'assets/images/ic-music.png';
      case 'draw-guess': return 'assets/images/ic-photo.png';
      case 'who-am-i': return 'assets/images/ic-mask.png';
      default: return 'assets/images/ic-dice.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      showBokeh: false,
      body: Column(
        children: [
          // 1. الهيدر (Header) الترحيب + الصورة + جرس الإشعارات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LammaColors.gold500, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: LammaColors.gold500.withValues(alpha: 0.45),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundImage: AssetImage('assets/images/av-ahmed.png'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مساء الخير',
                          style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFFCFC6E4), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'أهلاً يا أسامة',
                          style: GoogleFonts.cairo(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/notifs'),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LammaColors.cardBorder),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: LammaColors.pink500,
                              border: Border.all(color: const Color(0xFF2A1656), width: 2),
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

          // 2. شريط التبويبات الثلاثي المستدير (الألعاب / التحديات / المفضلة)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: LammaColors.cardBorder),
              ),
              child: Row(
                children: [
                  _buildTab('الألعاب', 0),
                  _buildTab('التحديات', 1),
                  _buildTab('المفضلة', 2),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. شبكة الألعاب من الباك إند
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: LammaColors.violet500),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchGames,
                    color: LammaColors.violet500,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        final g = _games[index];
                        return _buildGameTile(g);
                      },
                    ),
                  ),
          ),
        ],
      ),

      // 4. شريط التنقل السفلي مع زر الألعاب المرفوع المجسم (Raised Center Game Button)
      bottomNavigationBar: Container(
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFF130928).withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: Color(0x33A35BFF), width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'الرئيسية', Icons.home_rounded, onTap: () {}),
            _buildNavItem(1, 'طريقة اللعب', Icons.gamepad_rounded, onTap: () => context.push('/mode-select')),
            // الزر الأوسط المرفوع للألعاب
            Transform.translate(
              offset: const Offset(0, -18),
              child: GestureDetector(
                onTap: _fetchGames,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA35BFF), Color(0xFF7A2FE0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: LammaColors.violet500.withValues(alpha: 0.7),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.sports_esports_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'الألعاب',
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            _buildNavItem(3, 'الترتيب', Icons.leaderboard_rounded, onTap: () => context.push('/leaderboard')),
            _buildNavItem(4, 'الملف', Icons.person_rounded, onTap: () => context.push('/profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFA35BFF), Color(0xFF7A2FE0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: LammaColors.violet500.withValues(alpha: 0.6),
                      blurRadius: 18,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFFCFC6E4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameTile(Map<String, dynamic> game) {
    final slug = (game['slug'] ?? game['id'] ?? 'amthal-shaabiya').toString();
    final name = (game['name'] ?? 'لعبة لمّة').toString();
    final subtitle = (game['subtitle'] ?? game['sub'] ?? '').toString();
    final List<Color> colors = _getGameColors(slug);
    final iconAsset = _getGameIcon(slug);
    final coverUrl = game['cover_image_url'] as String?;

    return GestureDetector(
      onTap: () => context.push('/game-setup/$slug', extra: game),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (coverUrl != null && coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  coverUrl,
                  width: 58,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(iconAsset, width: 58, height: 48, fit: BoxFit.contain),
                ),
              )
            else
              Image.asset(
                iconAsset,
                width: 58,
                height: 48,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, {required VoidCallback onTap}) {
    final bool isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? Colors.white : const Color(0xFFCFC6E4),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFFCFC6E4),
            ),
          ),
        ],
      ),
    );
  }
}
