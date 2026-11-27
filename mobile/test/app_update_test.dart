import 'package:flutter_test/flutter_test.dart';
import 'package:lammah/core/services/app_update_service.dart';

void main() {
  group('AppUpdateInfo Tests', () {
    test('Correctly identifies force update when current build is less than min build', () {
      final json = {
        'is_update_available': true,
        'is_force_update': true,
        'min_build_number': 8,
        'latest_version': '1.0.0+8',
        'title': 'تحديث إجباري',
        'message': 'يرجى التحديث الآن',
        'store_url': 'https://play.google.com/store/apps/details?id=com.farafsha.app',
        'direct_download_url': 'https://farafsha.com/farafsha.aab',
      };

      final info = AppUpdateInfo.fromMap(
        json,
        currentVersion: '1.0.0',
        currentBuildNumber: 7,
      );

      expect(info.isForceUpdate, true);
      expect(info.isUpdateAvailable, true);
      expect(info.currentBuildNumber, 7);
      expect(info.minBuildNumber, 8);
      expect(info.storeUrl, contains('com.farafsha.app'));
    });

    test('Correctly identifies no force update when current build meets min build', () {
      final json = {
        'is_update_available': false,
        'is_force_update': false,
        'min_build_number': 8,
        'latest_version': '1.0.0+8',
      };

      final info = AppUpdateInfo.fromMap(
        json,
        currentVersion: '1.0.0',
        currentBuildNumber: 8,
      );

      expect(info.isForceUpdate, false);
      expect(info.isUpdateAvailable, false);
      expect(info.currentBuildNumber, 8);
    });

    test('Detects newer store semantic versions accurately', () {
      expect(AppUpdateService.isStoreVersionNewer('1.0.1', '1.0.0'), true);
      expect(AppUpdateService.isStoreVersionNewer('1.1.0', '1.0.9'), true);
      expect(AppUpdateService.isStoreVersionNewer('2.0.0', '1.9.9'), true);
      expect(AppUpdateService.isStoreVersionNewer('1.0.0', '1.0.0'), false);
      expect(AppUpdateService.isStoreVersionNewer('1.0.0', '1.0.1'), false);
    });
  });
}
