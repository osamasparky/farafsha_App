import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/lamma_theme.dart';
import '../../../core/widgets/lamma_scaffold.dart';
import '../../authentication/presentation/widgets/social_login_row.dart';

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

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final avatar = _avatars[_selectedAvatarIndex];

    setState(() => _isLoading = true);

    // إرسال رمز OTP أولاً لرقم هاتفك عبر الواتساب (والبريد إن وجد)
    final otpRes = await AuthService.instance.sendOtp(
      phone: phone,
      email: email,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final success = otpRes['success'] == true;
    final msg = otpRes['message']?.toString() ??
        (success
            ? 'تم إرسال رمز التحقق لهاتفك عبر واتساب بنجاح 📲'
            : 'يرجى إدخال رمز التحقق لتأكيد الحساب');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF35B88E) : const Color(0xFF8A56D2),
        duration: const Duration(seconds: 3),
      ),
    );

    // التوجيه المباشر والفوري لشاشة إدخال رمز التحقق OTP
    context.push(
      '/otp',
      extra: {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'avatar': avatar,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LammaScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 14.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // زر الرجوع وشعار الصفحة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 22),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 10),

              // كارت الصورة الرمزية المختارة وقائمة الشخصيات
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD27A), width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8F4BF0).withValues(alpha: 0.6),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _avatars[_selectedAvatarIndex],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // دائرة اختيار الأفاتار (بنين وبنات)
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_avatars.length, (idx) {
                      final isSelected = _selectedAvatarIndex == idx;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatarIndex = idx),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFFD27A) : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFD27A).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : [],
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(_avatars[idx]),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // كارت البيانات الزجاجي الفاخر
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
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.5), width: 1.4),
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
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.5), width: 1.4),
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
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.5), width: 1.4),
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
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.5), width: 1.4),
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
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8F4BF0).withValues(alpha: 0.5), width: 1.4),
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

                    const SizedBox(height: 22),

                    // زر إنشاء الحساب والبدء
                    GestureDetector(
                      onTap: _isLoading ? null : _handleRegister,
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
                                  'إنشاء الحساب والبدء 🚀',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // خيارات التواصل الاجتماعي للتسجيل
              if (_socialProviders.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('أو التسجيل عبر وسائل التواصل', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  ],
                ),
                const SizedBox(height: 14),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
