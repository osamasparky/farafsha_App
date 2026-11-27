import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../network/api_service.dart';

/// ثوابت تعريف إصدار التطبيق (يتم تحديثها عند كل إطلاق)
class AppConfig {
  static const String appName = 'فرفشة';
  static const String androidPackageName = 'farafsha.com';
  static const String iosBundleId = 'com.farafsha.app';
  static const String packageName = androidPackageName;
  static const String version = '1.0.0';
  static const int buildNumber = 13;
}

class AppUpdateInfo {
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final int currentBuildNumber;
  final int minBuildNumber;
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String message;
  final String storeUrl;
  final String directDownloadUrl;

  const AppUpdateInfo({
    required this.isUpdateAvailable,
    required this.isForceUpdate,
    required this.currentBuildNumber,
    required this.minBuildNumber,
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.message,
    required this.storeUrl,
    required this.directDownloadUrl,
  });

  factory AppUpdateInfo.fromMap(
    Map<String, dynamic> map, {
    required String currentVersion,
    required int currentBuildNumber,
  }) {
    final defaultStoreUrl = (!kIsWeb && Platform.isIOS)
        ? 'https://apps.apple.com/app/id6743250615'
        : 'https://play.google.com/store/apps/details?id=${AppConfig.androidPackageName}';

    return AppUpdateInfo(
      isUpdateAvailable: map['is_update_available'] == true,
      isForceUpdate: map['is_force_update'] == true,
      currentBuildNumber: currentBuildNumber,
      minBuildNumber: (map['min_build_number'] as num?)?.toInt() ?? 0,
      currentVersion: currentVersion,
      latestVersion: map['latest_version']?.toString() ?? currentVersion,
      title: map['title']?.toString() ?? 'تحديث إجباري جديد متوفر 🚀',
      message: map['message']?.toString() ??
          'يتوفر إصدار جديد من تطبيق فرفشة بميزات وتحسينات جديدة. يرجى التحديث الآن للمتابعة!',
      storeUrl: map['store_url']?.toString() ?? defaultStoreUrl,
      directDownloadUrl: map['direct_download_url']?.toString() ??
          'https://farafsha.com/farafsha.aab',
    );
  }
}

class _StoreVersionResult {
  final String version;
  final String storeUrl;
  const _StoreVersionResult({required this.version, required this.storeUrl});
}

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  AppUpdateService._internal();

  AppUpdateInfo? _currentUpdateInfo;
  AppUpdateInfo? get currentUpdateInfo => _currentUpdateInfo;

  bool get isForceUpdateRequired => _currentUpdateInfo?.isForceUpdate ?? false;

  int get currentBuildNumber => AppConfig.buildNumber;
  String get currentVersion => AppConfig.version;

  /// مقارنة رقمي الإصدار (مثل 1.0.2 مقابل 1.0.0) لتحديد هل إصدار المتجر أحدث
  static bool isStoreVersionNewer(String storeVersion, String currentVersion) {
    List<int> parseParts(String v) {
      final clean = v.split('+').first.trim();
      return clean
          .split('.')
          .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
    }

    final storeParts = parseParts(storeVersion);
    final currParts = parseParts(currentVersion);
    final maxLen = storeParts.length > currParts.length ? storeParts.length : currParts.length;

    for (int i = 0; i < maxLen; i++) {
      final s = i < storeParts.length ? storeParts[i] : 0;
      final c = i < currParts.length ? currParts[i] : 0;
      if (s > c) return true;
      if (s < c) return false;
    }
    return false;
  }

  /// فحص آخر إصدار من متجر Apple App Store تلقائياً عبر iTunes Lookup API
  Future<_StoreVersionResult?> _checkAppleAppStore() async {
    final urls = [
      'https://itunes.apple.com/lookup?bundleId=${AppConfig.iosBundleId}&country=eg',
      'https://itunes.apple.com/lookup?bundleId=${AppConfig.iosBundleId}',
    ];

    for (final url in urls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          if (json is Map && json['results'] is List && (json['results'] as List).isNotEmpty) {
            final app = (json['results'] as List).first as Map;
            final version = app['version']?.toString().trim() ?? '';
            final trackUrl = app['trackViewUrl']?.toString().trim() ?? '';
            if (version.isNotEmpty) {
              return _StoreVersionResult(
                version: version,
                storeUrl: trackUrl.isNotEmpty
                    ? trackUrl
                    : 'https://apps.apple.com/search?term=${Uri.encodeComponent(AppConfig.appName)}',
              );
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Apple Store lookup error: $e');
      }
    }
    return null;
  }

  /// فحص آخر إصدار من متجر Google Play تلقائياً
  Future<_StoreVersionResult?> _checkGooglePlayStore() async {
    const url = 'https://play.google.com/store/apps/details?id=${AppConfig.androidPackageName}&hl=en&gl=US';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = res.body;
        // استخراج رقم الإصدار الحالي من صفحة Google Play
        final match = RegExp(r'\[\[\["(\d+\.\d+(?:\.\d+)?)"\]\]').firstMatch(body) ??
            RegExp(r'Current Version.*?>(\d+\.\d+(?:\.\d+)?)<', dotAll: true).firstMatch(body);
        final version = match?.group(1)?.trim() ?? '';
        if (version.isNotEmpty) {
          return _StoreVersionResult(
            version: version,
            storeUrl: url,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Google Play lookup error: $e');
    }
    return null;
  }

  /// فحص توفر تحديث من السيرفر ومن المتجر (Apple / Google) تلقائياً وإجبار التحديث عند وجود إصدار أحدث
  Future<AppUpdateInfo?> checkUpdate() async {
    try {
      const buildNum = AppConfig.buildNumber;
      const ver = AppConfig.version;
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

      final backendFuture = ApiService.instance.checkAppUpdate(
        platform: platform,
        buildNumber: buildNum,
        version: ver,
      );

      final Future<_StoreVersionResult?> storeFuture = kIsWeb
          ? Future.value(null)
          : (Platform.isIOS ? _checkAppleAppStore() : _checkGooglePlayStore());

      final backendData = await backendFuture;
      final storeResult = await storeFuture;

      final bool storeHasNewer = storeResult != null && isStoreVersionNewer(storeResult.version, ver);

      if (storeHasNewer) {
        final mergedMap = <String, dynamic>{
          if (backendData != null) ...backendData,
          'is_update_available': true,
          'is_force_update': true,
          'latest_version': storeResult.version,
          'store_url': storeResult.storeUrl,
          'title': backendData?['title'] ?? 'تحديث إجباري جديد متوفر 🚀',
          'message': backendData?['message'] ??
              'يتوفر إصدار جديد (${storeResult.version}) على المتجر. يرجى تحديث التطبيق الآن للاستمرار في اللعب!',
        };
        final updateInfo = AppUpdateInfo.fromMap(
          mergedMap,
          currentVersion: ver,
          currentBuildNumber: buildNum,
        );
        _currentUpdateInfo = updateInfo;
        return updateInfo;
      }

      if (backendData != null) {
        final updateInfo = AppUpdateInfo.fromMap(
          backendData,
          currentVersion: ver,
          currentBuildNumber: buildNum,
        );
        _currentUpdateInfo = updateInfo;
        return updateInfo;
      }
    } catch (e) {
      debugPrint('⚠️ checkUpdate error: $e');
    }
    return null;
  }

  /// فتح المتجر أو رابط التحديث تلقائياً
  Future<bool> launchStoreOrUpdate({bool preferDirectDownload = false}) async {
    try {
      if (preferDirectDownload &&
          _currentUpdateInfo != null &&
          _currentUpdateInfo!.directDownloadUrl.isNotEmpty) {
        final directUri = Uri.parse(_currentUpdateInfo!.directDownloadUrl);
        if (await canLaunchUrl(directUri)) {
          return await launchUrl(directUri, mode: LaunchMode.externalApplication);
        }
      }

      final defaultUrl = (!kIsWeb && Platform.isIOS)
          ? 'https://apps.apple.com/search?term=${Uri.encodeComponent(AppConfig.appName)}'
          : 'https://play.google.com/store/apps/details?id=${AppConfig.androidPackageName}';

      final storeUrlStr = (_currentUpdateInfo?.storeUrl.isNotEmpty == true)
          ? _currentUpdateInfo!.storeUrl
          : defaultUrl;

      if (!kIsWeb && Platform.isAndroid) {
        // محاولة الفتح المباشر داخل تطبيق متجر Google Play
        final marketUri = Uri.parse('market://details?id=${AppConfig.androidPackageName}');
        if (await canLaunchUrl(marketUri)) {
          final launched = await launchUrl(marketUri, mode: LaunchMode.externalApplication);
          if (launched) return true;
        }
      }

      final storeUri = Uri.parse(storeUrlStr);
      if (await canLaunchUrl(storeUri)) {
        return await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ Could not launch store URL: $e');
    }
    return false;
  }

  /// الخروج من التطبيق تماماً عند رفض التحديث
  void exitApp() {
    SystemNavigator.pop();
  }
}
