import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';
import '../../../core/widgets/lamma_wordmark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '5');
  String _countryCode = '+966';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // شعار لمّة
            const Center(
              child: LammaWordmark(fontSize: 82),
            ),

            const SizedBox(height: 16),

            const Text(
              'أهلاً بيك في اللمّة!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'سجّل برقم موبايلك عشان تحفظ نقاطك وأصحابك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD9CCF2),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'رقم الموبايل',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEADFFF)),
            ),
            const SizedBox(height: 8),

            // إدخال رقم الهاتف مع كود الدولة
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LammaColors.cardBorder, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _countryCode,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LammaColors.violet400, width: 2),
                        boxShadow: [
                          BoxShadow(color: LammaColors.violet500.withValues(alpha: 0.2), blurRadius: 10),
                        ],
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                        decoration: const InputDecoration(
                          hintText: '5X XXX XXXX',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // زر إرسال رمز التحقق
            GameButton(
              text: 'إرسال رمز التحقق',
              onPressed: () {
                context.push('/otp');
              },
            ),

            const SizedBox(height: 22),

            // فاصل أو
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('أو', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
              ],
            ),

            const SizedBox(height: 22),

            // أزرار تسجيل الدخول الاجتماعي
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('متابعة بـ Google', style: TextStyle(color: Color(0xFF21143F), fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Center(
                      child: Text('متابعة بـ Apple', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // زر الدخول كضيف (بدون حساب)
            GestureDetector(
              onTap: () => context.push('/home'),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: LammaColors.violet500.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LammaColors.cardBorder, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'العب كضيف من غير حساب',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'بالمتابعة إنت موافق على الشروط وسياسة الخصوصية',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFFA99BC8), height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

