import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/appointment.dart';
import '../../shared/repositories/appointment_repository.dart';
import '../../shared/repositories/impl/appointment_repository_impl.dart'; // For appointmentRepositoryProvider

/// Provider for managing client/provider appointments state
/// 
/// Usage in widgets:
/// ```dart
/// final appointmentsAsync = ref.watch(appointmentsProvider);
/// appointmentsAsync.when(
///   data: (appointments) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
final appointmentsProvider = AsyncNotifierProvider<AppointmentsNotifier, List<Appointment>>(() {
  return AppointmentsNotifier();
});

class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    return _fetchAppointments();
  }

  Future<List<Appointment>> _fetchAppointments() async {
    final repository = ref.read(appointmentRepositoryProvider);
    // Fetch paginated result and extract items for backward compatibility
    // Note: For full pagination support in UI, a separate PaginatedAppointmentsNotifier
    // could be created that exposes the full PaginatedResult
    final result = await repository.getMyAppointments(page: 1, limit: 100);
    return result.items;
  }

  /// Refresh the appointments list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAppointments());
  }

  /// Cancel an appointment and refresh the list
  Future<void> cancelAppointment(String id) async {
    final repository = ref.read(appointmentRepositoryProvider);
    await repository.cancelAppointment(id);
    await refresh();
  }

  Future<void> createAppointment({
    required String providerId,
    required String serviceId,
    required DateTime startTime,
    String? notes,
    String? petId,
  }) async {
    final repository = ref.read(appointmentRepositoryProvider);
    await repository.createAppointment(
      providerId: providerId,
      serviceId: serviceId,
      startTime: startTime,
      notes: notes,
      petId: petId,
    );
    await refresh();
  }
}

/// Provider for upcoming appointments only
final upcomingAppointmentsProvider = Provider<AsyncValue<List<Appointment>>>((ref) {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  return appointmentsAsync.whenData(
    (appointments) => appointments.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime)),
  );
});

/// Provider for past/history appointments only
final historyAppointmentsProvider = Provider<AsyncValue<List<Appointment>>>((ref) {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  return appointmentsAsync.whenData(
    (appointments) => appointments.where((a) => a.isHistory).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)),
  );
});

/// Provider for available slots on a specific date
final availableSlotsProvider = FutureProvider.family<List<String>, AvailableSlotsParams>(
  (ref, params) async {
    final repository = ref.read(appointmentRepositoryProvider);
    return repository.getAvailableSlots(params.providerId, params.serviceId, params.date);
  },
);

/// Parameters for fetching available slots
class AvailableSlotsParams {
  final String providerId;
  final String serviceId;
  final DateTime date;

  const AvailableSlotsParams({
    required this.providerId,
    required this.serviceId,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableSlotsParams &&
          runtimeType == other.runtimeType &&
          providerId == other.providerId &&
          serviceId == other.serviceId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => providerId.hashCode ^ serviceId.hashCode ^ date.hashCode;
}
