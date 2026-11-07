import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/social_auth_config.dart';
import '../../data/models/social_auth_request.dart';
import 'social_auth_service.dart';

class GoogleAuthService implements ISocialAuthProviderService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: SocialAuthConfig.googleServerClientId.contains('apps.googleusercontent.com')
        ? SocialAuthConfig.googleServerClientId
        : null,
  );

  @override
  String get providerName => 'google';

  @override
  Future<SocialAuthRequest?> authenticate() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null; // إلغاء المستخدم
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('لم يتم استلام رمز Google التعريفي (idToken).');
      }

      return SocialAuthRequest(
        provider: providerName,
        idToken: idToken,
        name: account.displayName,
      );
    } catch (e) {
      // إذا كان الإلغاء ناتجاً عن إغلاق النافذة
      if (e.toString().contains('sign_in_canceled') || e.toString().contains('12501')) {
        return null;
      }
      rethrow;
    }
  }
}

