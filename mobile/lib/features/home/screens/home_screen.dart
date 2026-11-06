import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: الألعاب, 1: التحديات, 2: المفضلة
  int _currentNavIndex = 2; // 0: الرئيسية, 1: الأصدقاء, 2: الألعاب (الوسطى), 3: الترتيب, 4: الكل

  final List<Map<String, dynamic>> _games = const [
    {
      'id': 'amthal-shaabiya',
      'name': 'أمثال شعبية',
      'sub': 'كمّل المثل الشعبي',
      'icon': 'assets/images/ic-quote.png',
      'colors': [Color(0xFFD2566A), Color(0xFF8E2A4E)],
    },
    {
      'id': 'famous-quotes',
      'name': 'جمل مشهورة',
      'sub': 'من الأفلام والمسلسلات',
      'icon': 'assets/images/ic-film.png',
      'colors': [Color(0xFF8F3BD0), Color(0xFF561C94)],
    },
    {
      'id': 'forbidden-words',
      'name': 'خمن الكلمة',
      'sub': 'ممنوع تقول',
      'icon': 'assets/images/ic-a.png',
      'colors': [Color(0xFF4846BE), Color(0xFF2B2580)],
    },
    {
      'id': 'speed-trivia',
      'name': 'معلومات عامة',
      'sub': 'سؤال على السريع',
      'icon': 'assets/images/ic-bulb.png',
      'colors': [Color(0xFF2F6E7A), Color(0xFF1B3F52)],
    },
    {
      'id': 'guess-song',
      'name': 'خمن الأغنية',
      'sub': 'من التلميحات',
      'icon': 'assets/images/ic-music.png',
      'colors': [Color(0xFFB23A72), Color(0xFF6E1C4E)],
    },
    {
      'id': 'draw-guess',
      'name': 'خمن الصورة',
      'sub': 'ارسم وخمّن',
      'icon': 'assets/images/ic-photo.png',
      'colors': [Color(0xFF4740B0), Color(0xFF28226E)],
    },
    {
      'id': 'who-am-i',
      'name': 'مين أنا؟',
      'sub': 'شخصيات وأشياء',
      'icon': 'assets/images/ic-mask.png',
      'colors': [Color(0xFF7A6A3A), Color(0xFF3F3420)],
    },
    {
      'id': 'random-challenge',
      'name': 'تحديات عشوائية',
      'sub': 'مفاجآت كل جولة',
      'icon': 'assets/images/ic-dice.png',
      'colors': [Color(0xFF8C3468), Color(0xFF531B44)],
    },
  ];

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
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
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
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مساء الخير',
                          style: TextStyle(fontSize: 13, color: Color(0xFFCFC6E4), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'أهلاً يا أسامة 👋',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/notifications'),
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

          // 3. شبكة الألعاب الـ 8 (2×4 Grid)
          Expanded(
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
        ],
      ),

      // 4. شريط التنقل السفلي مع زر الألعاب المرفوع المجسم (Raised Center Game Button)
      bottomNavigationBar: Container(
        height: 84,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F1042), Color(0xFF130828)],
          ),
          border: Border(top: BorderSide(color: LammaColors.cardBorder, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'الرئيسية', Icons.home_filled, onTap: () {}),
            _buildNavItem(1, 'أونلاين', Icons.wifi_tethering_rounded, onTap: () => context.push('/mode-select')),
            // الزر الأوسط المرفوع (الألعاب)
            GestureDetector(
              onTap: () => setState(() => _currentNavIndex = 2),
              child: Container(
                margin: const EdgeInsets.only(top: 0),
                transform: Matrix4.translationValues(0, -18, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB98AFF), Color(0xFF6A24C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: const Border(
                          top: BorderSide(color: Colors.white54, width: 1.5),
                          bottom: BorderSide(color: Color(0xFF4A1690), width: 4.5),
                          left: BorderSide(color: Colors.white24, width: 1),
                          right: BorderSide(color: Colors.white24, width: 1),
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
                    const Text(
                      'الألعاب',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            _buildNavItem(3, 'الترتيب', Icons.leaderboard_rounded, onTap: () => context.push('/leaderboard')),
            _buildNavItem(4, 'الحزم', Icons.storefront_rounded, onTap: () => context.push('/store')),
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
              style: TextStyle(
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
    final List<Color> colors = game['colors'] as List<Color>;

    return GestureDetector(
      onTap: () => context.push('/game-setup/${game['id']}'),
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
            Image.asset(
              game['icon'] as String,
              width: 58,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              game['name'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
            Text(
              game['sub'] as String,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
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
            style: TextStyle(
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
