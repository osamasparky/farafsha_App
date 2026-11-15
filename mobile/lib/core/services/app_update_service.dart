import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_service.dart';

/// ثوابت تعريف إصدار التطبيق (يتم تحديثها عند كل إطلاق)
class AppConfig {
  static const String appName = 'فرفشة';
  static const String packageName = 'com.farafsha.app';
  static const String version = '1.0.0';
  static const int buildNumber = 9;
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
      storeUrl: map['store_url']?.toString() ??
          'https://play.google.com/store/apps/details?id=com.farafsha.app',
      directDownloadUrl: map['direct_download_url']?.toString() ??
          'https://farafsha.com/farafsha.aab',
    );
  }
}

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  AppUpdateService._internal();

  AppUpdateInfo? _currentUpdateInfo;
  AppUpdateInfo? get currentUpdateInfo => _currentUpdateInfo;

  bool get isForceUpdateRequired => _currentUpdateInfo?.isForceUpdate ?? false;

  int get currentBuildNumber => AppConfig.buildNumber;
  String get currentVersion => AppConfig.version;

  /// فحص توفر تحديث من السيرفر
  Future<AppUpdateInfo?> checkUpdate() async {
    try {
      const buildNum = AppConfig.buildNumber;
      const ver = AppConfig.version;
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');

      final data = await ApiService.instance.checkAppUpdate(
        platform: platform,
        buildNumber: buildNum,
        version: ver,
      );

      if (data != null) {
        final updateInfo = AppUpdateInfo.fromMap(
          data,
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

      final storeUrlStr = _currentUpdateInfo?.storeUrl ??
          'https://play.google.com/store/apps/details?id=com.farafsha.app';

      if (!kIsWeb && Platform.isAndroid) {
        // محاولة الفتح المباشر داخل تطبيق متجر Google Play
        final marketUri = Uri.parse('market://details?id=com.farafsha.app');
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
