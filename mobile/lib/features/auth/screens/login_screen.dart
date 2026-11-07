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

  /// تسجيل الدخول عبر وسائل التواصل الاجتماعي مع التحقق الصارم من وجود الحساب وتصريحه
  void _openSocialLoginModal(String provider) {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isModalLoading = false;
    String? modalError;
    final isGoogle = provider == 'google';
    final providerTitle = isGoogle ? 'Google' : (provider == 'apple' ? 'Apple' : 'Facebook');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF24104B), Color(0xFF14072B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFFB98AFF), width: 2)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isGoogle)
                          const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 36)
                        else
                          const Icon(Icons.apple_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'تسجيل الدخول عبر $providerTitle',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'أدخل البريد الإلكتروني المرتبط بحسابك للتحقق من الصلاحية والمتابعة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFFCFC6E4), height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    if (modalError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD2566A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD2566A), width: 1.2),
                        ),
                        child: Text(
                          modalError!,
                          style: const TextStyle(color: Color(0xFFFFB3B8), fontSize: 13, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFB98AFF), width: 1.4),
                      ),
                      child: TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(val.trim())) {
                            return 'صيغة البريد الإلكتروني غير صحيحة';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'example@gmail.com',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFB98AFF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: isModalLoading
                          ? null
                          : () async {
                              setModalState(() => modalError = null);
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isModalLoading = true);

                              final res = await AuthService.instance.loginWithSocial(
                                provider,
                                email: emailCtrl.text.trim(),
                              );

                              if (!modalContext.mounted) return;
                              setModalState(() => isModalLoading = false);

                              if (res['success'] == true) {
                                Navigator.pop(modalContext);
                                if (!mounted) return;
                                context.go('/home');
                              } else {
                                setModalState(() {
                                  modalError = res['message']?.toString() ?? 'فشل التحقق من الحساب.';
                                });
                              }
                            },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8F4BF0), Color(0xFF6A24C9)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF8F4BF0).withValues(alpha: 0.45), blurRadius: 12),
                          ],
                        ),
                        child: Center(
                          child: isModalLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'متابعة والتحقق من الحساب 🚀',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(modalContext);
                        context.push('/register');
                      },
                      child: const Text(
                        'ليس لديك حساب مسجل؟ إنشاء حساب جديد الآن',
                        style: TextStyle(color: Color(0xFFFFD27A), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

                    const SizedBox(height: 22),

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
                      child: Text('أو الدخول عبر', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  ],
                ),
                const SizedBox(height: 14),
                ..._socialProviders.map((provider) {
                  final code = provider['provider']?.toString() ?? '';
                  final isGoogle = code == 'google';
                  final isApple = code == 'apple';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => _openSocialLoginModal(code),
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
                              const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 32)
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
