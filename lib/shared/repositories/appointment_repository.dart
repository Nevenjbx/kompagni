import '../models/appointment.dart';

/// Repository interface for appointment-related operations
abstract class AppointmentRepository {
  /// Get all appointments for the current user (as client or provider)
  Future<List<Appointment>> getMyAppointments();

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
  });

  /// Cancel an appointment
  Future<void> cancelAppointment(String id);
}
