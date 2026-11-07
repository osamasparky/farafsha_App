import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/game_button.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final Map<String, dynamic>? registrationData;

  const OtpScreen({
    super.key,
    this.phoneNumber = '',
    this.registrationData,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _focusedIndex = 0;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // ربط مستمعات التركيز لتحديث شكل الصناديق
    for (int i = 0; i < 4; i++) {
      final index = i;
      _focusNodes[i].addListener(() {
        if (_focusNodes[index].hasFocus) {
          setState(() => _focusedIndex = index);
        }
      });
    }

    // التركيز تلقائياً على الخانة الأولى بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _errorMessage = null);

    // معالجة لصق كود كامل من 4 أرقام في أي خانة
    if (value.length > 1) {
      final cleanDigits = value.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.length >= 4) {
        for (int i = 0; i < 4; i++) {
          _controllers[i].text = cleanDigits[i];
        }
        _focusNodes[3].requestFocus();
        _submitOtp();
        return;
      } else {
        _controllers[index].text = value.isNotEmpty ? value.substring(value.length - 1) : '';
      }
    }

    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_otpCode.length == 4) {
          _submitOtp();
        }
      }
    }
  }

  // إعادة إرسال الكود
  Future<void> _handleResend() async {
    if (!_canResend || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetPhone = widget.phoneNumber.isNotEmpty
        ? widget.phoneNumber
        : (widget.registrationData?['phone']?.toString() ?? '');
    final targetEmail = widget.registrationData?['email']?.toString();

    final res = await AuthService.instance.sendOtp(
      phone: targetPhone,
      email: targetEmail,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _startTimer();
      // مسح الخانات القديمة
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'تمت إعادة إرسال كود التحقق بنجاح 📲'),
          backgroundColor: const Color(0xFF35B88E),
        ),
      );
    } else {
      setState(() => _errorMessage = res['message']?.toString() ?? 'تعذر إعادة إرسال الرمز.');
    }
  }

  // تأكيد كود التحقق وإتمام التسجيل أو الدخول
  Future<void> _submitOtp() async {
    final code = _otpCode;
    if (code.length < 4) {
      setState(() => _errorMessage = 'يرجى إدخال رمز التحقق المكون من 4 أرقام كاملاً.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetPhone = widget.phoneNumber.isNotEmpty
        ? widget.phoneNumber
        : (widget.registrationData?['phone']?.toString() ?? '');
    final regData = widget.registrationData;

    try {
      if (regData != null) {
        // حالة: مستخدم يسجل حساباً جديداً
        final res = await AuthService.instance.registerUser(
          name: regData['name'] ?? '',
          phone: regData['phone'] ?? targetPhone,
          email: regData['email'] ?? '',
          password: regData['password'] ?? '',
          avatar: regData['avatar'],
          otp: code,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم توثيق هاتفك وإنشاء الحساب بنجاح! مرحباً بك في فرفشة 🎉'),
              backgroundColor: Color(0xFF35B88E),
            ),
          );
          context.go('/home');
        } else {
          setState(() {
            _errorMessage = res['message']?.toString() ?? 'رمز التحقق غير صحيح أو انتهت صلاحيته.';
          });
        }
      } else {
        // حالة: تحقق من OTP بدون بيانات تسجيل مسبقة (مثل تسجيل دخول سريع بالهاتف)
        final res = await AuthService.instance.verifyOtp(
          phone: targetPhone,
          code: code,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message']?.toString() ?? 'تم التحقق بنجاح! 🎉'),
              backgroundColor: const Color(0xFF35B88E),
            ),
          );
          if (res['is_new_user'] == true) {
            context.push('/register');
          } else {
            context.go('/home');
          }
        } else {
          setState(() {
            _errorMessage = res['message']?.toString() ?? 'رمز التحقق غير صحيح، يرجى المحاولة ثانية.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء الاتصال بالسيرفر. يرجى المحاولة لاحقاً.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPhone = widget.phoneNumber.isNotEmpty
        ? widget.phoneNumber
        : (widget.registrationData?['phone']?.toString() ?? '');

    return LammaScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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

              // أيقونة التحقق المجسمة المائلة
              Center(
                child: Transform.rotate(
                  angle: -6 * math.pi / 180,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB98AFF), Color(0xFF6A24C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: const Border(
                        top: BorderSide(color: Colors.white54, width: 1.5),
                        bottom: BorderSide(color: Color(0xFF4A1690), width: 5.5),
                        left: BorderSide(color: Colors.white24, width: 1),
                        right: BorderSide(color: Colors.white24, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: LammaColors.violet500.withValues(alpha: 0.6),
                          blurRadius: 36,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.mark_chat_unread_rounded, size: 52, color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'رمز التحقق السريع 📲',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Color(0xFFD9CCF2), fontFamily: 'Cairo', height: 1.6),
                  children: [
                    const TextSpan(text: 'تم إرسال رمز تأكيد مكون من 4 أرقام عبر واتساب إلى:\n'),
                    TextSpan(
                      text: '$displayPhone ',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),

              Center(
                child: TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.edit_rounded, size: 16, color: LammaColors.gold300),
                  label: const Text(
                    'تعديل رقم الهاتف',
                    style: TextStyle(color: LammaColors.gold300, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // رسالة الخطأ إن وجدت
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2566A).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD2566A), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFFFB3B8), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFB3B8), fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // خانات إدخال كود الـ OTP الأربعة
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    final bool isFilled = _controllers[index].text.isNotEmpty;
                    final bool isFocus = _focusedIndex == index;

                    return Container(
                      width: 68,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? LammaColors.violet500.withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isFocus
                              ? LammaColors.gold500
                              : (isFilled ? LammaColors.violet400 : LammaColors.cardBorder),
                          width: isFocus ? 2.5 : 1.8,
                        ),
                        boxShadow: isFocus
                            ? [
                                BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.3), blurRadius: 12),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (val) => _onDigitChanged(index, val),
                          onTap: () {
                            _controllers[index].selection = TextSelection.fromPosition(
                              TextPosition(offset: _controllers[index].text.length),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 28),

              // مؤقت إعادة الإرسال أو زر إعادة الإرسال الفعلي
              Center(
                child: _canResend
                    ? TextButton.icon(
                        onPressed: _isLoading ? null : _handleResend,
                        icon: const Icon(Icons.refresh_rounded, color: LammaColors.gold300, size: 20),
                        label: const Text(
                          'إعادة إرسال رمز التحقق عبر واتساب 🔄',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: LammaColors.gold300,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFD9CCF2)),
                          const SizedBox(width: 6),
                          Text(
                            'إعادة الإرسال بعد 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFD9CCF2),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 36),

              // زر التأكيد وإتمام التسجيل
              GameButton(
                text: _isLoading ? 'جاري التحقق...' : 'تأكيد الرمز وإتمام الدخول 🚀',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submitOtp,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
