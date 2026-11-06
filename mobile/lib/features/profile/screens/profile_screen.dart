import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.76),
            radius: 1.0,
            colors: [
              Color(0xFF5A2A9E),
              Color(0xFF2A1458),
              Color(0xFF150A2E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // الشريط العلوي (رجوع + الإعدادات)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'الملف الشخصي',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // صورة الملف الشخصي ومؤشر المستوى
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFB98AFF), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA35BFF).withValues(alpha: 0.55),
                            blurRadius: 36,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/av-ahmed.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.push('/register');
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: LammaColors.gold500,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2A1458), width: 3),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Color(0xFF2A0E35), size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Text(
                  'أسامة صبري',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: LammaColors.gold500, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'المستوى 12',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: LammaColors.gold500),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // شريط خبرة التقدم
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: 0.69,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFFC24B), Color(0xFFFF8A4C)]),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '3,450 / 5,000 نقطة خبرة',
                        style: TextStyle(fontSize: 12, color: Color(0xFFCFC6E4)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // كروت الإحصائيات الثلاثة
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.emoji_events_rounded,
                        iconColor: LammaColors.gold500,
                        value: '32',
                        label: 'فوز',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.sports_esports_rounded,
                        iconColor: const Color(0xFFC9A2FF),
                        value: '148',
                        label: 'لعبة',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFF8A4C),
                        value: '4,320',
                        label: 'نقطة',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // آخر الأوسمة
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'آخر الأوسمة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildBadgeCard(
                        label: 'ملك الأمثال',
                        gradientColors: [const Color(0xFFD2566A), const Color(0xFF8E2A4E)],
                        iconAsset: 'assets/images/ic-quote.png',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBadgeCard(
                        label: 'العبقري',
                        gradientColors: [const Color(0xFF2F6E7A), const Color(0xFF1B3F52)],
                        iconAsset: 'assets/images/ic-bulb.png',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBadgeCard(
                        label: 'سمّيع',
                        gradientColors: [const Color(0xFFB23A72), const Color(0xFF6E1C4E)],
                        iconAsset: 'assets/images/ic-music.png',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, color: Color(0xFFA99BC8), size: 24),
                            SizedBox(height: 2),
                            Text('+9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFA99BC8))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // روابط الحساب السريعة (أصحابي، سجل الألعاب)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildNavigationRow(
                        icon: Icons.people_outline_rounded,
                        title: 'أصحابي',
                        count: '24',
                        onTap: () {},
                        hasDivider: true,
                      ),
                      _buildNavigationRow(
                        icon: Icons.history_rounded,
                        title: 'سجل الألعاب',
                        count: '',
                        onTap: () => context.push('/results'),
                        hasDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1F74), Color(0xFF241050)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCFC6E4))),
        ],
      ),
    );
  }

  Widget _buildBadgeCard({
    required String label,
    required List<Color> gradientColors,
    required String iconAsset,
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            width: 32,
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.military_tech_rounded, size: 26, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    required String count,
    required VoidCallback onTap,
    required bool hasDivider,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFC9A2FF), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                if (count.isNotEmpty) ...[
                  Text(count, style: const TextStyle(fontSize: 13, color: Color(0xFFCFC6E4))),
                  const SizedBox(width: 6),
                ],
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCFC6E4), size: 14),
              ],
            ),
          ),
          if (hasDivider) Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
        ],
      ),
    );
  }
}
