import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';
import '../../../core/widgets/lamma_wordmark.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      context.push('/mode-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildSlide1(),
                _buildSlide2(),
                _buildSlide3(),
              ],
            ),
          ),

          // شريط المؤشر وزر الإجراء السفلي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                // مؤشر الصفحات الثلاثي
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isCurrent = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),

                // زر CTA الرئيسي المجسم
                GameButton(
                  text: _currentPage == 0
                      ? 'ابدأ الآن'
                      : (_currentPage == 1 ? 'التالي' : 'يلا نبدأ'),
                  onPressed: _nextPage,
                ),

                const SizedBox(height: 12),

                // رابط تسجيل الدخول
                if (_currentPage == 0)
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 15, color: Color(0xFFE4D9FA), fontFamily: 'Cairo'),
                        children: [
                          TextSpan(text: 'لديك حساب؟ '),
                          TextSpan(
                            text: 'تسجيل الدخول',
                            style: TextStyle(fontWeight: FontWeight.w900, color: LammaColors.gold300),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// الشريحة الأولى: الشعار والتاج وجمهور الأصدقاء (01-Main.html)
  Widget _buildSlide1() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const LammaWordmark(fontSize: 110),
        const SizedBox(height: 4),
        const Text(
          'مجموعة ألعاب جماعية للمتعة والتحدي\nمع الأصدقاء والعائلة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEADFFF),
            height: 1.55,
          ),
        ),
        const Spacer(),
        // صورة تجمع الأصدقاء
        Image.asset(
          'assets/images/crowd.png',
          width: 380,
          fit: BoxFit.contain,
        ),
        const Spacer(),
      ],
    );
  }

  /// الشريحة الثانية: العب أونلاين مع صحابك (09-Onboard2.html)
  Widget _buildSlide2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/mode-select'),
              child: const Text('تخطي', style: TextStyle(color: Color(0xFFEADFFF), fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          Image.asset(
            'assets/images/online.png',
            width: 280,
            height: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          // أفاتارات اللاعبين المتداخلة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatarOverlap('assets/images/av-sara.png'),
              _buildAvatarOverlap('assets/images/av-ahmed.png', offsetRight: -12),
              _buildAvatarOverlap('assets/images/av-mena.png', offsetRight: -12),
              Container(
                margin: const EdgeInsets.only(right: 0),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LammaColors.violet500,
                  border: Border.all(color: const Color(0xFF2A1458), width: 3),
                ),
                child: const Center(
                  child: Text('+8', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'العب أونلاين مع صحابك',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(offset: Offset(0, 3), color: Color(0xFF6A24C9))],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اعمل غرفة، شارك الرمز، ويدخلوا معاك\nمن أي مكان، لحد 12 لاعب.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFE4D9FA),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// الشريحة الثالثة: ألعاب ومحتوى بيتجدد (10-Onboard3.html)
  Widget _buildSlide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/mode-select'),
              child: const Text('تخطي', style: TextStyle(color: Color(0xFFEADFFF), fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          // كولاج الأيقونات والمحتوى المتجدد
          SizedBox(
            width: 320,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/images/popcorn.png', width: 150, fit: BoxFit.contain),
                Positioned(
                  top: 10,
                  right: 20,
                  child: _buildTileIcon('assets/images/ic-quote.png', const Color(0xFFD2566A), 8),
                ),
                Positioned(
                  top: 10,
                  left: 20,
                  child: _buildTileIcon('assets/images/ic-bulb.png', const Color(0xFF2F6E7A), -10),
                ),
                Positioned(
                  bottom: 10,
                  right: 30,
                  child: _buildTileIcon('assets/images/ic-music.png', const Color(0xFFB23A72), -8),
                ),
                Positioned(
                  bottom: 10,
                  left: 30,
                  child: _buildTileIcon('assets/images/ic-dice.png', const Color(0xFF8C3468), 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ألعاب ومحتوى بيتجدد',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(offset: Offset(0, 3), color: Color(0xFF6A24C9))],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أمثال، أفلام، أغاني، ومعلومات…\nكل أسبوع فيه جديد يضحّككم.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFE4D9FA),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOverlap(String path, {double offsetRight = 0}) {
    return Container(
      margin: EdgeInsets.only(right: offsetRight),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A1458), width: 3),
        image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTileIcon(String path, Color color, double rotateDeg) {
    return Transform.rotate(
      angle: rotateDeg * 3.14159 / 180,
      child: Container(
        width: 68,
        height: 68,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Image.asset(path, fit: BoxFit.contain),
      ),
    );
  }
}
