import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';
import '../../features/client/services/appointment_service.dart';
import '../../features/provider/services/provider_service.dart';

// User Service Provider
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Appointment Service Provider
final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService();
});

// Provider Service Provider
final providerServiceProvider = Provider<ProviderService>((ref) {
  return ProviderService();
});
