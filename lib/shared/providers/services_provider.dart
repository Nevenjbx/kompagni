import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/service.dart';
import '../../shared/repositories/impl/service_repository_impl.dart';

/// Provider for managing services (for provider users)
final servicesProvider = AsyncNotifierProvider<ServicesNotifier, List<Service>>(() {
  return ServicesNotifier();
});

class ServicesNotifier extends AsyncNotifier<List<Service>> {
  String? _currentProviderId;

  @override
  Future<List<Service>> build() async {
    // Initially empty, will be populated when provider ID is set
    return [];
  }

  /// Set the provider ID and fetch their services
  Future<void> loadServicesForProvider(String providerId) async {
    _currentProviderId = providerId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchServices(providerId));
  }

  Future<List<Service>> _fetchServices(String providerId) async {
    final repository = ref.read(serviceRepositoryProvider);
    return repository.getServices(providerId);
  }

  /// Refresh services for current provider
  Future<void> refresh() async {
    if (_currentProviderId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchServices(_currentProviderId!));
  }

  /// Create a new service
  Future<void> createService({
    required String name,
    String? description,
    required int duration,
    required double price,
    required String animalType,
  }) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.createService(
      name: name,
      description: description,
      duration: duration,
      price: price,
      animalType: animalType,
    );
    await refresh();
  }

  /// Update an existing service
  Future<void> updateService({
    required String id,
    required String name,
    String? description,
    required int duration,
    required double price,
    required String animalType,
  }) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.updateService(
      id: id,
      name: name,
      description: description,
      duration: duration,
      price: price,
      animalType: animalType,
    );
    await refresh();
  }

  /// Delete a service
  Future<void> deleteService(String id) async {
    final repository = ref.read(serviceRepositoryProvider);
    await repository.deleteService(id);
    await refresh();
  }
}

/// Provider for fetching services of a specific provider (public, for clients)
final providerServicesProvider = FutureProvider.family<List<Service>, String>(
  (ref, providerId) async {
    final repository = ref.read(serviceRepositoryProvider);
    return repository.getServices(providerId);
  },
);
