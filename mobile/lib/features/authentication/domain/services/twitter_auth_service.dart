import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../../core/config/social_auth_config.dart';
import '../../data/models/social_auth_request.dart';
import 'social_auth_service.dart';

class TwitterAuthService implements ISocialAuthProviderService {
  @override
  String get providerName => 'twitter';

  String _createRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _createCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  @override
  Future<SocialAuthRequest?> authenticate() async {
    final codeVerifier = _createRandomString(64);
    final codeChallenge = _createCodeChallenge(codeVerifier);
    final state = _createRandomString(32);

    final url = Uri.https('twitter.com', '/i/oauth2/authorize', {
      'response_type': 'code',
      'client_id': SocialAuthConfig.twitterClientId,
      'redirect_uri': SocialAuthConfig.twitterRedirectUri,
      'scope': 'tweet.read users.read offline.access',
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
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
        throw Exception('فشل التحقق من حالة أمان OAuth (State mismatch).');
      }

      return SocialAuthRequest(
        provider: providerName,
        authorizationCode: code,
        codeVerifier: codeVerifier,
        redirectUri: SocialAuthConfig.twitterRedirectUri,
      );
    } catch (e) {
      if (e.toString().contains('CANCELED')) {
        return null;
      }
      rethrow;
    }
  }
}

