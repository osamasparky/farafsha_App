import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // المراحل: 1 = إدخال المعرف، 2 = إدخال رمز التحقق، 3 = كلمة المرور الجديدة
  int _currentStep = 1;

  final TextEditingController _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  String _sentTarget = '';
  String _resetToken = '';

  // مؤقت إعادة الإرسال
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void dispose() {
    _identifierController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // الخطوة 1: طلب إرسال رمز التحقق
  Future<void> _handleRequestOtp() async {
    final input = _identifierController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف المسجل.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService.instance.forgotPassword(input);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _sentTarget = res['target']?.toString() ?? input;
        _currentStep = 2;
        _successMessage = res['message']?.toString();
      });
      _startResendTimer();
      // التركيز على أول خانة OTP
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } else {
      setState(() => _errorMessage = res['message']?.toString() ?? 'فشل إرسال رمز التحقق.');
    }
  }

  // الخطوة 2: التحقق من كود الـ OTP
  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      setState(() => _errorMessage = 'يرجى إدخال رمز التحقق المكون من 4 أرقام كاملاً.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService.instance.verifyResetOtp(
      identifier: _sentTarget.isNotEmpty ? _sentTarget : _identifierController.text.trim(),
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true && res['reset_token'] != null) {
      setState(() {
        _resetToken = res['reset_token'].toString();
        _currentStep = 3;
        _successMessage = 'تم التحقق بنجاح! أدخل كلمة المرور الجديدة الآن.';
      });
    } else {
      setState(() => _errorMessage = res['message']?.toString() ?? 'رمز التحقق غير صحيح.');
    }
  }

  // الخطوة 3: تعيين كلمة المرور الجديدة
  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال كلمة المرور الجديدة.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'كلمة المرور يجب ألا تقل عن 6 خانات.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'كلمتا المرور غير متطابقتين.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService.instance.resetPassword(
      resetToken: _resetToken,
      password: newPass,
      passwordConfirmation: confirmPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      // تسجيل الدخول التلقائي للمستخدم
      if (res['user'] != null && res['token'] != null) {
        final u = res['user'];
        await AuthService.instance.loginUser(
          name: u['name'] ?? 'مستخدم فرفشة',
          email: u['email'],
          phone: u['phone'],
          avatar: u['avatar'],
          token: res['token'],
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعادة تعيين كلمة المرور بنجاح! مرحباً بك مجدداً 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/home');
    } else {
      setState(() => _errorMessage = res['message']?.toString() ?? 'فشل تعيين كلمة المرور.');
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepBadge(step: 1, label: 'إرسال الرمز'),
        _buildStepLine(active: _currentStep >= 2),
        _buildStepBadge(step: 2, label: 'تأكيد OTP'),
        _buildStepLine(active: _currentStep >= 3),
        _buildStepBadge(step: 3, label: 'كلمة مرور جديدة'),
      ],
    );
  }

  Widget _buildStepBadge({required int step, required String label}) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCurrent
                ? const LinearGradient(colors: [Color(0xFFFFD27A), Color(0xFFFFAE34)])
                : isActive
                    ? const LinearGradient(colors: [Color(0xFF8F4BF0), Color(0xFF6A24C9)])
                    : null,
            color: isActive ? null : Colors.white12,
            border: Border.all(
              color: isCurrent ? Colors.white : (isActive ? const Color(0xFFB98AFF) : Colors.white24),
              width: isCurrent ? 2.5 : 1.5,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(color: const Color(0xFFFFD27A).withOpacity(0.5), blurRadius: 10, spreadRadius: 1),
                  ]
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isCurrent ? const Color(0xFF14072B) : (isActive ? Colors.white : Colors.white54),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? const Color(0xFFFFD27A) : (isActive ? Colors.white70 : Colors.white38),
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool active}) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      color: active ? const Color(0xFF8F4BF0) : Colors.white12,
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أدخل بريدك الإلكتروني أو رقم هاتفك المرتبط بالحساب وسنرسل لك رمز تحقق فوري لاستعادة حسابك.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFCFC6E4), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB98AFF), width: 1.5),
          ),
          child: TextFormField(
            controller: _identifierController,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'البريد أو الهاتف (مثال: 01012345678)',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: Icon(Icons.account_circle_outlined, color: Color(0xFFB98AFF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSubmitButton(
          title: 'إرسال رمز التحقق 📲',
          onTap: _handleRequestOtp,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تم إرسال رمز التحقق المكون من 4 أرقام إلى:\n$_sentTarget',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFCFC6E4), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 58,
              height: 64,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _otpFocusNodes[index].hasFocus ? const Color(0xFFFFD27A) : const Color(0xFFB98AFF),
                    width: _otpFocusNodes[index].hasFocus ? 2.2 : 1.4,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 3) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                      if (index == 3 && val.isNotEmpty) {
                        _handleVerifyOtp();
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Center(
          child: _resendCountdown > 0
              ? Text(
                  'إعادة الإرسال متاحة خلال: 00:$_resendCountdown ثانية',
                  style: const TextStyle(color: Color(0xFFA99BC8), fontSize: 12, fontWeight: FontWeight.w600),
                )
              : TextButton(
                  onPressed: _handleRequestOtp,
                  child: const Text(
                    'إعادة إرسال رمز التحقق 🔄',
                    style: TextStyle(color: Color(0xFFFFD27A), fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _buildSubmitButton(
          title: 'تأكيد رمز التحقق 🚀',
          onTap: _handleVerifyOtp,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أدخل كلمة المرور الجديدة وتأكيدها لتسجيل الدخول الفوري لحسابك 🔒',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFCFC6E4), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),
        // كلمة المرور الجديدة
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB98AFF), width: 1.5),
          ),
          child: TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPass,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'كلمة المرور الجديدة (6 خانات كحد أدنى)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFB98AFF)),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        // تأكيد كلمة المرور
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB98AFF), width: 1.5),
          ),
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPass,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'تأكيد كلمة المرور الجديدة',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFFB98AFF)),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        _buildSubmitButton(
          title: 'حفظ كلمة المرور والدخول 🎉',
          onTap: _handleResetPassword,
        ),
      ],
    );
  }

  Widget _buildSubmitButton({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8F4BF0), Color(0xFF6A24C9)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8F4BF0).withOpacity(0.5),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // زر العودة والشعار العلوي
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentStep > 1) {
                      setState(() {
                        _currentStep--;
                        _errorMessage = null;
                        _successMessage = null;
                      });
                    } else {
                      context.pop();
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const Spacer(),
                const Text(
                  'استعادة كلمة المرور 🔑',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 24),

            // مؤشر الخطوات الثلاث
            _buildStepIndicator(),
            const SizedBox(height: 24),

            // لوحة المحتوى المركزية
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1138).withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB98AFF).withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2566A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD2566A), width: 1.2),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFFF9AA2), fontSize: 13, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 13, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // رابط العودة لتسجيل الدخول
            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'تذكرت كلمة المرور؟ تسجيل الدخول',
                  style: TextStyle(
                    color: Color(0xFFFFD27A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFFFD27A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
