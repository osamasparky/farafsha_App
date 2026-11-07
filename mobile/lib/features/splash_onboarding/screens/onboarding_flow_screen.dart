import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _walkImages = [
    'assets/images/walk_1.png',
    'assets/images/walk_2.png',
    'assets/images/walk_3.png',
    'assets/images/walk_4.png',
    'assets/images/walk_5.png',
    'assets/images/walk_6.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _walkImages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.push('/mode-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _walkImages.length - 1;

    return LammaScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // زر التخطي العلوي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push('/mode-select'),
                  child: const Text(
                    'تخطي',
                    style: TextStyle(
                      color: Color(0xFFEADFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            // عارض شرائح صور التعريف الـ 6 الرسمية
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _walkImages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8F4BF0).withValues(alpha: 0.35),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            _walkImages[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // شريط المؤشر وزر الإجراء السفلي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // مؤشر الصفحات الـ 6
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_walkImages.length, (index) {
                      final isCurrent = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrent ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFFFD27A) : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFD27A).withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // زر CTA الرئيسي المجسم
                  GameButton(
                    text: isLastPage ? 'يلا نبدأ 🚀' : 'التالي',
                    onPressed: _nextPage,
                  ),

                  const SizedBox(height: 10),

                  // رابط تسجيل الدخول السريع
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Color(0xFFE4D9FA), fontFamily: 'Cairo'),
                        children: [
                          TextSpan(text: 'لديك حساب؟ '),
                          TextSpan(
                            text: 'تسجيل الدخول',
                            style: TextStyle(fontWeight: FontWeight.w900, color: LammaColors.gold300),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
