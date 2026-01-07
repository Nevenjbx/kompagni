import '../models/provider.dart';
import '../models/working_hours.dart';

/// Repository interface for provider-related operations
abstract class ProviderRepository {
  /// Search for providers with optional query
  Future<List<Provider>> searchProviders({String query = ''});

  /// Get the current provider's profile (for provider users)
  Future<Provider> getMyProfile();

  /// Update the provider's profile
  Future<void> updateProfile(Map<String, dynamic> data);

  /// Update the provider's working hours
  Future<void> updateWorkingHours(List<WorkingHours> workingHours);
}
