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
         // Note: We can't easily wait for FutureProvider here without making this async and potentially slow.
         // A common pattern is to redirect to a 'loading' or 'splash' page that determines the role.
         // For now, let's try to read the metadata directly from the user object if available.
         final user = authState.value?.session?.user;
         final role = user?.userMetadata?['role'] ?? 'CLIENT';
         
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
