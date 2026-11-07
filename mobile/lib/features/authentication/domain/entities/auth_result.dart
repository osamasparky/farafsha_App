class AuthResult {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? message;
  final bool isCancelled;
  final String provider;

  const AuthResult({
    required this.success,
    required this.provider,
    this.token,
    this.user,
    this.message,
    this.isCancelled = false,
  });

  factory AuthResult.cancelled(String provider) {
    return AuthResult(
      success: false,
      provider: provider,
      isCancelled: true,
      message: 'تم إلغاء تسجيل الدخول.',
    );
  }

  factory AuthResult.failure(String provider, String message) {
    return AuthResult(
      success: false,
      provider: provider,
      message: message,
    );
  }

  factory AuthResult.success({
    required String provider,
    required String token,
    required Map<String, dynamic> user,
    String? message,
  }) {
    return AuthResult(
      success: true,
      provider: provider,
      token: token,
      user: user,
      message: message ?? 'تم تسجيل الدخول بنجاح 🎉',
    );
  }
}

