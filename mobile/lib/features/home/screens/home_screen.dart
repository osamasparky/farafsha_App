import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: الألعاب, 1: التحديات, 2: المفضلة
  int _currentNavIndex = 2; // 0: الرئيسية, 1: الأصدقاء, 2: الألعاب, 3: الترتيب, 4: الملف
  bool _isLoading = false;
  List<Map<String, dynamic>> _games = [];
  List<Map<String, dynamic>> _banners = [];
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.instance.getGames(),
      ApiService.instance.getBanners(),
    ]);

    if (mounted) {
      final games = results[0];
      final banners = results[1];
      setState(() {
        _games = games.isNotEmpty ? games : _fallbackGames();
        _banners = banners.isNotEmpty ? banners : _fallbackBanners();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _fallbackBanners() {
    return [
      {
        'id': 1,
        'title': 'بطولة لمّة الأسبوعية الكبرى 🏆',
        'image': 'assets/images/crowd.png',
        'external_url': 'https://lammah.app/tournament',
      },
      {
        'id': 2,
        'title': 'كروت جديدة وإفيهات حصرية 🔥',
        'image': 'assets/images/local.png',
        'external_url': null,
      },
    ];
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
        'slug': 'who-am-i',
        'name': 'مين أنا؟',
        'subtitle': 'شخصيات وأشياء بأسئلة نعم/لا',
        'category': 'تخمين',
        'icon': 'assets/images/ic-mask.png',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredGames {
    if (_selectedTabIndex == 1) {
      return _games.where((g) => g['is_featured'] == true || g['id'] % 2 == 1).toList();
    } else if (_selectedTabIndex == 2) {
      return _games.take(3).toList();
    }
    return _games;
  }

  List<Color> _getGameGradient(String slug) {
    switch (slug) {
      case 'amthal-shaabiya':
        return const [Color(0xFF8C3468), Color(0xFF531B44)];
      case 'famous-quotes':
        return const [Color(0xFF5C299A), Color(0xFF331560)];
      case 'forbidden-words':
      case 'taboo-words':
        return const [Color(0xFF2C3E8A), Color(0xFF192458)];
      case 'speed-trivia':
        return const [Color(0xFF1E6C68), Color(0xFF104240)];
      case 'two-truths-and-lie':
        return const [Color(0xFF6B2B70), Color(0xFF3E1542)];
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

  void _onBannerTap(Map<String, dynamic> banner) async {
    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();

    final urlStr = banner['external_url']?.toString();
    if (urlStr != null && urlStr.isNotEmpty) {
      try {
        final uri = Uri.parse(urlStr);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Error launching banner url: $e');
      }
    }

    if (!mounted) return;

    // إذا كان بدون رابط خارجي، نظهر إشعاراً تشجيعياً
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          banner['title'] ?? 'فعالية خاصة بتطبيق لمّـة! 🎮',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF4A1E9A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      showBokeh: false,
      body: Column(
        children: [
          // 1. الشريط العلوي (الهيدر)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                        radius: 20,
                        backgroundImage: AssetImage('assets/images/av-ahmed.png'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مساء الخير',
                          style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFCFC6E4), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'أهلاً يا أسامة',
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    SoundService.instance.playClick();
                    context.push('/notifications');
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LammaColors.cardBorder),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFFFF568A), shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. البنر الإعلاني الترويجي (Banner Carousel)
          if (_banners.isNotEmpty) ...[
            _buildBannerSection(),
            const SizedBox(height: 10),
          ],

          // 3. التبويبات (الألعاب - التحديات - المفضلة)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: LammaColors.cardBorder),
              ),
              child: Row(
                children: [
                  _buildTabItem(title: 'الألعاب', index: 0),
                  _buildTabItem(title: 'التحديات', index: 1),
                  _buildTabItem(title: 'المفضلة', index: 2),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 4. شبكة الألعاب (Grid of Games)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: LammaColors.violet500))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: RefreshIndicator(
                      onRefresh: _fetchData,
                      color: LammaColors.violet500,
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 90),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.94,
                        ),
                        itemCount: _filteredGames.length,
                        itemBuilder: (context, index) {
                          final game = _filteredGames[index];
                          return _buildGameCard(game);
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
            itemCount: _banners.length,
            itemBuilder: (context, idx) {
              final banner = _banners[idx];
              final imgUrl = banner['image_url']?.toString() ?? '';
              final title = banner['title']?.toString() ?? '';
              final hasUrl = banner['external_url'] != null && banner['external_url'].toString().isNotEmpty;

              return GestureDetector(
                onTap: () => _onBannerTap(banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A2A9E), Color(0xFF2E115B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A2A9E).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // صورة البنر
                        Positioned.fill(
                          child: imgUrl.startsWith('http')
                              ? Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset('assets/images/crowd.png', fit: BoxFit.cover),
                                )
                              : Image.asset(
                                  banner['image'] ?? 'assets/images/crowd.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                        // طبقة تظليل لضمان وضوح النص
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.black.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                        // نص البنر مع شارة الرابط إن وجد
                        Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (hasUrl)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: LammaColors.orange500,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'تفاصيل',
                                        style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.open_in_new_rounded, size: 11, color: Colors.white),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentBannerIndex == i ? 16 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == i ? LammaColors.gold500 : Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          SettingsService.instance.triggerHaptic();
          SoundService.instance.playClick();
          setState(() => _selectedTabIndex = index);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected ? LammaGradients.ctaSecondary : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: LammaColors.violet500.withValues(alpha: 0.6),
                      blurRadius: 14,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFFCFC6E4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final slug = game['slug']?.toString() ?? 'amthal-shaabiya';
    final colors = _getGameGradient(slug);
    final fallbackIcon = _getGameIcon(slug);
    final coverImageUrl = game['cover_image_url']?.toString();

    return GestureDetector(
      onTap: () {
        SettingsService.instance.triggerHaptic();
        SoundService.instance.playClick();
        context.push('/game-setup', extra: game);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.45),
              offset: const Offset(0, 10),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: coverImageUrl != null && coverImageUrl.isNotEmpty
                      ? Image.network(
                          coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(fallbackIcon, fit: BoxFit.contain),
                        )
                      : Image.asset(fallbackIcon, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                game['name'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                game['subtitle'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE2D9F3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF130924),
        border: Border(top: BorderSide(color: Color(0xFF2E1C55), width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_filled, label: 'الرئيسية', index: 0, route: '/home'),
              _buildNavItem(icon: Icons.sports_esports_rounded, label: 'طريقة اللعب', index: 1, route: '/mode-selection'),
              _buildCenterGameIcon(),
              _buildNavItem(icon: Icons.leaderboard_rounded, label: 'الترتيب', index: 3, route: '/leaderboard'),
              _buildNavItem(icon: Icons.person_rounded, label: 'الملف', index: 4, route: '/profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required String route}) {
    final bool isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        SettingsService.instance.triggerHaptic();
        SoundService.instance.playClick();
        setState(() => _currentNavIndex = index);
        if (route != '/home') {
          context.push(route);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFB98AFF) : const Color(0xFF8B7AA8),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF8B7AA8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterGameIcon() {
    return GestureDetector(
      onTap: () {
        SettingsService.instance.triggerHaptic();
        SoundService.instance.playClick();
        context.push('/mode-selection');
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFB98AFF), Color(0xFF7524E4)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA35BFF).withValues(alpha: 0.65),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
