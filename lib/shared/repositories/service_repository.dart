import '../models/service.dart';

/// Repository interface for service-related operations
abstract class ServiceRepository {
  /// Get all services for a provider
  Future<List<Service>> getServices(String providerId);

  /// Create a new service (for providers)
  Future<void> createService({
    required String name,
    String? description,
    required int duration,
    required double price,
    required String animalType,
  });

  /// Update an existing service
  Future<void> updateService({
    required String id,
    required String name,
    String? description,
    required int duration,
    required double price,
    required String animalType,
  });

  /// Delete a service
  Future<void> deleteService(String id);
}
