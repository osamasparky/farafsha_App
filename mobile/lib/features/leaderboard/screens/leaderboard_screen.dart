import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0: هذا الأسبوع, 1: هذا الشهر, 2: كل الوقت

  final List<String> _tabs = ['هذا الأسبوع', 'هذا الشهر', 'كل الوقت'];

  final List<Map<String, dynamic>> _rankings = [
    {
      'rank': 4,
      'name': 'منة',
      'score': '1,760',
      'avatar': 'assets/images/av-mena.png',
      'isUser': false,
    },
    {
      'rank': 5,
      'name': 'كريم',
      'score': '1,520',
      'avatar': 'assets/images/av-karim.png',
      'isUser': false,
    },
    {
      'rank': 12,
      'name': 'أنت',
      'score': '980',
      'avatar': 'assets/images/av-karim.png',
      'isUser': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // الشريط العلوي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'لوحة الترتيب',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 12),

                // شريط التبويب الزمني
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _selectedTab == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = index),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(colors: [Color(0xFF8138E8), Color(0xFFA35BFF)])
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Text(
                                _tabs[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

                const SizedBox(height: 16),

                // منصة التتويج الثلاثية (سارة #2 ، أحمد #1 ، محمود #3)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // المركز الثاني: سارة (فضة)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC9D2E0), width: 3),
                            ),
                            child: ClipOval(
                              child: Image.asset('assets/images/av-sara.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 110,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF5B6EC8), Color(0xFF34407E)],
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC9D2E0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('2', style: TextStyle(color: Color(0xFF21143F), fontWeight: FontWeight.w900)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text('سارة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                const Text('2,120', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // المركز الأول: أحمد (ذهب + تاج)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: LammaColors.gold500, size: 32),
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: LammaColors.gold500, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: LammaColors.gold500.withValues(alpha: 0.6),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset('assets/images/av-ahmed.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFE0A92E), Color(0xFF9C6A10)],
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF1C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('1', style: TextStyle(color: Color(0xFF21143F), fontWeight: FontWeight.w900)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text('أحمد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF21143F))),
                                const Text('2,840', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF21143F))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // المركز الثالث: محمود (برونز)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE0A47A), width: 3),
                            ),
                            child: ClipOval(
                              child: Image.asset('assets/images/av-mahmoud.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 95,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFD0603F), Color(0xFF8A3220)],
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3C3A5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('3', style: TextStyle(color: Color(0xFF21143F), fontWeight: FontWeight.w900)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text('محمود', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                const Text('1,980', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // بقية القائمة
                Expanded(
                  child: ListView.separated(
                    itemCount: _rankings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _rankings[index];
                      final isUser = item['isUser'] == true;
                      return Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? const LinearGradient(colors: [Color(0xFF4A2490), Color(0xFF6A24C9)])
                              : null,
                          color: isUser ? null : const Color(0xFF2A1850),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUser ? const Color(0xFFC9A2FF) : const Color(0xFFA35BFF).withValues(alpha: 0.3),
                            width: isUser ? 1.5 : 1.0,
                          ),
                          boxShadow: isUser
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFA35BFF).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${item['rank']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isUser ? Colors.white : const Color(0xFFCFC6E4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 19,
                              backgroundImage: AssetImage(item['avatar'] as String),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                            Text(
                              item['score'] as String,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: LammaColors.gold500),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // زر العب تاني
                GameButton(
                  text: 'العب تاني',
                  showArrow: false,
                  height: 60,
                  onPressed: () {
                    context.push('/mode-select');
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
