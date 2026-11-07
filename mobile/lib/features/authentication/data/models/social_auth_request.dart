class SocialAuthRequest {
  final String provider;
  final String? idToken;
  final String? accessToken;
  final String? authorizationCode;
  final String? codeVerifier;
  final String? redirectUri;
  final String? name;

  const SocialAuthRequest({
    required this.provider,
    this.idToken,
    this.accessToken,
    this.authorizationCode,
    this.codeVerifier,
    this.redirectUri,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      if (idToken != null) 'id_token': idToken,
      if (accessToken != null) 'access_token': accessToken,
      if (authorizationCode != null) 'authorization_code': authorizationCode,
      if (codeVerifier != null) 'code_verifier': codeVerifier,
      if (redirectUri != null) 'redirect_uri': redirectUri,
      if (name != null) 'name': name,
    };
  }
}

