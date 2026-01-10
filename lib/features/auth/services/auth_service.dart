import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpEmailPassword(String email, String password, {Map<String, dynamic>? data}) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Refresh the current session token
  /// 
  /// Returns true if refresh was successful, false otherwise.
  Future<bool> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.session != null;
    } catch (e) {
      return false;
    }
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}

