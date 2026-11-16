import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_service.dart';

/// خدمة إدارة حالة تسجيل الدخول والمصادقة (ضيف vs مستخدم مسجل)
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _userName = '';
  String _userAvatar = 'assets/images/farfasha_logo.webp';
  String _userPhone = '';
  String _userEmail = '';
  String _userDialect = 'مصري';
  String? _authToken;
  int _totalPoints = 0;
  int _wins = 0;
  int _gamesPlayed = 0;

  static const _secureStorage = FlutterSecureStorage();

  Future<void> _persistToken(String? token) async {
    _authToken = token;
    try {
      if (token != null && token.isNotEmpty) {
        await _secureStorage.write(key: 'sanctum_token', value: token);
      } else {
        await _secureStorage.delete(key: 'sanctum_token');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('⚠️ Error persisting token securely: $e');
    }
  }

  // ألعاب الزائر المفتوحة (لعبة الأمثال الشعبية فقط)
  static const List<String> kGuestUnlockedSlugs = [
    'amthal-shaabiya',
    'amthal',
  ];

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String get userName => _userName;
  String get userAvatar => _userAvatar;
  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  String get userDialect => _userDialect;
  String? get authToken => _authToken;
  int get totalPoints => _totalPoints;
  int get wins => _wins;
  int get gamesPlayed => _gamesPlayed;

  /// تهيئة الخدمة وقراءة الحالة المحفوظة واستعادتها
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('auth_is_logged_in') ?? false;
      _isGuest = prefs.getBool('auth_is_guest') ?? false;
      _userName = prefs.getString('auth_user_name') ?? (_isGuest ? 'زائر فرفشة' : '');
      _userAvatar = prefs.getString('auth_user_avatar') ?? (_isGuest ? 'assets/images/farfasha_logo.webp' : 'assets/images/av-ahmed.webp');
      _userPhone = prefs.getString('auth_user_phone') ?? '';
      _userEmail = prefs.getString('auth_user_email') ?? '';
      _userDialect = prefs.getString('auth_user_dialect') ?? 'مصري';
      _totalPoints = prefs.getInt('auth_total_points') ?? 0;
      _wins = prefs.getInt('auth_wins') ?? 0;
      _gamesPlayed = prefs.getInt('auth_games_played') ?? 0;

      // استرجاع التوكن حصرياً من FlutterSecureStorage المشفرة
      try {
        final secToken = await _secureStorage.read(key: 'sanctum_token');
        if (secToken != null && secToken.isNotEmpty) {
          _authToken = secToken;
          _isLoggedIn = true;
          await prefs.setBool('auth_is_logged_in', true);
        } else {
          // هجرة آمنة لمرة واحدة إن وجد توكن في SharedPreferences القديمة
          final oldToken = prefs.getString('auth_token');
          if (oldToken != null && oldToken.isNotEmpty) {
            _authToken = oldToken;
            await _secureStorage.write(key: 'sanctum_token', value: oldToken);
          }
        }
        // حذف التوكن من SharedPreferences لحمايته من أي تسريب
        await prefs.remove('auth_token');
      } catch (_) {}

      // مزامنة التوكن مع ApiService
      _syncWithApiService();

      // إذا كان مسجلاً ولديه توكن، يتم جلب أحدث بيانات في الخلفية للتأكد من صلاحية الجلسة
      if (_isLoggedIn && _authToken != null && _authToken!.isNotEmpty) {
        ApiService.instance.getCurrentUser(_authToken!).then((userData) {
          if (userData != null) {
            _userName = userData['name']?.toString() ?? _userName;
            _userEmail = userData['email']?.toString() ?? _userEmail;
            _userPhone = userData['phone']?.toString() ?? _userPhone;
            _userAvatar = userData['avatar']?.toString() ?? _userAvatar;
            _totalPoints = (userData['total_points'] ?? userData['total_score'] ?? _totalPoints) as int;
            _wins = (userData['wins'] ?? userData['wins_count'] ?? _wins) as int;
            _gamesPlayed = (userData['games_played'] ?? _gamesPlayed) as int;
            _syncWithApiService();
            notifyListeners();
          }
        }).catchError((_) {});
      }

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error initializing AuthService: $e');
    }
  }

  /// مزامنة جلسة المستخدم والمصادقة مع شبكة ApiService
  void _syncWithApiService() {
    if (_authToken != null && _authToken!.isNotEmpty) {
      ApiService.instance.setAuthToken(_authToken);
    }
    if (_userName.isNotEmpty) {
      ApiService.instance.setCurrentUser({
        'name': _userName,
        'email': _userEmail,
        'phone': _userPhone,
        'avatar': _userAvatar,
        'dialect': _userDialect,
        'total_points': _totalPoints,
        'wins': _wins,
        'games_played': _gamesPlayed,
      });
    }
  }

  /// هل هذه اللعبة مفتوحة للمستخدم الحالي؟
  /// - إذا كان المستخدم مسجلاً ومسجل دخوله (غير ضيف) -> كل الألعاب مفتوحة 100%.
  /// - إذا كان ضيفاً (Guest) أو غير مسجل -> لعبة الأمثال الشعبية فقط هي المتاحة.
  bool isGameUnlocked(String slug) {
    if (!_isGuest && _isLoggedIn) {
      return true;
    }
    final normalized = slug.trim().toLowerCase();
    return kGuestUnlockedSlugs.contains(normalized) ||
        normalized == 'amthal' ||
        normalized == 'amthal-shaabiya' ||
        normalized.contains('amthal');
  }

  /// هل نمط اللعب مفتوح للمستخدم الحالي؟
  /// - النمط المحلي ('local') متاح للجميع بما في ذلك الزائر (Guest).
  /// - باقي الأنماط ('lammah', 'online') متاحة فقط للمسجلين داخل المنصة.
  bool isModeUnlocked(String modeSlug) {
    if (!_isGuest && _isLoggedIn) {
      return true;
    }
    return modeSlug.toLowerCase().trim() == 'local';
  }

  /// الدخول كـ زائر
  Future<void> loginAsGuest() async {
    _isLoggedIn = false;
    _isGuest = true;
    _userName = 'زائر فرفشة';
    _userAvatar = 'assets/images/farfasha_logo.webp';
    _totalPoints = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_logged_in', false);
    await prefs.setBool('auth_is_guest', true);
    await prefs.setString('auth_user_name', _userName);
    await prefs.setString('auth_user_avatar', _userAvatar);

    _syncWithApiService();
    notifyListeners();
  }

  /// تسجيل الدخول كمستخدم مسجل
  Future<void> loginUser({
    required String name,
    String? phone,
    String? email,
    String? avatar,
    String? dialect,
    int? totalPoints,
    int? wins,
    int? gamesPlayed,
    String? token,
  }) async {
    _isLoggedIn = true;
    _isGuest = false;
    _userName = name.trim();
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
    if (totalPoints != null) {
      _totalPoints = totalPoints;
    }
    if (wins != null) {
      _wins = wins;
    }
    if (gamesPlayed != null) {
      _gamesPlayed = gamesPlayed;
    }
    if (token != null) {
      _authToken = token;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_logged_in', true);
    await prefs.setBool('auth_is_guest', false);
    await prefs.setString('auth_user_name', _userName);
    await prefs.setString('auth_user_phone', _userPhone);
    await prefs.setString('auth_user_email', _userEmail);
    await prefs.setString('auth_user_avatar', _userAvatar);
    await prefs.setString('auth_user_dialect', _userDialect);
    await prefs.setInt('auth_total_points', _totalPoints);
    await prefs.setInt('auth_wins', _wins);
    await prefs.setInt('auth_games_played', _gamesPlayed);
    await _persistToken(_authToken);

    // مزامنة التحديث مع الـ Backend
    try {
      await ApiService.instance.updateProfile(
        name: _userName,
        avatar: _userAvatar,
        phone: _userPhone,
        email: _userEmail,
        token: _authToken,
      );
    } catch (_) {}

    _syncWithApiService();
    notifyListeners();
  }

  /// تسجيل الدخول بالمعرف (بريد أو هاتف) وكلمة المرور عبر السيرفر
  Future<Map<String, dynamic>> loginWithCredentials({
    required String identifier,
    required String password,
  }) async {
    final res = await ApiService.instance.login(
      identifier: identifier,
      password: password,
    );

    if (res['success'] == true) {
      final user = res['user'] as Map<String, dynamic>?;
      _authToken = res['token']?.toString();
      _isLoggedIn = true;
      _isGuest = false;
      _userName = user?['name'] ?? '';
      _userEmail = user?['email'] ?? '';
      _userPhone = user?['phone'] ?? '';
      _userAvatar = user?['avatar'] ?? 'assets/images/av-ahmed.webp';
      _totalPoints = (user?['total_points'] ?? user?['total_score'] ?? 0) as int;
      _wins = (user?['wins'] ?? user?['wins_count'] ?? 0) as int;
      _gamesPlayed = (user?['games_played'] ?? 0) as int;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setBool('auth_is_guest', false);
      await prefs.setString('auth_user_name', _userName);
      await prefs.setString('auth_user_email', _userEmail);
      await prefs.setString('auth_user_phone', _userPhone);
      await prefs.setString('auth_user_avatar', _userAvatar);
      await prefs.setInt('auth_total_points', _totalPoints);
      await prefs.setInt('auth_wins', _wins);
      await prefs.setInt('auth_games_played', _gamesPlayed);
      await _persistToken(_authToken);

      _syncWithApiService();
      notifyListeners();
      return {'success': true, 'message': res['message']};
    }

    return {'success': false, 'message': res['message']};
  }

  /// إرسال كود OTP لرقم الهاتف (والبريد الإلكتروني إن توفر)
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String? email,
  }) async {
    return await ApiService.instance.sendOtp(phone, email: email);
  }

  /// التحقق من كود OTP وتأكيد رقم الهاتف
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    String? email,
  }) async {
    final res = await ApiService.instance.verifyOtp(phone, code, email: email);
    if (res['success'] == true && res['token'] != null) {
      final user = res['user'] as Map<String, dynamic>?;
      _authToken = res['token']?.toString();
      _isLoggedIn = true;
      _isGuest = false;
      _userName = user?['name'] ?? _userName;
      _userEmail = user?['email'] ?? _userEmail;
      _userPhone = user?['phone'] ?? phone;
      _userAvatar = user?['avatar'] ?? _userAvatar;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setBool('auth_is_guest', false);
      await prefs.setString('auth_user_name', _userName);
      await prefs.setString('auth_user_email', _userEmail);
      await prefs.setString('auth_user_phone', _userPhone);
      await prefs.setString('auth_user_avatar', _userAvatar);
      await _persistToken(_authToken);
      _syncWithApiService();
      notifyListeners();
    }
    return res;
  }

  /// إنشاء حساب جديد في قاعدة البيانات بالاسم والهاتف والبريد وكلمة المرور
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? avatar,
    String? otp,
  }) async {
    final res = await ApiService.instance.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
      avatar: avatar,
      otp: otp,
    );

    if (res['success'] == true) {
      final user = res['user'] as Map<String, dynamic>?;
      _authToken = res['token']?.toString();
      _isLoggedIn = true;
      _isGuest = false;
      _userName = user?['name'] ?? name;
      _userEmail = user?['email'] ?? email;
      _userPhone = user?['phone'] ?? phone;
      _userAvatar = user?['avatar'] ?? (avatar ?? 'assets/images/av-ahmed.webp');
      _totalPoints = 0;
      _wins = 0;
      _gamesPlayed = 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setBool('auth_is_guest', false);
      await prefs.setString('auth_user_name', _userName);
      await prefs.setString('auth_user_email', _userEmail);
      await prefs.setString('auth_user_phone', _userPhone);
      await prefs.setString('auth_user_avatar', _userAvatar);
      await prefs.setInt('auth_total_points', 0);
      await prefs.setInt('auth_wins', 0);
      await prefs.setInt('auth_games_played', 0);
      await _persistToken(_authToken);

      _syncWithApiService();
      notifyListeners();
      return {'success': true, 'message': res['message']};
    }

    return {'success': false, 'message': res['message']};
  }

  /// تسجيل الدخول عبر وسائل التواصل الاجتماعي (Google, Apple, Facebook)
  /// لا يسمح بالدخول إلا للحسابات المصرح لها والمسجلة مسبقاً
  Future<Map<String, dynamic>> loginWithSocial(
    String provider, {
    required String email,
    String? providerId,
  }) async {
    final res = await ApiService.instance.socialLogin(
      provider: provider,
      email: email,
      providerId: providerId,
    );

    if (res['success'] == true) {
      final user = res['user'] as Map<String, dynamic>?;
      _authToken = res['token']?.toString();
      _isLoggedIn = true;
      _isGuest = false;
      _userName = user?['name'] ?? '';
      _userEmail = user?['email'] ?? email;
      _userPhone = user?['phone'] ?? '';
      _userAvatar = user?['avatar'] ?? 'assets/images/av-ahmed.webp';
      _totalPoints = (user?['total_points'] ?? 0) as int;
      _wins = (user?['wins'] ?? 0) as int;
      _gamesPlayed = (user?['games_played'] ?? 0) as int;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setBool('auth_is_guest', false);
      await prefs.setString('auth_user_name', _userName);
      await prefs.setString('auth_user_email', _userEmail);
      await prefs.setString('auth_user_phone', _userPhone);
      await prefs.setString('auth_user_avatar', _userAvatar);
      await prefs.setInt('auth_total_points', _totalPoints);
      await prefs.setInt('auth_wins', _wins);
      await prefs.setInt('auth_games_played', _gamesPlayed);
      await _persistToken(_authToken);

      _syncWithApiService();
      notifyListeners();
      return {'success': true, 'message': res['message'] ?? 'تم تسجيل الدخول بنجاح'};
    }

    return {
      'success': false,
      'message': res['message'] ?? 'تعذر تسجيل الدخول عبر وسيلة التواصل المحددة.',
      'requires_registration': res['requires_registration'] == true,
    };
  }

  /// إنشاء حساب جديد مع وسيلة تواصل اجتماعي (Google, Apple) مع إلزام الاسم ورقم الهاتف
  Future<Map<String, dynamic>> registerWithSocial(
    String provider, {
    required String name,
    required String phone,
    required String email,
    required String password,
    String? avatar,
    String? providerId,
  }) async {
    final res = await ApiService.instance.socialRegister(
      provider: provider,
      name: name,
      phone: phone,
      email: email,
      password: password,
      avatar: avatar,
      providerId: providerId,
    );

    if (res['success'] == true) {
      final user = res['user'] as Map<String, dynamic>?;
      _authToken = res['token']?.toString();
      _isLoggedIn = true;
      _isGuest = false;
      _userName = user?['name'] ?? name;
      _userEmail = user?['email'] ?? email;
      _userPhone = user?['phone'] ?? phone;
      _userAvatar = user?['avatar'] ?? (avatar ?? 'assets/images/av-ahmed.webp');
      _totalPoints = 0;
      _wins = 0;
      _gamesPlayed = 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setBool('auth_is_guest', false);
      await prefs.setString('auth_user_name', _userName);
      await prefs.setString('auth_user_email', _userEmail);
      await prefs.setString('auth_user_phone', _userPhone);
      await prefs.setString('auth_user_avatar', _userAvatar);
      await prefs.setInt('auth_total_points', 0);
      await prefs.setInt('auth_wins', 0);
      await prefs.setInt('auth_games_played', 0);
      await _persistToken(_authToken);

      notifyListeners();
      return {'success': true, 'message': res['message'] ?? 'تم إنشاء الحساب بنجاح'};
    }

    return {
      'success': false,
      'message': res['message'] ?? 'فشل إنشاء الحساب عبر وسيلة التواصل.',
    };
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
        token: _authToken,
      );
    } catch (_) {}

    notifyListeners();
  }

  /// تسجيل الخروج (بدون تحويل كـ زائر، خروج كلي إلى شاشة تسجيل الدخول)
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await ApiService.instance.logout(_authToken);
      }
    } catch (_) {}

    _isLoggedIn = false;
    _isGuest = false;
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    _userAvatar = 'assets/images/farfasha_logo.webp';
    _totalPoints = 0;
    _wins = 0;
    _gamesPlayed = 0;
    await _persistToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_logged_in', false);
    await prefs.setBool('auth_is_guest', false);
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_phone');
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_avatar');
    await prefs.remove('auth_total_points');
    await prefs.remove('auth_wins');
    await prefs.remove('auth_games_played');

    ApiService.instance.setAuthToken(null);
    ApiService.instance.setCurrentUser(null);

    notifyListeners();
  }

  /// تقديم طلب حذف الحساب نهائياً
  Future<Map<String, dynamic>> requestAccountDeletion({String? reason}) async {
    final res = await ApiService.instance.requestAccountDeletion(
      reason: reason,
      token: _authToken,
    );

    if (res['success'] == true) {
      // إبطال وتسجيل الخروج محلياً فوراً
      await logout();
    }

    return res;
  }

  /// تحديث بيانات المستخدم بعد تسجيل الدخول بواسطة وسائل التواصل المعتمدة
  Future<void> updateFromSocialLogin({
    required Map<String, dynamic> user,
    required String token,
    bool isNewUser = false,
  }) async {
    await loginUser(
      name: user['name']?.toString() ?? 'مستخدم فرفشة',
      email: user['email']?.toString(),
      phone: user['phone']?.toString(),
      avatar: user['avatar']?.toString(),
      totalPoints: (user['total_score'] ?? user['points'] ?? 0) as int,
      wins: (user['wins_count'] ?? 0) as int,
      gamesPlayed: (user['games_played'] ?? 0) as int,
      token: token,
    );
  }
}

