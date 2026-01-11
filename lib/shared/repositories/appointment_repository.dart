import '../models/appointment.dart';
import '../models/paginated_result.dart';

/// Repository interface for appointment-related operations
abstract class AppointmentRepository {
  /// Get all appointments for the current user (as client or provider)
  /// 
  /// Supports pagination with [page] (1-indexed) and [limit] parameters.
  /// Returns a [PaginatedResult] containing items and pagination metadata.
  Future<PaginatedResult<Appointment>> getMyAppointments({
    int page = 1,
    int limit = 20,
  });

  /// Get available time slots for a service on a specific date
  Future<List<String>> getAvailableSlots(
    String providerId,
    String serviceId,
    DateTime date,
  );

  /// Create a new appointment
  Future<void> createAppointment({
    required String providerId,
    required String serviceId,
    required DateTime startTime,
    String? notes,
    String? petId,
  });

  /// Update appointment status
  Future<void> updateStatus(String id, AppointmentStatus status);

  /// Cancel an appointment
  Future<void> cancelAppointment(String id);
}

