import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/environment_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Centralized API client using Dio
/// 
/// This singleton provides a pre-configured Dio instance with:
/// - Automatic authentication token injection
/// - Request/Response logging in debug mode
/// - Structured error transformation
/// 
/// Usage:
/// ```dart
/// final dio = ref.read(apiClientProvider);
/// final response = await dio.get('/endpoint');
/// ```
class ApiClient {
  static ApiClient? _instance;
  
  final Dio dio;
  
  ApiClient._internal() : dio = _createDio();
  
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }
  
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvironmentConfig.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Order matters: Auth first, then logging, then error handling
    dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
    
    return dio;
  }
  
  /// Reset the singleton instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}

/// Provider for the Dio instance
/// 
/// Use this in your repositories and services:
/// ```dart
/// class MyRepository {
///   final Dio _dio;
///   MyRepository(this._dio);
/// }
/// 
/// final myRepoProvider = Provider((ref) {
///   return MyRepository(ref.read(apiClientProvider));
/// });
/// ```
final apiClientProvider = Provider<Dio>((ref) {
  return ApiClient().dio;
});
