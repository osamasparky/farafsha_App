import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../data/models/social_auth_request.dart';
import 'social_auth_service.dart';

class FacebookAuthService implements ISocialAuthProviderService {
  @override
  String get providerName => 'facebook';

  @override
  Future<SocialAuthRequest?> authenticate() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      if (result.status == LoginStatus.failed) {
        throw Exception('تعذر تسجيل الدخول عبر Facebook، يرجى المحاولة مرة أخرى.');
      }

      if (result.status == LoginStatus.success && result.accessToken != null) {
        return SocialAuthRequest(
          provider: providerName,
          accessToken: result.accessToken!.tokenString,
        );
      }

      return null;
    } on MissingPluginException {
      throw Exception('تسجيل الدخول عبر Facebook غير مهيأ على هذه النسخة حالياً. يمكنك الدخول بالبريد أو الهاتف.');
    } on PlatformException {
      throw Exception('تعذر الاتصال بتطبيق Facebook حالياً. يمكنك الدخول بالبريد أو الهاتف.');
    }
  }
}

