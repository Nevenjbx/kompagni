import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/config/environment_config.dart';

class AppointmentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvironmentConfig.apiUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<String>> getAvailableSlots(String providerId, String serviceId, DateTime date) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _dio.get(
        '/appointments/available-slots',
        queryParameters: {
          'providerId': providerId,
          'serviceId': serviceId,
          'date': dateStr,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<String>.from(response.data);
      } else {
        throw Exception('Failed to load slots');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createAppointment({
    required String providerId,
    required String serviceId,
    required DateTime startTime,
    String? notes,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.post(
        '/appointments',
        data: {
          'providerId': providerId,
          'serviceId': serviceId,
          'startTime': startTime.toIso8601String(),
          'notes': notes,
        },
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

  Future<List<dynamic>> getMyAppointments() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.get(
        '/appointments',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      // Re-throw to handle in UI
      rethrow;
    }
  }
  Future<void> cancelAppointment(String id) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.patch(
        '/appointments/$id/status',
        data: {'status': 'CANCELLED'},
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
}
