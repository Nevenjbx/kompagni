import '../models/provider.dart';

/// Repository interface for user-related operations
/// 
/// This abstraction allows for easy testing and swapping implementations
abstract class UserRepository {
  /// Get the current authenticated user's profile from the backend
  Future<Map<String, dynamic>?> getCurrentUser();

  /// Sync the Supabase user with the backend database
  Future<void> syncUser({
    required String role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    Map<String, dynamic>? providerProfile,
    List<String>? tags,
  });

  /// Update the current user's profile
  Future<void> updateUser(Map<String, dynamic> data);

  /// Delete the current user's account
  Future<void> deleteAccount();

  /// Add a provider to the user's favorites
  Future<void> addFavorite(String providerId);

  /// Remove a provider from the user's favorites
  Future<void> removeFavorite(String providerId);

  /// Get all favorite providers for the current user
  Future<List<Provider>> getFavorites();
}
