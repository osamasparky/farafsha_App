import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // الحقول تبدأ فارغة تماماً بدون بيانات مسبقة
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final List<String> _avatars = [
    'assets/images/av-sara.png',
    'assets/images/av-karim.png',
    'assets/images/av-ahmed.png',
    'assets/images/av-mena.png',
    'assets/images/av-mahmoud.png',
  ];

  int _selectedAvatarIndex = 2; // Default: Ahmed
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // التحقق من صحة الاسم
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال الاسم بالكامل';
    }
    if (value.trim().length < 2) {
      return 'الاسم يجب ألا يقل عن حرفين';
    }
    return null;
  }

  // التحقق من صحة رقم الهاتف
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    final cleanPhone = value.trim().replaceAll(RegExp(r'[\s\-+]'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    }
    if (cleanPhone.length < 10) {
      return 'رقم الهاتف يجب ألا يقل عن 10 أرقام';
    }
    return null;
  }

  // التحقق من صحة البريد الإلكتروني
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة (مثال: name@domain.com)';
    }
    return null;
  }

  // التحقق من كلمة المرور
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
    }
    return null;
  }

  // التحقق من تطابق تأكيد كلمة المرور
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != _passwordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  // إرسال طلب إنشاء الحساب للسيرفر
  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.instance.registerUser(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      avatar: _avatars[_selectedAvatarIndex],
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء الحساب بنجاح! مرحباً بك في فرفشة 🎉'),
          backgroundColor: Color(0xFF35B88E),
        ),
      );
      context.go('/home');
    } else {
      final msg = result['message']?.toString() ?? 'فشل إنشاء الحساب';
      setState(() => _errorMessage = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFD2566A),
        ),
      );
    }
  }

  // التسجيل عبر وسيلة تواصل اجتماعي مع استيفاء الاسم والهاتف والإيميل
  Future<void> _handleSocialRegister(String provider) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل رقم هاتفك لإكمال التسجيل بحساب التواصل'),
          backgroundColor: Color(0xFFD2566A),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await AuthService.instance.loginWithSocial(
      provider,
      name: name.isNotEmpty ? name : 'مستخدم $provider',
      email: email.isNotEmpty ? email : '$provider@farfasha.app',
      phone: phone,
      avatar: _avatars[_selectedAvatarIndex],
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'فشل التسجيل'),
          backgroundColor: const Color(0xFFD2566A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الشريط العلوي مع زر الرجوع
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 12),

              // اختيار الشخصية الرمزية (الأفاتار)
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: LammaColors.gold500, width: 3),
                    boxShadow: [
                      BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.4), blurRadius: 20),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(_avatars[_selectedAvatarIndex], fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // قائمة الأفاتار للاختيار
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_avatars.length, (index) {
                  final isSelected = _selectedAvatarIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatarIndex = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? LammaColors.gold500 : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: AssetImage(_avatars[index]),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // رسالة الخطأ العامة
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
                const SizedBox(height: 14),
              ],

              // 1. الاسم بالكامل
              const Text(
                'الاسم بالكامل',
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
                  controller: _nameController,
                  validator: _validateName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'اكتب اسمك أو لقبك هنا...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFFB98AFF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. رقم الهاتف
              const Text(
                'رقم الهاتف',
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
                  controller: _phoneController,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'مثال: 01012345678',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: Icon(Icons.phone_android_rounded, color: Color(0xFFB98AFF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. البريد الإلكتروني
              const Text(
                'البريد الإلكتروني',
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
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: Color(0xFFB98AFF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. كلمة المرور
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'على الأقل 6 أحرف وأرقام',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFB98AFF)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white54, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 5. تأكيد كلمة المرور
              const Text(
                'تأكيد كلمة المرور',
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
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'أعد إدخال كلمة المرور',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFFB98AFF)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white54, size: 20),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // زر إنشاء الحساب
              GestureDetector(
                onTap: _isLoading ? null : _handleRegister,
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
                            'إنشاء الحساب والبدء 🚀',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // خيارات التواصل الاجتماعي للتسجيل
              if (_socialProviders.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('أو التسجيل عبر', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w600)),
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
                      onTap: _isLoading ? null : () => _handleSocialRegister(code),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isGoogle ? Colors.white : (isApple ? Colors.black : const Color(0xFF1877F2)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isGoogle ? Colors.transparent : Colors.white24, width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isGoogle)
                              const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 28)
                            else if (isApple)
                              const Icon(Icons.apple_rounded, color: Colors.white, size: 22)
                            else
                              const Icon(Icons.facebook_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              isGoogle ? 'التسجيل السريع بحساب Google' : (isApple ? 'التسجيل السريع بحساب Apple' : 'التسجيل بحساب Facebook'),
                              style: TextStyle(
                                color: isGoogle ? const Color(0xFF202124) : Colors.white,
                                fontSize: 14,
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

              const SizedBox(height: 12),

              // العودة لتسجيل الدخول
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'لديك حساب بالفعل؟ ',
                    style: TextStyle(color: Color(0xFFA99BC8), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'تسجيل الدخول',
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
