import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../../../shared/services/user_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user;
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  // 1. Try to get role from metadata
  final metadataRole = user.userMetadata?['role'];
  if (metadataRole != null) return metadataRole.toString();

  // 2. Fallback: Fetch profile
  final userService = UserService(); // Ideally should be provided too
  final profile = await userService.getCurrentUser();
  return profile?['role']?.toString();
});
