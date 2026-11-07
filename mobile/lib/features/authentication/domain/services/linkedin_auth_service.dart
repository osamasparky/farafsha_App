import 'dart:math';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../../core/config/social_auth_config.dart';
import '../../data/models/social_auth_request.dart';
import 'social_auth_service.dart';

class LinkedInAuthService implements ISocialAuthProviderService {
  @override
  String get providerName => 'linkedin';

  String _createRandomState(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Future<SocialAuthRequest?> authenticate() async {
    final state = _createRandomState(32);

    final url = Uri.https('www.linkedin.com', '/oauth/v2/authorization', {
      'response_type': 'code',
      'client_id': SocialAuthConfig.linkedinClientId,
      'redirect_uri': SocialAuthConfig.linkedinRedirectUri,
      'state': state,
      'scope': 'openid profile email',
    }).toString();

    try {
      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'farfasha',
      );

      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final returnedState = uri.queryParameters['state'];

      if (code == null || code.isEmpty) {
        return null;
      }

      if (returnedState != state) {
        throw Exception('فشل التحقق من حالة أمان LinkedIn (State mismatch).');
      }

      return SocialAuthRequest(
        provider: providerName,
        authorizationCode: code,
        redirectUri: SocialAuthConfig.linkedinRedirectUri,
      );
    } catch (e) {
      if (e.toString().contains('CANCELED')) {
        return null;
      }
      rethrow;
    }
  }
}

