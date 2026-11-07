import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // حقول الإدخال تبدأ فارغة تماماً بدون أي بيانات مسبقة (Placeholders نظيفة)
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _socialProviders = [];

  @override
  void initState() {
    super.initState();
    _loadSocialProviders();
  }

  Future<void> _loadSocialProviders() async {
    try {
      final providers = await ApiService.instance.getSocialProviders();
      if (mounted) {
        setState(() {
          _socialProviders = providers.where((p) => p['is_enabled'] == true).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// التحقق من صحة البريد الإلكتروني أو رقم الهاتف
  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف';
    }
    final trimmed = value.trim();

    // إذا كان يحتوي على @ نتحقق من صيغة البريد
    if (trimmed.contains('@')) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'يرجى إدخال بريد إلكتروني صحيح (مثال: name@domain.com)';
      }
    } else {
      // نتحقق من رقم الهاتف (أرقام فقط على الأقل 10 أرقام)
      final cleanPhone = trimmed.replaceAll(RegExp(r'[\s\-+]'), '');
      if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
        return 'يرجى إدخال بريد إلكتروني أو رقم هاتف صحيح';
      }
      if (cleanPhone.length < 10) {
        return 'رقم الهاتف يجب ألا يقل عن 10 أرقام';
      }
    }
    return null;
  }

  /// التحقق من كلمة المرور
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
    }
    return null;
  }

  /// إرسال طلب تسجيل الدخول للسيرفر
  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final result = await AuthService.instance.loginWithCredentials(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      context.go('/home');
    } else {
      final msg = result['message']?.toString() ?? 'بيانات الدخول غير صحيحة';
      setState(() => _errorMessage = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFD2566A),
        ),
      );
    }
  }

  /// تسجيل الدخول عبر وسائل التواصل الاجتماعي مع استيفاء الهاتف إذا لزم
  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    final res = await AuthService.instance.loginWithSocial(
      provider,
      name: 'مستخدم $provider',
      email: '$provider@farfasha.app',
      phone: '01012345678',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'فشل تسجيل الدخول'),
          backgroundColor: const Color(0xFFD2566A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // لوجو فرفشة 3D
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8F4BF0).withValues(alpha: 0.55),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.asset('assets/images/farfasha_logo.png', fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'تسجيل الدخول إلى فرفشة 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'أدخل بيانات حسابك لتستمتع بكل الألعاب وتحفظ نقاطك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD9CCF2),
                ),
              ),

              const SizedBox(height: 24),

              // رسالة الخطأ العامة إذا وُجدت
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2566A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD2566A), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFD2566A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFB3B8), fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. حقل البريد الإلكتروني أو رقم الهاتف (يبدأ فارغاً بدون Placeholder مضلل)
              const Text(
                'البريد الإلكتروني أو رقم الهاتف',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LammaColors.violet400, width: 1.5),
                ),
                child: TextFormField(
                  controller: _identifierController,
                  validator: _validateIdentifier,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'البريد الإلكتروني أو رقم الموبايل',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFFB98AFF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. حقل كلمة المرور (يبدأ فارغاً مع إمكانية الإظهار والإخفاء)
              const Text(
                'كلمة المرور',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LammaColors.violet400, width: 1.5),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  validator: _validatePassword,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFB98AFF)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // زر تسجيل الدخول
              GestureDetector(
                onTap: _isLoading ? null : _handleLogin,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8F4BF0), Color(0xFF6A24C9)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF8F4BF0).withValues(alpha: 0.45), blurRadius: 14),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text(
                            'تسجيل الدخول 🚀',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // رابط إنشاء حساب جديد
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ليس لديك حساب بعد؟ ',
                    style: TextStyle(color: Color(0xFFA99BC8), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: Color(0xFFFFD27A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFFFD27A),
                      ),
                    ),
                  ),
                ],
              ),

              // قسم وسائل التواصل الاجتماعي (من لوحة التحكم)
              if (_socialProviders.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('أو الدخول عبر', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  ],
                ),
                const SizedBox(height: 16),
                ..._socialProviders.map((provider) {
                  final code = provider['provider']?.toString() ?? '';
                  final isGoogle = code == 'google';
                  final isApple = code == 'apple';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => _handleSocialLogin(code),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: isGoogle
                              ? Colors.white
                              : (isApple ? Colors.black : const Color(0xFF1877F2)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isGoogle ? Colors.transparent : Colors.white24,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isGoogle)
                              const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 30)
                            else if (isApple)
                              const Icon(Icons.apple_rounded, color: Colors.white, size: 24)
                            else
                              const Icon(Icons.facebook_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              isGoogle
                                  ? 'المتابعة بحساب Google'
                                  : (isApple ? 'المتابعة بحساب Apple' : 'المتابعة بحساب Facebook'),
                              style: TextStyle(
                                color: isGoogle ? const Color(0xFF202124) : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // فاصل أو
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('أو', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                ],
              ),

              const SizedBox(height: 16),

              // زر الدخول كزائر
              GestureDetector(
                onTap: () async {
                  await AuthService.instance.loginAsGuest();
                  if (!context.mounted) return;
                  context.go('/home');
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: LammaColors.violet500.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD27A), width: 1.6),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.theater_comedy_rounded, color: Color(0xFFFFD27A), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'الدخول كزائر',
                        style: TextStyle(color: Color(0xFFFFD27A), fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'بالمتابعة إنت موافق على الشروط وسياسة الخصوصية لتطبيق فرفشة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFFA99BC8), height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
