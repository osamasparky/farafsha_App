class SocialAuthConfig {
  // Google
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '752943156824-farfashageneric.apps.googleusercontent.com',
  );

  // Apple
  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'com.lammah.app.client',
  );
  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'https://farfasha.app/api/v1/auth/social/apple/callback',
  );

  // Facebook
  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: '123456789012345',
  );

  // X (Twitter)
  static const String twitterClientId = String.fromEnvironment(
    'TWITTER_CLIENT_ID',
    defaultValue: 'TWITTER_OAUTH2_CLIENT_ID',
  );
  static const String twitterRedirectUri = 'farfasha://oauth-callback';

  // LinkedIn
  static const String linkedinClientId = String.fromEnvironment(
    'LINKEDIN_CLIENT_ID',
    defaultValue: 'LINKEDIN_OAUTH2_CLIENT_ID',
  );
  static const String linkedinRedirectUri = 'farfasha://oauth-callback';
}

