import 'dart:io';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/config/social_auth_config.dart';
import '../../data/models/social_auth_request.dart';
import 'social_auth_service.dart';

class AppleAuthService implements ISocialAuthProviderService {
  @override
  String get providerName => 'apple';

  @override
  Future<SocialAuthRequest?> authenticate() async {
    try {
      AuthorizationCredentialAppleID credential;

      if (Platform.isIOS || Platform.isMacOS) {
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
      } else {
        // دعم أندرويد عبر الويب
        credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: SocialAuthConfig.appleServiceId,
            redirectUri: Uri.parse(SocialAuthConfig.appleRedirectUri),
          ),
        );
      }

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('لم يتم استلام رمز الهوية من Apple.');
      }

      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      }

      return SocialAuthRequest(
        provider: providerName,
        idToken: identityToken,
        authorizationCode: credential.authorizationCode,
        name: fullName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

