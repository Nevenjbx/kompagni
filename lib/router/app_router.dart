import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/provider/screens/provider_dashboard_screen.dart';
import '../features/client/screens/home_client.dart'; // Ensure this exists
import '../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(ref.watch(authServiceProvider).authStateChanges),
     redirect: (context, state) async {
       final isLoggedIn = authState.value?.session != null;
       final isLoggingIn = state.uri.path == '/login';

       if (!isLoggedIn) {
         return '/login';
       }

       if (isLoggingIn && isLoggedIn) {
         // Determine role to redirect correctly
         final user = authState.value?.session?.user;
         
         // 1. Try metadata first
         String? role = user?.userMetadata?['role'];
         
         // 2. If no role in metadata, it might be an UNSYNCED or slow-sync scenario.
         // We should verify against the database or trust the metadata if it's there.
         // For the "Race Condition" fix, if role is null, we can force a fetch or wait.
         // However, in GoRouter redirect is synchronous-ish or needs to be fast.
         // The safest fallback is CLIENT if genuinely unknown, or a 'loading' route.
         // But here, let's assume if it's not PROVIDER, it's CLIENT.
         
         // Fix: If role is totally missing, we might want to check if they are in the process of onboarding
         // but for now, the "UNSYNCED" role from backend might appear here if we refreshed the session.
         
         if (role == 'PROVIDER') {
           return '/provider/dashboard';
         } else {
           return '/client/home';
         }
       }

       return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/provider/dashboard',
        builder: (context, state) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: '/client/home',
        builder: (context, state) => const HomeClientScreen(),
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
