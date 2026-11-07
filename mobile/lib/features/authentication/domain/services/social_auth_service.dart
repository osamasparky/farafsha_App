import '../../data/models/social_auth_request.dart';

abstract class ISocialAuthProviderService {
  String get providerName;
  Future<SocialAuthRequest?> authenticate();
}

