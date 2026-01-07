import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provider.dart' as models;
import '../models/working_hours.dart';
import '../repositories/impl/provider_repository_impl.dart';

/// Provider for managing current provider's profile (for provider users)
/// 
/// This includes their business info, services, and working hours
final providerProfileProvider = AsyncNotifierProvider<ProviderProfileNotifier, models.Provider?>(() {
  return ProviderProfileNotifier();
});

class ProviderProfileNotifier extends AsyncNotifier<models.Provider?> {
  static const int _maxRetries = 20;
  static const Duration _retryDelay = Duration(milliseconds: 200);

  @override
  Future<models.Provider?> build() async {
    return _fetchProfileWithRetry();
  }

  /// Fetch profile with retry logic for race conditions during signup
  Future<models.Provider?> _fetchProfileWithRetry() async {
    final repository = ref.read(providerRepositoryProvider);
    
    for (int i = 0; i < _maxRetries; i++) {
      try {
        return await repository.getMyProfile();
      } catch (e) {
        if (i == _maxRetries - 1) {
          // Last retry failed
          return null;
        }
        await Future.delayed(_retryDelay);
      }
    }
    return null;
  }

  /// Refresh the profile
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfileWithRetry());
  }

  /// Update the profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final repository = ref.read(providerRepositoryProvider);
    await repository.updateProfile(data);
    await refresh();
  }

  /// Update working hours
  Future<void> updateWorkingHours(List<WorkingHours> workingHours) async {
    final repository = ref.read(providerRepositoryProvider);
    await repository.updateWorkingHours(workingHours);
    await refresh();
  }
}

/// Provider for searching providers (public, for clients)
final providerSearchProvider = FutureProvider.family<List<models.Provider>, String>(
  (ref, query) async {
    final repository = ref.read(providerRepositoryProvider);
    return repository.searchProviders(query: query);
  },
);

/// Provider for all providers (empty query)
final allProvidersProvider = FutureProvider<List<models.Provider>>((ref) async {
  final repository = ref.read(providerRepositoryProvider);
  return repository.searchProviders();
});
