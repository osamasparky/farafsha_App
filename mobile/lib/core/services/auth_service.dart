import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_service.dart';

/// خدمة إدارة حالة تسجيل الدخول والمصادقة (ضيف vs مستخدم مسجل)
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  bool _isLoggedIn = true;
  bool _isGuest = false;
  String _userName = 'أسامة صبري';
  String _userAvatar = 'assets/images/av-ahmed.png';
  String _userPhone = '01012345678';
  String _userEmail = 'osama@farfasha.app';
  String _userDialect = 'مصري';
  int _totalPoints = 4320;

  // اللعبتان المتاحتان للزائر فقط (وفق طلب المستخدم)
  static const List<String> kGuestUnlockedSlugs = [
    'amthal-shaabiya',
    'famous-quotes',
  ];

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String get userName => _userName;
  String get userAvatar => _userAvatar;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  String get userDialect => _userDialect;
  int get totalPoints => _totalPoints;

  /// تهيئة الخدمة وقراءة الحالة المحفوظة
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('auth_is_logged_in') ?? true;
      _isGuest = prefs.getBool('auth_is_guest') ?? false;
      _userName = prefs.getString('auth_user_name') ?? (_isGuest ? 'زائر فرفشة' : 'أسامة صبري');
      _userAvatar = prefs.getString('auth_user_avatar') ?? (_isGuest ? 'assets/images/farfasha_logo.png' : 'assets/images/av-ahmed.png');
      _userPhone = prefs.getString('auth_user_phone') ?? '01012345678';
      _userEmail = prefs.getString('auth_user_email') ?? 'osama@farfasha.app';
      _userDialect = prefs.getString('auth_user_dialect') ?? 'مصري';
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error initializing AuthService: $e');
    }
  }

  /// هل هذه اللعبة مفتوحة للمستخدم الحالي؟
  /// - إذا كان المستخدم مسجلاً (غير ضيف) -> كل الألعاب مفتوحة 100%.
  /// - إذا كان ضيفاً (Guest) -> يفتح له لعبتان فقط (أمثال شعبية وجمل مشهورة).
  bool isGameUnlocked(String slug) {
    if (!_isGuest && _isLoggedIn) {
      return true;
    }
    return kGuestUnlockedSlugs.contains(slug);
  }

  /// الدخول كـ زائر
  Future<void> loginAsGuest() async {
    _isLoggedIn = false;
    _isGuest = true;
    _userName = 'زائر فرفشة';
    _userAvatar = 'assets/images/farfasha_logo.png';
    _totalPoints = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_logged_in', false);
    await prefs.setBool('auth_is_guest', true);
    await prefs.setString('auth_user_name', _userName);
    await prefs.setString('auth_user_avatar', _userAvatar);

    notifyListeners();
  }

  /// تسجيل الدخول كمستخدم مسجل
  Future<void> loginUser({
    required String name,
    String? phone,
    String? email,
    String? avatar,
    String? dialect,
  }) async {
    _isLoggedIn = true;
    _isGuest = false;
    _userName = name.trim().isEmpty ? 'أسامة صبري' : name.trim();
    if (phone != null && phone.trim().isNotEmpty) {
      _userPhone = phone.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      _userEmail = email.trim();
    }
    if (avatar != null && avatar.isNotEmpty) {
      _userAvatar = avatar;
    }
    if (dialect != null && dialect.isNotEmpty) {
      _userDialect = dialect;
    }
    _totalPoints = 4320;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_logged_in', true);
    await prefs.setBool('auth_is_guest', false);
    await prefs.setString('auth_user_name', _userName);
    await prefs.setString('auth_user_phone', _userPhone);
    await prefs.setString('auth_user_email', _userEmail);
    await prefs.setString('auth_user_avatar', _userAvatar);
    await prefs.setString('auth_user_dialect', _userDialect);

    // مزامنة التحديث مع الـ Backend
    try {
      await ApiService.instance.updateProfile(
        name: _userName,
        avatar: _userAvatar,
        phone: _userPhone,
        email: _userEmail,
      );
    } catch (_) {}

    notifyListeners();
  }

  /// تسجيل الدخول المباشر بالبريد الإلكتروني
  Future<bool> loginWithEmail(String email, {String? name}) async {
    final res = await ApiService.instance.loginByEmail(email, name: name);
    final finalName = (name != null && name.trim().isNotEmpty) ? name.trim() : (res?['user']?['name'] ?? email.split('@').first);
    await loginUser(
      name: finalName,
      email: email,
      phone: _userPhone,
      avatar: res?['user']?['avatar'] ?? _userAvatar,
    );
    return true;
  }

  /// تسجيل الدخول عبر وسائل التواصل الاجتماعي (Google, Apple, Facebook)
  Future<bool> loginWithSocial(String provider, {String? email, String? name, String? avatar}) async {
    final res = await ApiService.instance.socialLogin(
      provider: provider,
      email: email,
      name: name,
      avatar: avatar,
    );
    final user = res?['user'] as Map<String, dynamic>?;
    final finalName = user?['name'] ?? name ?? 'مستخدم $provider';
    final finalEmail = user?['email'] ?? email ?? '$provider@farfasha.app';
    final finalAvatar = user?['avatar'] ?? avatar ?? _userAvatar;

    await loginUser(
      name: finalName,
      email: finalEmail,
      phone: _userPhone,
      avatar: finalAvatar,
    );
    return true;
  }

  /// تعديل بيانات الملف الشخصي (الاسم، الأفاتار، الهاتف، البريد)
  Future<void> updateProfile({
    String? name,
    String? avatar,
    String? phone,
    String? email,
    String? dialect,
  }) async {
    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
    }
    if (avatar != null && avatar.isNotEmpty) {
      _userAvatar = avatar;
    }
    if (phone != null && phone.trim().isNotEmpty) {
      _userPhone = phone.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      _userEmail = email.trim();
    }
    if (dialect != null && dialect.isNotEmpty) {
      _userDialect = dialect;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user_name', _userName);
    await prefs.setString('auth_user_avatar', _userAvatar);
    await prefs.setString('auth_user_phone', _userPhone);
    await prefs.setString('auth_user_email', _userEmail);
    await prefs.setString('auth_user_dialect', _userDialect);

    // إرسال التحديث للسيرفر
    try {
      await ApiService.instance.updateProfile(
        name: _userName,
        avatar: _userAvatar,
        phone: _userPhone,
        email: _userEmail,
      );
    } catch (_) {}

    notifyListeners();
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await loginAsGuest();
  }
}

