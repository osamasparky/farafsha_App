import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/widgets/guest_locked_modal.dart';
import '../../../core/widgets/lamma_scaffold.dart';
import '../../../core/widgets/player_avatar_widget.dart';
import '../widgets/banner_curtain_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: الألعاب, 1: التحديات, 2: المفضلة
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

  Future<void> _fetchData({bool forceRefresh = false}) async {
    if (!forceRefresh && _games.isEmpty) {
      setState(() => _isLoading = true);
    }
    final results = await Future.wait([
      ApiService.instance.getGames(forceRefresh: true),
      ApiService.instance.getBanners(forceRefresh: forceRefresh),
    ]);

    if (mounted) {
      final games = results[0];
      final banners = results[1];
      final localAllowed = games.where((g) {
        final gm = g['game_mode']?.toString() ?? 'all';
        return g['is_active'] != false &&
            ['all', 'local_only', 'hybrid', 'local_and_lammah'].contains(gm);
      }).toList();

      setState(() {
        _games = games.isNotEmpty ? localAllowed : _fallbackGames();
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
        'image': 'assets/images/crowd.webp',
        'external_url': 'https://lammah.app/tournament',
      },
      {
        'id': 2,
        'title': 'كروت جديدة وإفيهات حصرية 🔥',
        'image': 'assets/images/local.webp',
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
        'icon': 'assets/images/ic-quote.webp',
      },
      {
        'id': 2,
        'slug': 'famous-quotes',
        'name': 'جمل مشهورة',
        'subtitle': 'من الأفلام والمسلسلات',
        'category': 'إفيهات',
        'icon': 'assets/images/ic-film.webp',
      },
      {
        'id': 3,
        'slug': 'forbidden-words',
        'name': 'خمن الكلمة',
        'subtitle': 'ممنوع تقول',
        'category': 'ذكاء وسرعة',
        'icon': 'assets/images/ic-a.webp',
      },
      {
        'id': 4,
        'slug': 'speed-trivia',
        'name': 'معلومات عامة',
        'subtitle': 'سؤال على السريع',
        'category': 'معلومات عامة',
        'icon': 'assets/images/ic-bulb.webp',
      },
      {
        'id': 5,
        'slug': 'guess-song',
        'name': 'خمن الأغنية',
        'subtitle': 'من التلميحات',
        'category': 'فن',
        'icon': 'assets/images/ic-music.webp',
      },
      {
        'id': 6,
        'slug': 'who-am-i',
        'name': 'مين أنا؟',
        'subtitle': 'شخصيات وأشياء بأسئلة نعم/لا',
        'category': 'تخمين',
        'icon': 'assets/images/ic-mask.webp',
      },
      {
        'id': 7,
        'slug': 'autobus-complete',
        'name': 'أتوبيس كومبليت',
        'subtitle': 'ولد، بنت، جماد، نبات، بلاد، حيوان',
        'category': 'ذكاء وسرعة',
        'icon': 'assets/images/ic-dice.webp',
        'is_featured': true,
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
      case 'autobus-complete':
        return const [Color(0xFFBF360C), Color(0xFFE65100)];
      default:
        return const [Color(0xFF8C3468), Color(0xFF531B44)];
    }
  }

  String _getGameCover(String slug) {
    switch (slug) {
      case 'amthal-shaabiya':
        return 'assets/images/proverb.webp';
      case 'famous-quotes':
        return 'assets/images/popcorn.webp';
      case 'forbidden-words':
      case 'taboo-words':
        return 'assets/images/walk_2.webp';
      case 'speed-trivia':
        return 'assets/images/walk_4.webp';
      case 'who-am-i':
        return 'assets/images/walk_3.webp';
      case 'autobus-complete':
        return 'assets/images/walk_1.webp';
      case 'acting-drawing':
      case 'draw-guess':
        return 'assets/images/walk_5.webp';
      default:
        return 'assets/images/crowd.webp';
    }
  }

  void _onBannerTap(Map<String, dynamic> banner) {
    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();

    // عرض الستارة التفاعلية الناعمة للبنر (صور وفيديو وروابط وزر إغلاق)
    BannerCurtainModal.show(context, banner);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final isGuest = auth.isGuest;
        final avatarPath = auth.userAvatar;
        final greetingName = isGuest ? 'زائر فرفشة 🎭' : auth.userName;

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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        SoundService.instance.playClick();
                        context.push('/profile');
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isGuest ? const Color(0xFFA35BFF) : LammaColors.gold500,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isGuest ? const Color(0xFFA35BFF) : LammaColors.gold500).withValues(alpha: 0.45),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: PlayerAvatarWidget(
                              avatarPath: avatarPath,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGuest ? 'تصفح كزائر' : 'مساء الخير',
                                style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFCFC6E4), fontWeight: FontWeight.w600),
                              ),
                              Text(
                                isGuest ? greetingName : 'أهلاً يا $greetingName',
                                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            SoundService.instance.playClick();
                            if (isGuest) {
                              GuestLockedModal.show(
                                context,
                                customTitle: 'ميزة الأصدقاء والشلل',
                                customMessage: 'سجّل حسابك مجاناً لإضافة صحابك بـ @username واللعب مع شلتك!',
                              );
                            } else {
                              context.push('/friends');
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: LammaColors.cardBorder),
                            ),
                            child: const Icon(Icons.group_rounded, color: LammaColors.gold500, size: 22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
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
                      onRefresh: () => _fetchData(forceRefresh: true),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  },
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
                behavior: HitTestBehavior.opaque,
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
                                  cacheWidth: 800,
                                  errorBuilder: (_, __, ___) => Image.asset('assets/images/crowd.webp', fit: BoxFit.cover, cacheWidth: 800),
                                )
                              : Image.asset(
                                  banner['image'] ?? 'assets/images/crowd.webp',
                                  fit: BoxFit.cover,
                                  cacheWidth: 800,
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
        behavior: HitTestBehavior.opaque,
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
    final fallbackCover = _getGameCover(slug);
    final coverImageUrl = game['cover_image_url']?.toString();
    final isUnlocked = AuthService.instance.isGameUnlocked(slug);
    final badgeText = game['badge_text']?.toString();

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SettingsService.instance.triggerHaptic();
          SoundService.instance.playClick();
          if (!isUnlocked) {
            _showGuestLockedModal(context, game['name'] ?? 'اللعبة');
          } else {
            if (game['slug'] == 'domino') {
              context.push('/domino-setup');
            } else {
              context.push('/game-setup', extra: game);
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUnlocked
                  ? Colors.white.withValues(alpha: 0.22)
                  : const Color(0xFFFFD27A).withValues(alpha: 0.45),
              width: isUnlocked ? 1.4 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: isUnlocked ? 0.4 : 0.2),
                offset: const Offset(0, 8),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. الصورة كخلفية كاملة للكارت (Full Background Image مع تقييد حجم الذاكرة cacheWidth)
                Positioned.fill(
                  child: coverImageUrl != null && coverImageUrl.isNotEmpty
                      ? Image.network(
                          coverImageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 360,
                          errorBuilder: (_, __, ___) => Image.asset(fallbackCover, fit: BoxFit.cover, cacheWidth: 360),
                        )
                      : Image.asset(fallbackCover, fit: BoxFit.cover, cacheWidth: 360),
                ),

              // 2. تدرج لوني خفيف لحماية التباين اللوني
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: isUnlocked ? 0.45 : 0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. طبقة داكنة تحت النصوص لإظهار الكلام بوضوح تام (Text Layer)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        game['name'] ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isUnlocked)
                        Text(
                          game['subtitle'] ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFD27A),
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFFFD27A)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'سجل دخول عشان تفرفش',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFD27A),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // 4. شارة مميزة في الزاوية العلوية (إن وُجدت)
              if (badgeText != null && badgeText.isNotEmpty)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9E40), Color(0xFFFF5400)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.cairo(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // 5. أيقونة القفل للحسابات غير المسجلة (Guest)
              if (!isUnlocked)
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD27A), width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.lock_rounded, size: 13, color: Color(0xFFFFD27A)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showGuestLockedModal(BuildContext context, String gameTitle) {
    GuestLockedModal.show(context, gameTitle: gameTitle);
  }
}
