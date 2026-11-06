import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  // مع adb reverse tcp:8000 tcp:8000 يعمل localhost على الهاتف المتصل بالـ USB مباشرة
  String get baseUrl => 'http://localhost:8000/api';

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// تسجيل دخول كضيف والحصول على توكن فوري
  Future<Map<String, dynamic>?> loginAsGuest({String? name, String? avatar}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/guest'),
            headers: _headers,
            body: jsonEncode({
              'name': name ?? 'ضيف لمّة',
              'avatar': avatar ?? 'av-ahmed.png',
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _authToken = data['token'] as String?;
        return data;
      }
    } catch (e) {
      debugPrint('⚠️ Guest login offline: $e');
    }
    return null;
  }

  /// جلب بطاقات لعبة محددة مع إمكانية العمل بلا إنترنت (Offline fallback)
  Future<List<Map<String, dynamic>>> getGameCards(String slug) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/games/$slug/cards'), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Fetching online cards failed ($e). Loading local seed data...');
    }

    // بديل محلي دون إنترنت من ملف assets/data/seed_games.json
    return _loadSeedCards(slug);
  }

  /// إنشاء غرفة ألعاب أونلاين جديدة
  Future<Map<String, dynamic>?> createRoom(String gameSlug) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/rooms'),
            headers: _headers,
            body: jsonEncode({'game_slug': gameSlug}),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ Create room failed: $e');
    }
    return null;
  }

  /// الانضمام إلى غرفة موجودة برمزها
  Future<Map<String, dynamic>?> joinRoom(String roomCode, String playerName) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/rooms/$roomCode/join'),
            headers: _headers,
            body: jsonEncode({'player_name': playerName}),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('⚠️ Join room failed: $e');
    }
    return null;
  }

  /// جلب لوحة الترتيب حسب الفترة
  Future<List<Map<String, dynamic>>> getLeaderboard({String period = 'week'}) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/leaderboard?period=$period'), headers: _headers)
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('⚠️ Leaderboard fetch failed: $e');
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
      if (match != null && match['cards'] != null) {
        return List<Map<String, dynamic>>.from(match['cards']);
      }
    } catch (e) {
      debugPrint('⚠️ Error loading offline seed cards: $e');
    }
    return [];
  }
}
