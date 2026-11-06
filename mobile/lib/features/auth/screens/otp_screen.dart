import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, this.phoneNumber = '+966 5X XXX XX21'});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controllers[0].text = '7';
    _controllers[1].text = '4';
    _focusedIndex = 2;
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                onPressed: () => context.pop(),
              ),
            ),

            const SizedBox(height: 14),

            // أيقونة الهاتف والتحقق المجسمة المائلة
            Center(
              child: Transform.rotate(
                angle: -6 * math.pi / 180,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB98AFF), Color(0xFF6A24C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: const Border(
                      top: BorderSide(color: Colors.white54, width: 1.5),
                      bottom: BorderSide(color: Color(0xFF4A1690), width: 5.5),
                      left: BorderSide(color: Colors.white24, width: 1),
                      right: BorderSide(color: Colors.white24, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LammaColors.violet500.withValues(alpha: 0.6),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.mark_email_read_rounded, size: 54, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'اكتب رمز التحقق',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(fontSize: 15, color: Color(0xFFD9CCF2), fontFamily: 'Cairo', height: 1.7),
                children: [
                  TextSpan(text: 'بعتنالك رمز من 4 أرقام على\n'),
                  TextSpan(text: '+966 5X XXX XX21 ', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  TextSpan(text: 'تغيير', style: TextStyle(fontWeight: FontWeight.w700, color: LammaColors.gold300)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // خانات كود الـ OTP الأربعة
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final bool isFilled = _controllers[index].text.isNotEmpty;
                  final bool isFocus = _focusedIndex == index;

                  return Container(
                    width: 70,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? LammaColors.violet500.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isFocus
                            ? LammaColors.gold500
                            : (isFilled ? LammaColors.violet400 : LammaColors.cardBorder),
                        width: isFocus ? 2.5 : 1.8,
                      ),
                      boxShadow: isFocus
                          ? [
                              BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.25), blurRadius: 10),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _controllers[index].text,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            const Center(
              child: Text(
                'ما وصلكش؟ إعادة الإرسال بعد 00:42',
                style: TextStyle(fontSize: 15, color: Color(0xFFD9CCF2), fontWeight: FontWeight.w600),
              ),
            ),

            const Spacer(),

            GameButton(
              text: 'تأكيد',
              onPressed: () {
                context.push('/register');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

