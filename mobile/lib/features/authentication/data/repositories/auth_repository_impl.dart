import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/apple_auth_service.dart';
import '../../domain/services/facebook_auth_service.dart';
import '../../domain/services/google_auth_service.dart';
import '../../domain/services/linkedin_auth_service.dart';
import '../../domain/services/social_auth_service.dart';
import '../../domain/services/twitter_auth_service.dart';
import '../datasources/social_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SocialAuthDataSource _dataSource = SocialAuthDataSource();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  late final Map<String, ISocialAuthProviderService> _providers = {
    'google': GoogleAuthService(),
    'apple': AppleAuthService(),
    'facebook': FacebookAuthService(),
    'twitter': TwitterAuthService(),
    'linkedin': LinkedInAuthService(),
  };

  @override
  Future<AuthResult> signInWithSocial(String providerKey) async {
    final provider = _providers[providerKey.toLowerCase()];
    if (provider == null) {
      return AuthResult.failure(providerKey, "مزود الخدمة '$providerKey' غير مدعوم حالياً.");
    }

    try {
      // 1. استخراج الرمز الموثق من الـ SDK المخصص
      final request = await provider.authenticate();
      if (request == null) {
        return AuthResult.cancelled(providerKey);
      }

      // 2. إرسال بيانات الاعتماد إلى لارافيل للتحقق الخادمي المستقل
      final response = await _dataSource.sendSocialCredential(request);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final user = data['user'] as Map<String, dynamic>? ?? {};

        // 3. تخزين الرمز بأمان في FlutterSecureStorage
        await _secureStorage.write(key: 'sanctum_token', value: token);

        // 4. تحديث حالة التطبيق العامة في AuthService
        await AuthService.instance.updateFromSocialLogin(
          user: user,
          token: token,
          isNewUser: data['is_new_user'] == true,
        );

        return AuthResult.success(
          provider: providerKey,
          token: token,
          user: user,
          message: response['message']?.toString(),
        );
      } else {
        return AuthResult.failure(
          providerKey,
          response['message']?.toString() ?? 'فشل التحقق من الحساب لدى الخادم.',
        );
      }
    } catch (e) {
      return AuthResult.failure(providerKey, 'حدث خطأ أثناء المصادقة: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  @override
  Future<bool> logout() async {
    await _secureStorage.delete(key: 'sanctum_token');
    await _dataSource.logout();
    await AuthService.instance.logout();
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _dataSource.getMe();
  }
}

