import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/social_auth_config.dart';
import '../../data/models/social_auth_request.dart';
import 'social_auth_service.dart';

class GoogleAuthService implements ISocialAuthProviderService {
  static bool get _hasConfiguredServerClientId =>
      SocialAuthConfig.googleServerClientId.contains('apps.googleusercontent.com') &&
      !SocialAuthConfig.googleServerClientId.contains('farfashageneric');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    serverClientId: _hasConfiguredServerClientId ? SocialAuthConfig.googleServerClientId : null,
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
        throw Exception('تعذر إتمام تسجيل الدخول بحساب Google على هذا الجهاز حالياً.');
      }

      return SocialAuthRequest(
        provider: providerName,
        idToken: idToken,
        name: account.displayName,
      );
    } on PlatformException catch (e) {
      final msg = '${e.code} ${e.message ?? ''}'.toLowerCase();
      if (msg.contains('canceled') || msg.contains('12501')) {
        return null;
      }
      if (msg.contains('sign_in_failed') || msg.contains('10:')) {
        throw Exception('تسجيل الدخول عبر Google غير مفعّل لهذه النسخة بعد. يمكنك الدخول بالبريد أو رقم الهاتف.');
      }
      throw Exception('تعذر الاتصال بخدمة Google، يرجى المحاولة مرة أخرى.');
    } catch (e) {
      if (e.toString().contains('sign_in_canceled') || e.toString().contains('12501')) {
        return null;
      }
      rethrow;
    }
  }
}

