import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_service.dart';

enum AssetSyncStatus {
  idle,
  checking,
  offlineBlocked,
  syncing,
  completed,
  error,
}

class AssetSyncService extends ChangeNotifier {
  static final AssetSyncService instance = AssetSyncService._internal();
  AssetSyncService._internal();

  static const String _kKeyInitialSynced = 'is_initial_assets_synced_v1';

  AssetSyncStatus _status = AssetSyncStatus.idle;
  double _progress = 0.0;
  String _currentStepMessage = '';
  String? _errorMessage;

  AssetSyncStatus get status => _status;
  double get progress => _progress;
  String get currentStepMessage => _currentStepMessage;
  String? get errorMessage => _errorMessage;
  bool get isInitialSyncCompleted => _status == AssetSyncStatus.completed;

  /// فحص هل تمت المزامنة المبدئية مسبقاً
  Future<bool> hasCompletedInitialSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kKeyInitialSynced) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// فحص توفر الإنترنت الفعلي عبر الاتصال بالسيرفر
  Future<bool> checkInternetConnection() async {
    try {
      final uri = Uri.parse('${ApiService.instance.baseUrl}/banners');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Internet check failed: $e');
      return false;
    }
  }

  void _cacheNetworkImage(String? url) {
    if (url == null || url.isEmpty) return;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        final image = NetworkImage(url);
        image.resolve(ImageConfiguration.empty);
      } catch (_) {}
    }
  }

  /// بدء عملية الفحص والمزامنة الإلزامية لأول تشغيل
  Future<bool> startInitialSync() async {
    final alreadySynced = await hasCompletedInitialSync();
    if (alreadySynced) {
      _status = AssetSyncStatus.completed;
      notifyListeners();
      return true;
    }

    _status = AssetSyncStatus.checking;
    _currentStepMessage = 'جاري التحقق من اتصال الإنترنت... 📶';
    notifyListeners();

    final isOnline = await checkInternetConnection();
    if (!isOnline) {
      _status = AssetSyncStatus.offlineBlocked;
      _currentStepMessage = 'يلزم الاتصال بالإنترنت لأول مرة لتحميل أصول وتصاميم اللعبة';
      notifyListeners();
      return false;
    }

    // بدء تنزيل وحفظ كافة الأصول الأساسية
    _status = AssetSyncStatus.syncing;
    _progress = 0.1;
    _currentStepMessage = 'جاري تحميل الألعاب والتصاميم من السيرفر... 🎮';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. تحميل البنرات
      _progress = 0.2;
      _currentStepMessage = 'جاري مزامنة البنرات والإعلانات... 📢';
      notifyListeners();
      try {
        final banners = await ApiService.instance.getBanners();
        if (banners.isNotEmpty) {
          for (final b in banners.take(3)) {
            _cacheNetworkImage(b['image_url']?.toString());
          }
        }
      } catch (_) {}

      // 2. تحميل أنماط وطرق اللعب
      _progress = 0.35;
      _currentStepMessage = 'جاري مزامنة طرق وأنماط اللعب... 🧩';
      notifyListeners();
      try {
        final modes = await ApiService.instance.getGameplayModes();
        if (modes.isNotEmpty) {
          for (final m in modes) {
            _cacheNetworkImage(m['image_url']?.toString());
          }
        }
      } catch (_) {}

      // 3. تحميل قائمة الألعاب
      _progress = 0.5;
      _currentStepMessage = 'جاري تحميل قائمة ألعاب فرفشة وبطاقاتها... 🃏';
      notifyListeners();
      final games = await ApiService.instance.getGames();

      // 4. تحميل بطاقات كل لعبة على حدة وتخزينها محلياً
      if (games.isNotEmpty) {
        final total = games.length;
        for (int i = 0; i < total; i++) {
          final game = games[i];
          final slug = game['slug']?.toString();
          if (slug != null && slug.isNotEmpty) {
            _progress = 0.5 + ((i + 1) / total) * 0.45;
            _currentStepMessage = 'جاري تجهيز بطاقات: ${game['name'] ?? slug}... (${i + 1}/$total)';
            notifyListeners();

            try {
              final cards = await ApiService.instance.getGameCards(slug);
              if (cards.isNotEmpty) {
                await prefs.setString('offline_cards_$slug', jsonEncode(cards));
              }
            } catch (_) {}

            // تحضير مسبق لصورة كارت اللعبة
            _cacheNetworkImage(game['cover_image_url']?.toString());
          }
        }
      }

      // اكتملت المزامنة بنجاح!
      _progress = 1.0;
      _currentStepMessage = 'تم تجهيز كافة الألعاب بنجاح! مرحباً بك في فرفشة 🎉';
      await prefs.setBool(_kKeyInitialSynced, true);
      _status = AssetSyncStatus.completed;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (e) {
      debugPrint('⚠️ Error during initial asset sync: $e');
      _errorMessage = 'حدث خطأ أثناء تحميل بعض الملفات، يرجى المحاولة مجدداً.';
      _status = AssetSyncStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// إعادة تعيين حالة المزامنة (للتجارب والاختبارات)
  Future<void> resetSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeyInitialSynced);
    _status = AssetSyncStatus.idle;
    _progress = 0.0;
    notifyListeners();
  }
}
