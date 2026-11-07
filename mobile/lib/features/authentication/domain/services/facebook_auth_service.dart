import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../data/models/social_auth_request.dart';
import 'social_auth_service.dart';

class FacebookAuthService implements ISocialAuthProviderService {
  @override
  String get providerName => 'facebook';

  @override
  Future<SocialAuthRequest?> authenticate() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
    );

    if (result.status == LoginStatus.cancelled) {
      return null;
    }

    if (result.status == LoginStatus.failed) {
      throw Exception(result.message ?? 'فشل تسجيل الدخول بحساب Facebook.');
    }

    if (result.status == LoginStatus.success && result.accessToken != null) {
      return SocialAuthRequest(
        provider: providerName,
        accessToken: result.accessToken!.tokenString,
      );
    }

    return null;
  }
}

