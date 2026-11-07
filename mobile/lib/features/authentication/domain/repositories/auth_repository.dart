import '../../domain/entities/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> signInWithSocial(String provider);
  Future<bool> logout();
  Future<Map<String, dynamic>?> getCurrentUser();
}

