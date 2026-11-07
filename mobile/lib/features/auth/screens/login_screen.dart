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
  int _selectedTab = 0; // 0: رقم الهاتف, 1: البريد الإلكتروني
  final TextEditingController _phoneController = TextEditingController(text: '01012345678');
  final TextEditingController _emailController = TextEditingController(text: 'osama@farfasha.app');
  final String _countryCode = '+20';
  bool _isLoading = false;
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
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل رقم الموبايل')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await AuthService.instance.loginUser(
      name: 'أسامة صبري',
      phone: phone,
      avatar: 'assets/images/av-ahmed.png',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/home');
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل بريد إلكتروني صحيح')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await AuthService.instance.loginWithEmail(email, name: 'أسامة صبري');
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/home');
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    await AuthService.instance.loginWithSocial(provider);
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/home');
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
              'أهلاً بيك في فرفشة! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'سجّل عشان تفرفش وتحفظ نقاطك وإنجازاتك وتفتح جميع الألعاب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD9CCF2),
              ),
            ),

            const SizedBox(height: 24),

            // تبويب الاختيار بين رقم الموبايل أو البريد الإلكتروني
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LammaColors.cardBorder, width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? LammaColors.violet500 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: LammaColors.violet500.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                size: 18,
                                color: _selectedTab == 0 ? Colors.white : const Color(0xFFA99BC8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'رقم الهاتف',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedTab == 0 ? Colors.white : const Color(0xFFA99BC8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? LammaColors.violet500 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: LammaColors.violet500.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.alternate_email_rounded,
                                size: 18,
                                color: _selectedTab == 1 ? Colors.white : const Color(0xFFA99BC8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'البريد الإلكتروني',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedTab == 1 ? Colors.white : const Color(0xFFA99BC8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // محتوى التبويب المختار
            if (_selectedTab == 0) ...[
              const Text(
                'رقم الموبايل',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEADFFF)),
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    Container(
                      height: 54,
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
                        height: 54,
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
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                          decoration: const InputDecoration(
                            hintText: '01X XXXX XXXX',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _isLoading ? null : _handlePhoneLogin,
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
                            'تسجيل الدخول برقم الموبايل 🚀',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'البريد الإلكتروني',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEADFFF)),
              ),
              const SizedBox(height: 8),
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LammaColors.violet400, width: 2),
                  boxShadow: [
                    BoxShadow(color: LammaColors.violet500.withValues(alpha: 0.2), blurRadius: 10),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFB98AFF)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _isLoading ? null : _handleEmailLogin,
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
                            'تسجيل الدخول بالبريد الإلكتروني 🚀',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
            ],

            // قسم وسائل التواصل الاجتماعي (المتحكم بها من لوحة التحكم)
            if (_socialProviders.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('أو المتابعة عبر', style: TextStyle(color: Color(0xFFA99BC8), fontSize: 13, fontWeight: FontWeight.w600)),
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

            // زر الدخول كـ زائر (بالمسمى المطلوب بدقة: "الدخول كزائر")
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
    );
  }
}
