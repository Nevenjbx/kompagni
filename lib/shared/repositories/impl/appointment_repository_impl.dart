import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../models/appointment.dart';
import '../appointment_repository.dart';

/// Implementation of AppointmentRepository using Dio
class AppointmentRepositoryImpl implements AppointmentRepository {
  final Dio _dio;

  AppointmentRepositoryImpl(this._dio);

  @override
  Future<List<Appointment>> getMyAppointments() async {
    final response = await _dio.get('/appointments');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Appointment.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<String>> getAvailableSlots(
    String providerId,
    String serviceId,
    DateTime date,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await _dio.get(
      '/appointments/available-slots',
      queryParameters: {
        'providerId': providerId,
        'serviceId': serviceId,
        'date': dateStr,
      },
    );

    if (response.statusCode == 200) {
      return List<String>.from(response.data);
    }
    return [];
  }

  @override
  Future<void> createAppointment({
    required String providerId,
    required String serviceId,
    required DateTime startTime,
    String? notes,
  }) async {
    await _dio.post(
      '/appointments',
      data: {
        'providerId': providerId,
        'serviceId': serviceId,
        'startTime': startTime.toIso8601String(),
        'notes': notes,
      },
    );
  }

  @override
  Future<void> cancelAppointment(String id) async {
    await _dio.patch(
      '/appointments/$id/status',
      data: {'status': 'CANCELLED'},
    );
  }
}

/// Provider for AppointmentRepository
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepositoryImpl(ref.read(apiClientProvider));
});
