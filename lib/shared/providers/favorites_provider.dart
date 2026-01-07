import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provider.dart' as models;
import '../repositories/impl/user_repository_impl.dart';

/// Provider for managing user's favorite providers state
/// 
/// Usage in widgets:
/// ```dart
/// final favoritesAsync = ref.watch(favoritesProvider);
/// ```
final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<models.Provider>>(() {
  return FavoritesNotifier();
});

class FavoritesNotifier extends AsyncNotifier<List<models.Provider>> {
  @override
  Future<List<models.Provider>> build() async {
    return _fetchFavorites();
  }

  Future<List<models.Provider>> _fetchFavorites() async {
    final repository = ref.read(userRepositoryProvider);
    return repository.getFavorites();
  }

  /// Refresh the favorites list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFavorites());
  }

  /// Add a provider to favorites with optimistic update
  Future<void> addFavorite(models.Provider provider) async {
    // Optimistic update
    final currentState = state;
    if (currentState is AsyncData<List<models.Provider>>) {
      state = AsyncData([...currentState.value, provider]);
    }

    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.addFavorite(provider.id);
    } catch (e) {
      // Revert on error
      state = currentState;
      rethrow;
    }
  }

  /// Remove a provider from favorites with optimistic update
  Future<void> removeFavorite(String providerId) async {
    // Optimistic update
    final currentState = state;
    if (currentState is AsyncData<List<models.Provider>>) {
      state = AsyncData(
        currentState.value.where((p) => p.id != providerId).toList(),
      );
    }

    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.removeFavorite(providerId);
    } catch (e) {
      // Revert on error
      state = currentState;
      rethrow;
    }
  }

  /// Check if a provider is in favorites
  bool isFavorite(String providerId) {
    final currentState = state;
    if (currentState is AsyncData<List<models.Provider>>) {
      return currentState.value.any((p) => p.id == providerId);
    }
    return false;
  }
}

/// Provider to check if a specific provider is favorited
final isFavoriteProvider = Provider.family<bool, String>((ref, providerId) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.when(
    data: (favorites) => favorites.any((p) => p.id == providerId),
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});
