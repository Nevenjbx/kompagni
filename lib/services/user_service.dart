import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000', // 10.0.2.2 for emulator
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<void> syncUser({
    required String role,
    String? name,
    Map<String, dynamic>? providerProfile,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.post(
        '/users/sync',
        data: {
          'role': role,
          'name': name,
          'providerProfile': providerProfile,
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
