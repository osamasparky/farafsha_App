import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _selectedTab = 0; // 0: الكل, 1: مجاني, 2: عندي

  final List<String> _tabs = ['الكل', 'مجاني', 'عندي'];

  final List<Map<String, dynamic>> _packs = [
    {
      'title': 'أمثال الجدّات',
      'meta': '120 بطاقة · عائلي',
      'isOwned': true,
      'isFree': false,
      'price': '',
      'image': 'assets/images/ic-quote.webp',
      'gradient': const [Color(0xFFD2566A), Color(0xFF8E2A4E)],
    },
    {
      'title': 'أفلام الأبيض والأسود',
      'meta': '80 بطاقة · كلاسيك',
      'isOwned': false,
      'isFree': false,
      'price': '19.99 ج.م',
      'image': 'assets/images/ic-film.webp',
      'gradient': const [Color(0xFF8F3BD0), Color(0xFF561C94)],
    },
    {
      'title': 'معلومات خليجية',
      'meta': '150 سؤال · خليجي',
      'isOwned': false,
      'isFree': true,
      'price': 'نزّل مجانًا',
      'image': 'assets/images/ic-bulb.webp',
      'gradient': const [Color(0xFF2F6E7A), Color(0xFF1B3F52)],
    },
    {
      'title': 'أغاني الزمن الجميل',
      'meta': '60 تلميح · نصي',
      'isOwned': false,
      'isFree': false,
      'price': '19.99 ج.م',
      'image': 'assets/images/ic-music.webp',
      'gradient': const [Color(0xFFB23A72), Color(0xFF6E1C4E)],
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
            center: Alignment(0.0, -0.75),
            radius: 1.0,
            colors: [
              Color(0xFF4A2290),
              Color(0xFF241050),
              Color(0xFF150A2E),
            ],
            stops: [0.0, 0.55, 1.0],
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
                      'الحزم والمحتوى',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 12),

                // بانر لمة بلس VIP
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF5C04E), Color(0xFFE08A2A), Color(0xFFC2386F)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF8A2A50), width: 5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE08A2A).withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        left: -15,
                        top: -10,
                        child: Opacity(
                          opacity: 0.35,
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            size: 110,
                            color: Color(0xFFFFF1C7),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A0E35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'قريبًا',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: LammaColors.gold300),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'لمّة بلس',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2A0E35)),
                          ),
                          const SizedBox(height: 4),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('✓ كل الحزم مفتوحة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2A0E35))),
                              Text('✓ من غير إعلانات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2A0E35))),
                              Text('✓ غرف لحد 20 لاعب', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2A0E35))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A0E35),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('اشتراك لمّة بلس سيكون متاحاً في التحديث القادم!')),
                                );
                              },
                              child: const Text(
                                'اشترك · 49.99 ج.م / شهر',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // شريط التبويب
                Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _selectedTab == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(colors: [Color(0xFFA35BFF), Color(0xFF7A2FE0)])
                              : null,
                          borderRadius: BorderRadius.circular(999),
                          border: isSelected ? null : Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFFCFC6E4),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 14),

                // شبكة الحزم
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _packs.length,
                    itemBuilder: (context, index) {
                      final p = _packs[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1850),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA35BFF).withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // غلاف الحزمة
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: p['gradient'] as List<Color>),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              ),
                              child: Center(
                                child: Image.asset(
                                  p['image'] as String,
                                  width: 50,
                                  height: 48,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.style_rounded, size: 36, color: Colors.white),
                                ),
                              ),
                            ),
                            // التفاصيل وزر الشراء
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['title'] as String,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p['meta'] as String,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFCFC6E4)),
                                  ),
                                  const SizedBox(height: 6),
                                  if (p['isOwned'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF35B88E).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        '✓ عندك',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6FD9B5)),
                                      ),
                                    )
                                  else if (p['isFree'] == true)
                                    SizedBox(
                                      height: 32,
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFF6FD9B5), width: 1.5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                          padding: EdgeInsets.zero,
                                        ),
                                        onPressed: () {
                                          setState(() => p['isOwned'] = true);
                                        },
                                        child: const Text(
                                          'نزّل مجانًا',
                                          style: TextStyle(color: Color(0xFF6FD9B5), fontWeight: FontWeight.w900, fontSize: 12),
                                        ),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      height: 32,
                                      width: double.infinity,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LammaGradients.ctaPrimary,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Center(
                                          child: Text(
                                            p['price'] as String,
                                            style: const TextStyle(color: Color(0xFF2A0E35), fontWeight: FontWeight.w900, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
