import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  static String? _workingBaseUrl;
  Map<String, dynamic>? _currentUser;
  String? _authToken;

  Map<String, dynamic>? get currentUser => _currentUser;
  void setCurrentUser(Map<String, dynamic>? user) => _currentUser = user;

  String? get authToken => _authToken;
  void setAuthToken(String? token) => _authToken = token;

  // طبقة التخزين المؤقت في الذاكرة لتسريع استجابة الشاشات ومنع تكرار طلبات HTTP
  List<Map<String, dynamic>>? _cachedGames;
  DateTime? _gamesCacheTime;

  List<Map<String, dynamic>>? _cachedBanners;
  DateTime? _bannersCacheTime;

  List<Map<String, dynamic>>? _cachedDialects;
  DateTime? _dialectsCacheTime;

  // على المحاكي في أندرويد يتم استخدام 10.0.2.2، على USB يتم استخدام 127.0.0.1، على الواي فاي 192.168.100.3
  String get baseUrl {
    if (kIsWeb) return 'https://farafsha.com/api';
    if (_workingBaseUrl != null) return _workingBaseUrl!;
    return 'https://farafsha.com/api';
  }

  /// فحص واكتشاف عنوان السيرفر الفعّال تلقائياً (السيرفر السحابي المباشر، USB reverse، أو الشبكة المحلية)
  Future<void> detectWorkingHost() async {
    if (kIsWeb || kReleaseMode) {
      _workingBaseUrl = 'https://farafsha.com/api';
      return;
    }
    const candidates = [
      'https://farafsha.com/api',
      'http://127.0.0.1:8000/api',
      'http://192.168.100.3:8000/api',
      'http://10.0.2.2:8000/api',
    ];
    for (final candidate in candidates) {
      try {
        final res = await http
            .get(Uri.parse('$candidate/banners'))
            .timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 200) {
          _workingBaseUrl = candidate;
          debugPrint('🌐 Connected to backend successfully at: $candidate');
          return;
        }
      } catch (_) {}
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null && _authToken!.isNotEmpty) 'Authorization': 'Bearer $_authToken',
      };

  Map<String, String> _authHeaders(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// جلب بيانات المستخدم المصادق الحالي بواسطة التوكن
  Future<Map<String, dynamic>?> getCurrentUser(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/me'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['user'] is Map) {
          return Map<String, dynamic>.from(data['user']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching current user failed: $e');
    }
    return null;
  }

  /// تسجيل دخول سريع كضيف (Guest) والحصول على Token
  Future<String?> guestLogin({String name = 'لاعب لمّة'}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/guest'),
            headers: _headers,
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['token'] as String?;
      }
    } catch (e) {
      debugPrint('⚠️ Guest login failed: $e');
    }
    return null;
  }

  /// إرسال كود OTP لرقم الهاتف والبريد
  Future<Map<String, dynamic>> sendOtp(String phone, {String? email}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: _headers,
            body: jsonEncode({
              'phone': phone.trim(),
              if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'تم إرسال رمز التحقق بنجاح 📲',
          'debug_otp': data['debug_otp'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'تعذر إرسال رمز التحقق، يرجى مراجعة الرقم.',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Send OTP failed: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر لإرسال رمز التحقق.',
      };
    }
  }

  /// التحقق من رمز OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String code, {String? email}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: _headers,
            body: jsonEncode({
              'phone': phone.trim(),
              'otp': code.trim(),
              'code': code.trim(),
              if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'تم التحقق بنجاح! 🎉',
          'token': data['token'],
          'user': data['user'],
          'is_new_user': data['is_new_user'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'رمز التحقق غير صحيح أو انتهت صلاحيته.',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Verify OTP failed: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر للتحقق من الرمز.',
      };
    }
  }

  /// فحص تحديث التطبيق والتحقق من التحديث الإجباري
  Future<Map<String, dynamic>?> checkAppUpdate({
    required String platform,
    required int buildNumber,
    required String version,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/app-version').replace(
        queryParameters: {
          'platform': platform,
          'build_number': buildNumber.toString(),
          'version': version,
        },
      );
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ checkAppUpdate failed: $e');
    }
    return null;
  }

  /// جلب كافة الألعاب المتاحة من السيرفر (مع تخزين مؤقت فوري و fallback محلي)
  Future<List<Map<String, dynamic>>> getGames({String? category, bool forceRefresh = false}) async {
    // 1. استخدام التخزين المؤقت في الذاكرة لتسريع الشاشة بشكل فوري (0ms)
    if (!forceRefresh && _cachedGames != null && _gamesCacheTime != null) {
      if (DateTime.now().difference(_gamesCacheTime!).inMinutes < 5) {
        if (category != null && category != 'all') {
          return _cachedGames!.where((g) => g['category'] == category).toList();
        }
        return _cachedGames!;
      }
    }

    try {
      final uri = Uri.parse('$baseUrl/games').replace(
        queryParameters: category != null && category != 'all' ? {'category': category} : null,
      );

      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<Map<String, dynamic>> result = [];
        if (data is Map && data['data'] is List) {
          result = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          result = List<Map<String, dynamic>>.from(data);
        }
        if (result.isNotEmpty && (category == null || category == 'all')) {
          _cachedGames = result;
          _gamesCacheTime = DateTime.now();
        }
        return result;
      }
    } catch (e) {
      debugPrint('⚠️ Fetching online games failed ($e). Loading local seed data...');
    }

    if (_cachedGames != null && _cachedGames!.isNotEmpty) {
      return _cachedGames!;
    }
    return _loadSeedGames();
  }

  /// جلب لعبة محددة بالـ slug
  Future<Map<String, dynamic>?> getGameBySlug(String slug) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/games/$slug'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching game by slug failed ($e)');
    }
    return null;
  }

  /// جلب كروت وأسئلة اللعبة من السيرفر (مع fallback محلي)
  Future<List<Map<String, dynamic>>> getGameCards(String slug, {int limit = 50}) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/games/$slug/cards?limit=$limit'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['cards'] != null) {
          return List<Map<String, dynamic>>.from(data['cards']);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching online cards failed ($e). Loading local seed data...');
    }

    return _loadSeedCards(slug);
  }

  /// جلب البنرات الإعلانية والترويجية (مع تخزين مؤقت)
  Future<List<Map<String, dynamic>>> getBanners({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBanners != null && _bannersCacheTime != null) {
      if (DateTime.now().difference(_bannersCacheTime!).inMinutes < 5) {
        return _cachedBanners!;
      }
    }

    try {
      final res = await http.get(Uri.parse('$baseUrl/banners'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is List) {
          final banners = List<Map<String, dynamic>>.from(data['data']);
          _cachedBanners = banners;
          _bannersCacheTime = DateTime.now();
          return banners;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching banners failed: $e');
    }
    return _cachedBanners ?? [];
  }

  /// جلب اللهجات المتاحة من السيرفر (مع تخزين مؤقت)
  Future<List<Map<String, dynamic>>> getDialects({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDialects != null && _dialectsCacheTime != null) {
      if (DateTime.now().difference(_dialectsCacheTime!).inMinutes < 10) {
        return _cachedDialects!;
      }
    }

    try {
      final res = await http.get(Uri.parse('$baseUrl/dialects'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is List) {
          final dialects = List<Map<String, dynamic>>.from(data['data']);
          _cachedDialects = dialects;
          _dialectsCacheTime = DateTime.now();
          return dialects;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching dialects failed: $e');
    }
    return _cachedDialects ?? [];
  }

  /// جلب لوحة الترتيب والمتصدرين حسب الفترة (weekly, monthly, all_time)
  Future<Map<String, dynamic>?> getLeaderboardData({String period = 'weekly'}) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/leaderboard?period=$period'), headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is Map) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching leaderboard failed: $e');
    }
    return null;
  }

  /// جلب قائمة الإشعارات
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching notifications failed: $e');
    }
    return [];
  }

  /// جلب صفحة محتوى ثابتة (سياسة الخصوصية، الشروط، المساعدة)
  Future<Map<String, dynamic>?> getPage(String slug) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/pages/$slug'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is Map) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching page $slug failed: $e');
    }
    return null;
  }

  /// جلب معلومات التواصل والدعم
  Future<Map<String, dynamic>?> getContactInfo() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/contact-info'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is Map) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching contact info failed: $e');
    }
    return null;
  }

  /// جلب الأوسمة النشطة مرتبة من لوحة التحكم مع حالة الفتح
  Future<List<Map<String, dynamic>>> getBadges({int userPoints = 0}) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/badges?user_points=$userPoints'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching badges failed: $e');
    }
    return [
      {
        'id': 1,
        'title': 'ملك الأمثال',
        'description': 'أجب على 10 أمثال شعبية بنجاح دون ارتكاب أي خطأ.',
        'required_points': 300,
        'icon': 'quote',
        'color': '#D2566A',
        'is_unlocked': true,
      },
      {
        'id': 2,
        'title': 'العبقري',
        'description': 'أجب بسرعة فائقة في أول 5 ثوانٍ من السؤال.',
        'required_points': 600,
        'icon': 'bulb',
        'color': '#2F6E7A',
        'is_unlocked': true,
      },
      {
        'id': 3,
        'title': 'سمّيع',
        'description': 'تفوّق في جولات التحديات الموسيقية والغنائية.',
        'required_points': 900,
        'icon': 'music',
        'color': '#B23A72',
        'is_unlocked': true,
      },
      {
        'id': 4,
        'title': 'عاشق السينما',
        'description': 'خمّن أكثر من 15 إيفيه سينمائي بدقة تامة.',
        'required_points': 1200,
        'icon': 'film',
        'color': '#F59E0B',
        'is_unlocked': true,
      },
      {
        'id': 5,
        'title': 'حاوي اللمّة',
        'description': 'حقّق المركز الأول في 10 ألعاب جماعية مختلفة.',
        'required_points': 2000,
        'icon': 'trophy',
        'color': '#A35BFF',
        'is_unlocked': true,
      },
      {
        'id': 6,
        'title': 'أسطورة التحدي',
        'description': 'تجاوز حاجز 3,000 نقطة واعتلِ صدارة لوحة الترتيب.',
        'required_points': 3500,
        'icon': 'star',
        'color': '#FFD27A',
        'is_unlocked': true,
      },
    ];
  }

  /// جلب المستويات والرتب من لوحة التحكم
  Future<List<Map<String, dynamic>>> getLevels() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/levels'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching levels failed: $e');
    }
    return [];
  }

  /// جلب بيانات البروفايل الكاملة وحساب المستوى تلقائياً
  Future<Map<String, dynamic>?> getProfile({bool isGuest = false, String? token}) async {
    try {
      final url = isGuest ? '$baseUrl/profile?guest=true' : '$baseUrl/profile';
      final res = await http.get(Uri.parse(url), headers: _authHeaders(token)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is Map) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching profile failed: $e');
    }
    return null;
  }

  /// جلب مزودي تسجيل الدخول والتواصل الاجتماعي المفعلين من لوحة التحكم
  Future<List<Map<String, dynamic>>> getSocialProviders() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/social-providers'), headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching social providers failed: $e');
    }
    return [
      {'provider': 'google', 'name': 'تسجيل الدخول بحساب Google', 'is_enabled': true, 'icon': 'google'},
      {'provider': 'apple', 'name': 'تسجيل الدخول بحساب Apple', 'is_enabled': true, 'icon': 'apple'},
      {'provider': 'facebook', 'name': 'تسجيل الدخول بحساب Facebook', 'is_enabled': true, 'icon': 'facebook'},
      {'provider': 'twitter', 'name': 'تسجيل الدخول بحساب X (Twitter)', 'is_enabled': true, 'icon': 'twitter'},
      {'provider': 'linkedin', 'name': 'تسجيل الدخول بحساب LinkedIn', 'is_enabled': true, 'icon': 'linkedin'},
    ];
  }

  /// تسجيل الدخول بالمعرف (بريد أو هاتف) وكلمة المرور
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message'] ?? 'تم تسجيل الدخول بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'بيانات الدخول غير صحيحة، يرجى التأكد من البريد أو رقم الهاتف وكلمة المرور.',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Login API error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر. يرجى التحقق من اتصال الإنترنت والمحاولة مجدداً.',
      };
    }
  }

  /// إنشاء حساب جديد في قاعدة البيانات بالاسم والهاتف والبريد وكلمة المرور
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? avatar,
    String? otp,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode({
              'name': name.trim(),
              'phone': phone.trim(),
              'email': email.trim(),
              'password': password,
              if (avatar != null) 'avatar': avatar,
              if (otp != null && otp.isNotEmpty) 'otp': otp.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message'] ?? 'تم إنشاء الحساب بنجاح',
        };
      } else {
        String msg = data['message'] ?? 'فشل إنشاء الحساب، يرجى التأكد من البيانات المدخلة.';
        if (data['errors'] is Map) {
          final errMap = data['errors'] as Map<String, dynamic>;
          final firstKey = errMap.keys.firstOrNull;
          if (firstKey != null && errMap[firstKey] is List && errMap[firstKey].isNotEmpty) {
            msg = errMap[firstKey][0].toString();
          }
        }
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      debugPrint('⚠️ Register API error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر أثناء إنشاء الحساب.',
      };
    }
  }

  /// تسجيل الدخول عبر وسائل التواصل الاجتماعي (Google, Apple, Facebook)
  /// لا يسمح بالدخول إلا للحسابات المصرح لها والمسجلة مسبقاً
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String email,
    String? providerId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/social-login'),
            headers: _headers,
            body: jsonEncode({
              'provider': provider,
              'email': email.trim(),
              if (providerId != null) 'provider_id': providerId,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message'] ?? 'تم تسجيل الدخول بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'تعذر تسجيل الدخول عبر وسيلة التواصل المحددة.',
          'requires_registration': data['requires_registration'] == true,
        };
      }
    } catch (e) {
      debugPrint('⚠️ Social login error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر.',
      };
    }
  }

  /// إنشاء حساب جديد عبر وسائل التواصل الاجتماعي (Google, Apple, Facebook)
  /// يفرض إدخال الاسم ورقم الهاتف والبريد وكلمة المرور
  Future<Map<String, dynamic>> socialRegister({
    required String provider,
    required String name,
    required String phone,
    required String email,
    required String password,
    String? avatar,
    String? providerId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/social-register'),
            headers: _headers,
            body: jsonEncode({
              'provider': provider,
              'name': name.trim(),
              'phone': phone.trim(),
              'email': email.trim(),
              'password': password,
              if (avatar != null) 'avatar': avatar,
              if (providerId != null) 'provider_id': providerId,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message'] ?? 'تم إنشاء الحساب بنجاح',
        };
      } else {
        String msg = data['message'] ?? 'فشل إنشاء الحساب.';
        if (data['errors'] is Map) {
          final errMap = data['errors'] as Map<String, dynamic>;
          final firstKey = errMap.keys.firstOrNull;
          if (firstKey != null && errMap[firstKey] is List && errMap[firstKey].isNotEmpty) {
            msg = errMap[firstKey][0].toString();
          }
        }
        return {
          'success': false,
          'message': msg,
        };
      }
    } catch (e) {
      debugPrint('⚠️ Social register error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر أثناء التسجيل.',
      };
    }
  }

  /// تسجيل الخروج من السيرفر
  Future<void> logout(String? token) async {
    try {
      if (token != null && token.isNotEmpty) {
        await http
            .post(
              Uri.parse('$baseUrl/auth/logout'),
              headers: {
                ..._headers,
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
  }

  /// تسجيل الدخول المباشر بالبريد الإلكتروني
  Future<Map<String, dynamic>?> loginByEmail(String email, {String? name}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login-by-email'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              if (name != null) 'name': name,
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('⚠️ Login by email error: $e');
    }
    return null;
  }

  /// تحديث بيانات البروفايل (الاسم، الأفاتار، الهاتف، البريد)
  Future<Map<String, dynamic>?> updateProfile({
    String? name,
    String? avatar,
    String? phone,
    String? email,
    String? token,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/profile/update'),
            headers: _authHeaders(token),
            body: jsonEncode({
              if (name != null) 'name': name,
              if (avatar != null) 'avatar': avatar,
              if (phone != null) 'phone': phone,
              if (email != null) 'email': email,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['data'] is Map) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Updating profile failed: $e');
    }
    return null;
  }

  /// طلب استعادة كلمة المرور عبر البريد أو الهاتف
  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: _headers,
            body: jsonEncode({'identifier': identifier.trim()}),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'تم إرسال رمز التحقق بنجاح.',
          'type': data['type'] ?? 'email',
          'target': data['target'] ?? identifier,
          if (data['debug_otp'] != null) 'debug_otp': data['debug_otp'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'فشل طلب استعادة كلمة المرور.',
      };
    } catch (e) {
      debugPrint('⚠️ forgotPassword error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر. يرجى التحقق من اتصالك بالإنترنت.',
      };
    }
  }

  /// التحقق من رمز OTP لاستعادة كلمة المرور
  Future<Map<String, dynamic>> verifyResetOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-reset-otp'),
            headers: _headers,
            body: jsonEncode({
              'identifier': identifier.trim(),
              'otp': otp.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'تم التحقق من الرمز بنجاح.',
          'reset_token': data['reset_token'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'رمز التحقق غير صحيح أو انتهت صلاحيته.',
      };
    } catch (e) {
      debugPrint('⚠️ verifyResetOtp error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر.',
      };
    }
  }

  /// تعيين كلمة مرور جديدة باستخدام Reset Token
  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: _headers,
            body: jsonEncode({
              'reset_token': resetToken,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'تم تغيير كلمة المرور بنجاح!',
          'token': data['token'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'فشل تعيين كلمة المرور.',
      };
    } catch (e) {
      debugPrint('⚠️ resetPassword error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر.',
      };
    }
  }

  /// تغيير كلمة المرور للمستخدم المسجل دخوله
  Future<Map<String, dynamic>> changePassword({
    String? currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
    String? token,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/change-password'),
            headers: _authHeaders(token),
            body: jsonEncode({
              if (currentPassword != null && currentPassword.isNotEmpty)
                'current_password': currentPassword,
              'new_password': newPassword,
              'new_password_confirmation': newPasswordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'تم تحديث كلمة المرور بنجاح 🔒',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'فشل تغيير كلمة المرور.',
      };
    } catch (e) {
      debugPrint('⚠️ changePassword error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر.',
      };
    }
  }

  /// طلب حذف الحساب نهائياً من قِبل المستخدم
  Future<Map<String, dynamic>> requestAccountDeletion({
    String? reason,
    String? token,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/request-deletion'),
            headers: _authHeaders(token),
            body: jsonEncode({
              if (reason != null && reason.isNotEmpty) 'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'تم تقديم طلب حذف حسابك بنجاح.',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'تعذر تقديم طلب حذف الحساب.',
      };
    } catch (e) {
      debugPrint('⚠️ requestAccountDeletion error: $e');
      return {
        'success': false,
        'message': 'تعذر الاتصال بالسيرفر، يرجى المحاولة لاحقاً.',
      };
    }
  }

  /// قراءة الألعاب المحلية المرفقة في التطبيق لحالة الـ Offline
  Future<List<Map<String, dynamic>>> _loadSeedGames() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/seed_games.json');
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      debugPrint('⚠️ Error loading offline seed games: $e');
    }
    return [];
  }

  /// قراءة البطاقات المحلية المرفقة في التطبيق لحالة الـ Offline
  Future<List<Map<String, dynamic>>> _loadSeedCards(String slug) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/seed_games.json');
      final List<dynamic> games = jsonDecode(jsonStr);
      final match = games.firstWhere(
        (g) => g['slug'] == slug,
        orElse: () => games.first,
      );
      if (match != null && match['cards'] is List) {
        return List<Map<String, dynamic>>.from(match['cards']);
      }
    } catch (e) {
      debugPrint('⚠️ Error loading offline seed cards: $e');
    }
    return [];
  }

  // ==========================================
  // أنماط وطرق اللعب (Gameplay Modes)
  // ==========================================

  /// جلب أنماط وطرق اللعب من السيرفر مع تخزين مؤقت و fallback محلي
  Future<List<Map<String, dynamic>>> getGameplayModes() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/gameplay-modes'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is List && decoded.isNotEmpty) {
          final list = List<Map<String, dynamic>>.from(decoded);
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_gameplay_modes', jsonEncode(list));
          } catch (_) {}
          return list;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching gameplay modes from server: $e');
    }

    // محاولة القراءة من الكاش
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_gameplay_modes');
      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached);
        if (decoded is List && decoded.isNotEmpty) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (_) {}

    // القائمة الافتراضية المدمجة
    return const [
      {
        'slug': 'local',
        'title': 'لعبة محلية',
        'subtitle': 'على جهاز واحد بالتناوب\nمع أصحابك جنبك (Pass & Play)',
        'badge': 'التناوب الكلاسيكي',
        'image': 'assets/images/local.webp',
        'image_url': null,
        'highlight_color': '#A35BFF',
        'sort_order': 1,
        'is_active': true,
      },
      {
        'slug': 'lammah',
        'title': 'طريقة اللمّة',
        'subtitle': 'واحد معاه الموبايل والميكروفون\nويقرأ الأسئلة للقعدة كلها',
        'badge': 'الأمتع للقعدة 🎉',
        'image': 'assets/images/crowd.webp',
        'image_url': null,
        'highlight_color': '#FF8A4C',
        'sort_order': 2,
        'is_active': true,
      },
      {
        'slug': 'online',
        'title': 'لعبة أونلاين',
        'subtitle': 'العب مع أصحابك\nعن بُعد بغرفة ورمز سري',
        'badge': 'غرف شبكية',
        'image': 'assets/images/online.webp',
        'image_url': null,
        'highlight_color': '#A35BFF',
        'sort_order': 3,
        'is_active': true,
      },
    ];
  }

  // ==========================================
  // غرف اللعب أونلاين (Online Multiplayer Rooms)
  // ==========================================

  /// إنشاء غرفة لعب جديدة (Host)
  Future<Map<String, dynamic>> createRoom({
    required String gameSlug,
    String? hostName,
    int totalRounds = 10,
    int roundDurationSeconds = 20,
    int maxPlayers = 8,
  }) async {
    final resolvedName = (hostName != null && hostName.trim().isNotEmpty)
        ? hostName.trim()
        : (_currentUser?['name'] != null && _currentUser!['name'].toString().trim().isNotEmpty)
            ? _currentUser!['name'].toString().trim()
            : 'لاعب فرفشة';

    final body = {
      'game_slug': gameSlug,
      'host_name': resolvedName,
      'total_rounds': totalRounds,
      'round_duration_seconds': roundDurationSeconds,
      'max_players': maxPlayers,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'فشل إنشاء الغرفة');
    }
  }

  /// انضمام لغرفة عبر الكود المكون من 6 أرقام (Client)
  Future<Map<String, dynamic>> joinRoom({
    required String code,
    String? playerName,
    String? avatar,
  }) async {
    final resolvedPlayerName = (playerName != null && playerName.trim().isNotEmpty)
        ? playerName.trim()
        : (_currentUser?['name'] != null && _currentUser!['name'].toString().trim().isNotEmpty)
            ? _currentUser!['name'].toString().trim()
            : 'ضيف فرفشة';

    final body = {
      'player_name': resolvedPlayerName,
      'avatar': avatar ?? _currentUser?['avatar'],
    };

    final res = await http.post(
      Uri.parse('$baseUrl/rooms/$code/join'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'فشل الانضمام للغرفة');
    }
  }

  /// جلب تفاصيل الغرفة
  Future<Map<String, dynamic>> getRoom(String code) async {
    final res = await http.get(
      Uri.parse('$baseUrl/rooms/$code'),
      headers: _headers,
    ).timeout(const Duration(seconds: 8));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'الغرفة غير موجودة');
    }
  }

  /// المزامنة اللحظية لحالة الغرفة (Smart Polling & State)
  Future<Map<String, dynamic>> getRoomState(String code, {String? token}) async {
    final uri = Uri.parse('$baseUrl/rooms/$code/state').replace(
      queryParameters: token != null ? {'token': token} : null,
    );

    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'فشل جلب حالة الغرفة');
    }
  }

  /// بدء اللعبة من المضيف
  Future<Map<String, dynamic>> startRoom(String code, {String? playerToken}) async {
    final headers = Map<String, String>.from(_headers);
    if (playerToken != null) {
      headers['X-Player-Token'] = playerToken;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/rooms/$code/start'),
      headers: headers,
      body: playerToken != null ? jsonEncode({'player_token': playerToken}) : null,
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'فشل بدء اللعبة');
    }
  }

  /// إرسال إجابة لاعب مع احتساب نقاط السرعة
  Future<Map<String, dynamic>> submitRoomAnswer({
    required String code,
    required String playerToken,
    required String answer,
    double? timeTakenSeconds,
  }) async {
    final body = {
      'player_token': playerToken,
      'answer': answer,
      'time_taken_seconds': timeTakenSeconds ?? 5.0,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/rooms/$code/answer'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 8));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'فشل إرسال الإجابة');
    }
  }

  /// انتهاء وقت السؤال (Timeout)
  Future<Map<String, dynamic>> timeoutRoom(String code, {String? playerToken}) async {
    final headers = Map<String, String>.from(_headers);
    if (playerToken != null) {
      headers['X-Player-Token'] = playerToken;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/rooms/$code/timeout'),
      headers: headers,
      body: playerToken != null ? jsonEncode({'player_token': playerToken}) : null,
    ).timeout(const Duration(seconds: 8));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return data as Map<String, dynamic>;
  }

  /// الانتقال للجولة التالية (Next Question)
  Future<Map<String, dynamic>> nextRoomRound(String code, {String? playerToken}) async {
    final headers = Map<String, String>.from(_headers);
    if (playerToken != null) {
      headers['X-Player-Token'] = playerToken;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/rooms/$code/next-round'),
      headers: headers,
      body: playerToken != null ? jsonEncode({'player_token': playerToken}) : null,
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'فشل الانتقال للجولة التالية');
    }
  }

  /// إنهاء اللعبة بالكامل وحفظ إحصائيات اللاعبين
  Future<Map<String, dynamic>> finishRoom(String code, {String? playerToken}) async {
    final headers = Map<String, String>.from(_headers);
    if (playerToken != null) {
      headers['X-Player-Token'] = playerToken;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/rooms/$code/finish'),
      headers: headers,
      body: playerToken != null ? jsonEncode({'player_token': playerToken}) : null,
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return data as Map<String, dynamic>;
  }

  /// جلب توكن LiveKit WebRTC للغرفة الصوتية
  Future<Map<String, dynamic>> getVoiceToken(String code, {String? token}) async {
    final uri = Uri.parse('$baseUrl/rooms/$code/voice-token').replace(
      queryParameters: token != null ? {'token': token} : null,
    );

    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'فشل استخراج توكن الصوت');
    }
  }

  /// مغادرة الغرفة
  Future<void> leaveRoom(String code, {String? token}) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/rooms/$code/leave'),
        headers: _headers,
        body: jsonEncode({'player_token': token}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}
