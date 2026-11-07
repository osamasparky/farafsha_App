import 'package:flutter_test/flutter_test.dart';
import 'package:lammah/features/authentication/data/models/social_auth_request.dart';
import 'package:lammah/features/authentication/domain/entities/auth_result.dart';

void main() {
  group('Social Authentication Models & Entities', () {
    test('SocialAuthRequest serializes correctly with Google id_token', () {
      const request = SocialAuthRequest(
        provider: 'google',
        idToken: 'mock-google-id-token',
        name: 'أسامة صبري',
      );

      final json = request.toJson();
      expect(json['provider'], 'google');
      expect(json['id_token'], 'mock-google-id-token');
      expect(json['name'], 'أسامة صبري');
      expect(json.containsKey('access_token'), isFalse);
    });

    test('SocialAuthRequest serializes correctly with Twitter PKCE authorization_code', () {
      const request = SocialAuthRequest(
        provider: 'twitter',
        authorizationCode: 'auth-code-xyz',
        codeVerifier: 'verifier-12345',
        redirectUri: 'farfasha://oauth-callback',
      );

      final json = request.toJson();
      expect(json['provider'], 'twitter');
      expect(json['authorization_code'], 'auth-code-xyz');
      expect(json['code_verifier'], 'verifier-12345');
      expect(json['redirect_uri'], 'farfasha://oauth-callback');
    });

    test('AuthResult.cancelled sets isCancelled and appropriate message', () {
      final result = AuthResult.cancelled('apple');

      expect(result.success, isFalse);
      expect(result.isCancelled, isTrue);
      expect(result.provider, 'apple');
      expect(result.message, contains('إلغاء'));
    });

    test('AuthResult.success holds token and user data', () {
      final result = AuthResult.success(
        provider: 'google',
        token: 'sanctum-token-abc',
        user: {'id': 1, 'name': 'سارة'},
      );

      expect(result.success, isTrue);
      expect(result.token, 'sanctum-token-abc');
      expect(result.user?['name'], 'سارة');
    });
  });
}

