import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor that automatically adds the Supabase auth token to requests
/// and handles automatic token refresh on 401 errors.
class AuthInterceptor extends Interceptor {
  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 - attempt token refresh and retry
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      
      try {
        // Attempt to refresh the session
        final response = await Supabase.instance.client.auth.refreshSession();
        
        if (response.session != null) {
          // Retry the original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${response.session!.accessToken}';
          
          // Create a new Dio instance to avoid interceptor loop
          final dio = Dio(BaseOptions(
            baseUrl: options.baseUrl,
            headers: options.headers,
          ));
          
          try {
            final retryResponse = await dio.request(
              options.path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
              ),
            );
            
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          } catch (retryError) {
            _isRefreshing = false;
            return handler.next(err);
          }
        }
      } catch (refreshError) {
        // Refresh failed - let error propagate (will trigger logout via error interceptor)
        _isRefreshing = false;
      }
    }
    
    handler.next(err);
  }
}

