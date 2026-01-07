import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor that automatically adds the Supabase auth token to requests
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 - could trigger token refresh or logout
    if (err.response?.statusCode == 401) {
      // Token might be expired - the app should handle this gracefully
      // For now, we let the error propagate to the error interceptor
    }
    handler.next(err);
  }
}
