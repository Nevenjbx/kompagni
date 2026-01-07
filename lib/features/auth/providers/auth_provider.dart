import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../../../shared/repositories/impl/user_repository_impl.dart';

/// Provider for the AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Stream provider for authentication state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provider for the currently authenticated Supabase user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user;
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Provider for getting the user's role
/// Attempts to get from metadata first, then falls back to backend
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  // 1. Try to get role from metadata (faster)
  final metadataRole = user.userMetadata?['role'];
  if (metadataRole != null) return metadataRole.toString();

  // 2. Fallback: Fetch profile from backend
  final userRepository = ref.read(userRepositoryProvider);
  final profile = await userRepository.getCurrentUser();
  return profile?['role']?.toString();
});

/// Provider that checks if current user is a provider
final isProviderUserProvider = Provider<AsyncValue<bool>>((ref) {
  final roleAsync = ref.watch(userRoleProvider);
  return roleAsync.when(
    data: (role) => AsyncData(role == 'PROVIDER'),
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

/// Provider that checks if current user is a client
final isClientUserProvider = Provider<AsyncValue<bool>>((ref) {
  final roleAsync = ref.watch(userRoleProvider);
  return roleAsync.when(
    data: (role) => AsyncData(role == 'CLIENT'),
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});
