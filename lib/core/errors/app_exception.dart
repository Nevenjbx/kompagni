/// Custom exceptions for the application
/// These provide structured error handling throughout the app

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.statusCode,
  });

  factory NetworkException.noConnection() => const NetworkException(
        message: 'Pas de connexion internet',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'La requête a expiré',
        code: 'TIMEOUT',
      );

  factory NetworkException.serverError({int? statusCode, String? message}) =>
      NetworkException(
        message: message ?? 'Erreur serveur',
        code: 'SERVER_ERROR',
        statusCode: statusCode,
      );

  factory NetworkException.badRequest({String? message}) => NetworkException(
        message: message ?? 'Requête invalide',
        code: 'BAD_REQUEST',
        statusCode: 400,
      );

  factory NetworkException.unauthorized() => const NetworkException(
        message: 'Non autorisé',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

  factory NetworkException.forbidden() => const NetworkException(
        message: 'Accès refusé',
        code: 'FORBIDDEN',
        statusCode: 403,
      );

  factory NetworkException.notFound({String? message}) => NetworkException(
        message: message ?? 'Ressource non trouvée',
        code: 'NOT_FOUND',
        statusCode: 404,
      );

  factory NetworkException.conflict({String? message}) => NetworkException(
        message: message ?? 'Conflit de données',
        code: 'CONFLICT',
        statusCode: 409,
      );
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.notAuthenticated() => const AuthException(
        message: 'Vous devez être connecté',
        code: 'NOT_AUTHENTICATED',
      );

  factory AuthException.sessionExpired() => const AuthException(
        message: 'Session expirée, veuillez vous reconnecter',
        code: 'SESSION_EXPIRED',
      );

  factory AuthException.invalidCredentials() => const AuthException(
        message: 'Email ou mot de passe incorrect',
        code: 'INVALID_CREDENTIALS',
      );
}

/// Business logic exceptions
class BusinessException extends AppException {
  const BusinessException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory BusinessException.slotAlreadyBooked() => const BusinessException(
        message: 'Ce créneau vient d\'être réservé par quelqu\'un d\'autre',
        code: 'SLOT_BOOKED',
      );

  factory BusinessException.providerUnavailable() => const BusinessException(
        message: 'Le prestataire n\'est pas disponible',
        code: 'PROVIDER_UNAVAILABLE',
      );
}
