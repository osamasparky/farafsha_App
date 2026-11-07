import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/social_auth_request.dart';

class SocialAuthDataSource {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> sendSocialCredential(SocialAuthRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/social/${request.provider}',
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'استجابة غير متوقعة من الخادم.'};
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        return {
          'success': false,
          'message': data['message'] ?? 'فشل الاتصال بخادم تسجيل الدخول.',
          'errors': data['errors'],
        };
      }
      return {
        'success': false,
        'message': 'تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.',
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع: $e'};
    }
  }

  Future<bool> logout() async {
    try {
      final res = await _dio.post('/api/v1/auth/logout');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await _dio.get('/api/v1/auth/me');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data['data']?['user'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

