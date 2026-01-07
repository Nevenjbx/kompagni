import 'dart:io';
import 'package:dio/dio.dart';
import '../../errors/app_exception.dart';

/// Interceptor that transforms Dio errors into structured AppExceptions
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _transformError(err);
    
    // Re-throw as DioException with our custom error attached
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        message: exception.message,
      ),
    );
  }

  AppException _transformError(DioException err) {
    // Handle connection errors
    if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      return NetworkException.noConnection();
    }

    // Handle timeouts
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return NetworkException.timeout();
    }

    // Handle HTTP errors
    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;
    
    // Try to extract error message from response
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message']?.toString() ??
          responseData['error']?.toString();
    } else if (responseData is String && responseData.isNotEmpty) {
      serverMessage = responseData;
    }

    switch (statusCode) {
      case 400:
        return NetworkException.badRequest(message: serverMessage);
      case 401:
        return AuthException.sessionExpired();
      case 403:
        return NetworkException.forbidden();
      case 404:
        return NetworkException.notFound(message: serverMessage);
      case 409:
        // Conflict - often means slot already booked
        if (serverMessage?.toLowerCase().contains('booked') == true ||
            serverMessage?.toLowerCase().contains('slot') == true) {
          return BusinessException.slotAlreadyBooked();
        }
        return NetworkException.conflict(message: serverMessage);
      case 500:
      case 502:
      case 503:
        return NetworkException.serverError(
          statusCode: statusCode,
          message: serverMessage,
        );
      default:
        return NetworkException(
          message: serverMessage ?? 'Une erreur est survenue',
          statusCode: statusCode,
          originalError: err,
        );
    }
  }
}
