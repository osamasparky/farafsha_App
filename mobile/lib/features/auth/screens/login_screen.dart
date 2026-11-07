import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../authentication/presentation/widgets/social_login_row.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // حقول الإدخال تبدأ فارغة تماماً بدون أي بيانات مسبقة
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

    if (trimmed.contains('@')) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'صيغة البريد غير صحيحة (مثال: name@domain.com)';
      }
    } else {
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

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // لوجو فرفشة 3D المتوهج
              Center(
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFFFD27A), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8F4BF0).withValues(alpha: 0.65),
                        blurRadius: 40,
                        spreadRadius: 6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset('assets/images/farfasha_logo.png', fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'تسجيل الدخول إلى فرفشة 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
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

              const SizedBox(height: 22),

              // كارت تسجيل الدخول الزجاجي الأنيق (Glassmorphism Card)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF220F45).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // رسالة الخطأ العامة
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD2566A).withValues(alpha: 0.18),
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

                    // 1. حقل البريد الإلكتروني أو رقم الهاتف
                    const Text(
                      'البريد الإلكتروني أو رقم الهاتف',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.5), width: 1.4),
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

                    // 2. حقل كلمة المرور
                    const Text(
                      'كلمة المرور',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEADFFF)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.5), width: 1.4),
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
                              color: Colors.white60,
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

                    const SizedBox(height: 10),

                    // رابط نسيت كلمة المرور
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            color: Color(0xFFFFD27A),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFFFD27A),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // زر تسجيل الدخول
                    GestureDetector(
                      onTap: _isLoading ? null : _handleLogin,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9852FF), Color(0xFF6722C4)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9852FF).withValues(alpha: 0.5),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text(
                                  'تسجيل الدخول 🚀',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
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
                  ],
                ),
              ),

              // قسم وسائل التواصل الاجتماعي
              if (_socialProviders.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('أو المتابعة بوسائل التواصل', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  ],
                ),
                const SizedBox(height: 14),

                // صف أيقونات وسائل التواصل المدمج لتوفير المساحة
                SocialLoginRow(
                  providers: _socialProviders,
                  onSuccess: () {
                    if (!mounted) return;
                    context.go('/home');
                  },
                  onError: (err) {
                    setState(() => _errorMessage = err);
                  },
                ),
              ],

              const SizedBox(height: 14),

              // فاصل أو
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('أو', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                ],
              ),

              const SizedBox(height: 14),

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

              const SizedBox(height: 24),

              const Text(
                'بالمتابعة إنت موافق على الشروط وسياسة الخصوصية لتطبيق فرفشة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFFA99BC8), height: 1.6),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
