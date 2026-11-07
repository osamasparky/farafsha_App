import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // إظهار شاشة البداية بهوية فرفشة لمدة ثانية ثم الفحص التلقائي
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // إذا كان المستخدم لديه جلسة مسجلة أو مسجل كزائر، ينتقل مباشرة إلى الرئيسية!
    if (AuthService.instance.isLoggedIn || AuthService.instance.isGuest) {
      context.go('/home');
      return;
    }

    // إذا لم تكن هناك جلسة، نظهر أزرار البداية والدخول
    setState(() {
      _showActions = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150A2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية الشاشة الكاملة من الصورة الرسمية
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // تدرج لوني سفلي ناعم لإبراز الأزرار التفاعلية فقط عند عدم وجود جلسة
          if (_showActions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF150A2E).withOpacity(0.95),
                      const Color(0xFF150A2E).withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // أزرار البداية والانتقال للتعريف تظهر فقط إذا لم يكن مسجلاً
          if (_showActions)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameButton(
                        text: 'ابدأ الآن 🚀',
                        onPressed: () => context.push('/onboarding'),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 15, color: Color(0xFFE4D9FA), fontFamily: 'Cairo'),
                              children: [
                                TextSpan(text: 'لديك حساب بالفعل؟ '),
                                TextSpan(
                                  text: 'تسجيل الدخول',
                                  style: TextStyle(fontWeight: FontWeight.w900, color: LammaColors.gold300),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
