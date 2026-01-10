import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../models/appointment.dart';
import '../../models/paginated_result.dart';
import '../appointment_repository.dart';

/// Implementation of AppointmentRepository using Dio
class AppointmentRepositoryImpl implements AppointmentRepository {
  final Dio _dio;

  AppointmentRepositoryImpl(this._dio);

  @override
  Future<PaginatedResult<Appointment>> getMyAppointments({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/appointments',
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.statusCode == 200) {
      return PaginatedResult.fromJson(
        response.data,
        (json) => Appointment.fromJson(json),
      );
    }
    return PaginatedResult(items: [], total: 0, page: page, limit: limit);
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
  Future<void> updateStatus(String id, AppointmentStatus status) async {
    await _dio.patch(
      '/appointments/$id/status',
      data: {'status': status.name.toUpperCase()},
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
