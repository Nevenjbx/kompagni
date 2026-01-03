import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/environment_config.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvironmentConfig.apiUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<void> syncUser({
    required String role,
    String? name,
    String? phoneNumber,
    Map<String, dynamic>? providerProfile,
    List<String>? tags,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.post(
        '/users/sync',
        data: {
          'role': role,
          'name': name,
          'phoneNumber': phoneNumber,
          'providerProfile': providerProfile != null 
              ? {...providerProfile, 'tags': tags}
              : null,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
    } catch (e) {
      // print('Error syncing user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.get(
        '/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
      
      if (response.data == null || (response.data is String && (response.data as String).isEmpty)) {
        return null;
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // If 404 or other error, return null to trigger sync
      return null;
    }
  }
}
