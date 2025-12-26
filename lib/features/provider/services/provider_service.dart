import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../../shared/models/working_hours.dart';
import '../../../shared/models/provider.dart';

class ProviderService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.111:3000', // Adjust for Android Emulator: 10.0.2.2
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<Provider>> searchProviders({String query = ''}) async {
    try {
      final response = await _dio.get(
        '/providers/search',
        queryParameters: {
          'q': query,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Provider.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load providers');
      }
    } catch (e) {
      // Log error internally if needed
      rethrow;
    }
  }

  Future<void> updateWorkingHours(List<WorkingHours> workingHours) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.put(
        '/providers/me/working-hours',
        data: workingHours
            .where((wh) => !wh.isClosed)
            .map((wh) => wh.toJson())
            .toList(),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Provider> getMyProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.get(
        '/providers/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Provider.fromJson(response.data);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      rethrow;
    }
  }
}
