/// Custom exceptions
class AppException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

class AppAuthException extends AppException {
  AppAuthException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class NetworkException extends AppException {
  NetworkException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class ValidationException extends AppException {
  ValidationException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class NotFoundException extends AppException {
  NotFoundException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

class UnauthorizedException extends AppException {
  UnauthorizedException({
    required String message,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    originalException: originalException,
    stackTrace: stackTrace,
  );
}
