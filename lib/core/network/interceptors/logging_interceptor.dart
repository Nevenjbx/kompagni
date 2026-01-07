import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor for logging HTTP requests and responses in debug mode
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ 🚀 REQUEST: ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('│ 📦 Body: ${_truncate(options.data.toString(), 200)}');
      }
      if (options.queryParameters.isNotEmpty) {
        debugPrint('│ 🔍 Query: ${options.queryParameters}');
      }
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ ✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('│ 📦 Data: ${_truncate(response.data.toString(), 300)}');
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────────────────────');
      debugPrint('│ ❌ ERROR: ${err.response?.statusCode ?? 'N/A'} ${err.requestOptions.uri}');
      debugPrint('│ 💬 Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('│ 📦 Response: ${_truncate(err.response?.data.toString() ?? '', 200)}');
      }
      debugPrint('└──────────────────────────────────────────────────────────');
    }
    handler.next(err);
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
