import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0: هذا الأسبوع, 1: هذا الشهر, 2: كل الوقت
  final List<String> _tabs = ['هذا الأسبوع', 'هذا الشهر', 'كل الوقت'];
  final List<String> _periodKeys = ['weekly', 'monthly', 'all_time'];

  bool _isLoading = false;
  List<Map<String, dynamic>> _podium = [];
  List<Map<String, dynamic>> _rankings = [];
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard('weekly');
  }

  Future<void> _fetchLeaderboard(String period) async {
    setState(() => _isLoading = true);
    final data = await ApiService.instance.getLeaderboardData(period: period);

    if (mounted) {
      if (data != null) {
        setState(() {
          _podium = List<Map<String, dynamic>>.from(data['podium'] ?? []);
          _rankings = List<Map<String, dynamic>>.from(data['rankings'] ?? []);
          _currentUser = data['current_user'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        _loadFallbackData(period);
      }
    }
  }

  void _loadFallbackData(String period) {
    if (period == 'monthly') {
      setState(() {
        _podium = [
          {'player_name': 'سارة', 'avatar': 'assets/images/av-sara.webp', 'score': 8450, 'rank': 1, 'badge': 'سيدة الشهر 👑'},
          {'player_name': 'محمود', 'avatar': 'assets/images/av-mahmoud.webp', 'score': 7910, 'rank': 2, 'badge': 'الوصيف 🥈'},
          {'player_name': 'أحمد', 'avatar': 'assets/images/av-ahmed.webp', 'score': 7200, 'rank': 3, 'badge': 'المتحدي 🥉'},
        ];
        _rankings = [
          {'player_name': 'كريم', 'avatar': 'assets/images/av-karim.webp', 'score': 5830, 'rank': 4},
          {'player_name': 'منة', 'avatar': 'assets/images/av-mena.webp', 'score': 4920, 'rank': 5},
          {'player_name': 'أنت (أسامة)', 'avatar': 'assets/images/av-karim.webp', 'score': 3420, 'rank': 8, 'is_current_user': true},
        ];
        _currentUser = {'player_name': 'أنت (أسامة)', 'score': 3420, 'rank': 8};
        _isLoading = false;
      });
    } else if (period == 'all_time') {
      setState(() {
        _podium = [
          {'player_name': 'محمود', 'avatar': 'assets/images/av-mahmoud.webp', 'score': 24190, 'rank': 1, 'badge': 'الأسطورة 🌟'},
          {'player_name': 'أحمد', 'avatar': 'assets/images/av-ahmed.webp', 'score': 21500, 'rank': 2, 'badge': 'المحارب ⚔️'},
          {'player_name': 'سارة', 'avatar': 'assets/images/av-sara.webp', 'score': 19840, 'rank': 3, 'badge': 'العبقرية 💡'},
        ];
        _rankings = [
          {'player_name': 'ياسين', 'avatar': 'assets/images/av-ahmed.webp', 'score': 16300, 'rank': 4},
          {'player_name': 'منة', 'avatar': 'assets/images/av-mena.webp', 'score': 14750, 'rank': 5},
          {'player_name': 'كريم', 'avatar': 'assets/images/av-karim.webp', 'score': 12900, 'rank': 6},
          {'player_name': 'أنت (أسامة)', 'avatar': 'assets/images/av-karim.webp', 'score': 8650, 'rank': 15, 'is_current_user': true},
        ];
        _currentUser = {'player_name': 'أنت (أسامة)', 'score': 8650, 'rank': 15};
        _isLoading = false;
      });
    } else {
      setState(() {
        _podium = [
          {'player_name': 'أحمد', 'avatar': 'assets/images/av-ahmed.webp', 'score': 2840, 'rank': 1, 'badge': 'بطل الأسبوع 👑'},
          {'player_name': 'سارة', 'avatar': 'assets/images/av-sara.webp', 'score': 2120, 'rank': 2, 'badge': 'محترفة 🥈'},
          {'player_name': 'محمود', 'avatar': 'assets/images/av-mahmoud.webp', 'score': 1980, 'rank': 3, 'badge': 'سريع البديهة 🥉'},
        ];
        _rankings = [
          {'player_name': 'منة', 'avatar': 'assets/images/av-mena.webp', 'score': 1760, 'rank': 4},
          {'player_name': 'كريم', 'avatar': 'assets/images/av-karim.webp', 'score': 1520, 'rank': 5},
          {'player_name': 'أنت (أسامة)', 'avatar': 'assets/images/av-karim.webp', 'score': 980, 'rank': 12, 'is_current_user': true},
        ];
        _currentUser = {'player_name': 'أنت (أسامة)', 'score': 980, 'rank': 12};
        _isLoading = false;
      });
    }
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    SettingsService.instance.triggerHaptic();
    SoundService.instance.playClick();
    setState(() => _selectedTab = index);
    _fetchLeaderboard(_periodKeys[index]);
  }

  @override
  Widget build(BuildContext context) {
    // تحديد اللاعبين في المنصة (1st, 2nd, 3rd)
    final firstPlace = _podium.isNotEmpty ? _podium[0] : null;
    final secondPlace = _podium.length > 1 ? _podium[1] : null;
    final thirdPlace = _podium.length > 2 ? _podium[2] : null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.4),
            radius: 1.0,
            colors: [
              Color(0xFF4A2490),
              Color(0xFF21143F),
              Color(0xFF1B0F38),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Column(
              children: [
                // 1. الشريط العلوي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 22),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    Text(
                      'لوحة الترتيب 🏆',
                      style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. شريط التبويب الزمني (هذا الأسبوع | هذا الشهر | كل الوقت)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _selectedTab == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onTabSelected(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(colors: [Color(0xFF8138E8), Color(0xFFA35BFF)])
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF8138E8).withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                _tabs[index],
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: isSelected ? Colors.white : const Color(0xFFCFC6E4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. المحتوى
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: LammaColors.gold500))
                      : Column(
                          children: [
                            // منصة التتويج الثلاثية
                            _buildPodium(firstPlace, secondPlace, thirdPlace),

                            const SizedBox(height: 12),

                            // باقي قائمة الترتيب
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _rankings.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = _rankings[index];
                                  return _buildRankRow(item);
                                },
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildPodium(Map<String, dynamic>? first, Map<String, dynamic>? second, Map<String, dynamic>? third) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // المركز الثاني (فضة)
        Expanded(
          child: _buildPodiumColumn(
            player: second,
            height: 110,
            rankNumber: 2,
            rankColor: const Color(0xFFC9D2E0),
            gradientColors: [const Color(0xFFC9D2E0).withValues(alpha: 0.35), const Color(0xFF4A2A80)],
          ),
        ),

        // المركز الأول (ذهب)
        Expanded(
          child: _buildPodiumColumn(
            player: first,
            height: 135,
            rankNumber: 1,
            rankColor: const Color(0xFFFFD700),
            gradientColors: [const Color(0xFFFFD700).withValues(alpha: 0.45), const Color(0xFF7524E4)],
            hasCrown: true,
          ),
        ),

        // المركز الثالث (برونز)
        Expanded(
          child: _buildPodiumColumn(
            player: third,
            height: 95,
            rankNumber: 3,
            rankColor: const Color(0xFFCD7F32),
            gradientColors: [const Color(0xFFCD7F32).withValues(alpha: 0.35), const Color(0xFF331560)],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required Map<String, dynamic>? player,
    required double height,
    required int rankNumber,
    required Color rankColor,
    required List<Color> gradientColors,
    bool hasCrown = false,
  }) {
    if (player == null) return const SizedBox.shrink();

    final name = player['player_name']?.toString() ?? '';
    final score = player['score']?.toString() ?? '0';
    final avatar = player['avatar']?.toString() ?? 'assets/images/av-ahmed.webp';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCrown)
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 28)
        else
          const SizedBox(height: 4),

        Container(
          width: hasCrown ? 64 : 54,
          height: hasCrown ? 64 : 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: rankColor, width: hasCrown ? 3.5 : 2.5),
            boxShadow: [
              BoxShadow(
                color: rankColor.withValues(alpha: 0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(top: BorderSide(color: rankColor, width: 2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '$rankNumber',
                    style: const TextStyle(color: Color(0xFF1B0F38), fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
              ),
              Text(
                '$score نقطة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: LammaColors.gold300, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(Map<String, dynamic> item) {
    final bool isUser = item['is_current_user'] == true || item['rank'] == _currentUser?['rank'];
    final rank = item['rank']?.toString() ?? '-';
    final name = item['player_name']?.toString() ?? '';
    final score = item['score']?.toString() ?? '0';
    final avatar = item['avatar']?.toString() ?? 'assets/images/av-ahmed.webp';
    final badge = item['badge']?.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF4A1E9A).withValues(alpha: 0.8) : const Color(0xFF241050).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser ? LammaColors.gold500 : Colors.white10,
          width: isUser ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              rank,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isUser ? LammaColors.gold500 : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: LammaColors.gold500,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'أنت',
                          style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                    ],
                  ],
                ),
                if (badge != null && badge.isNotEmpty)
                  Text(
                    badge,
                    style: GoogleFonts.cairo(fontSize: 11, color: LammaColors.gold300, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Text(
            '$score نقطة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isUser ? LammaColors.gold500 : const Color(0xFFFF9E6A),
            ),
          ),
        ],
      ),
    );
  }
}
