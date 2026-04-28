class AppException implements Exception {
  const AppException(
    this.userMessage, {
    this.code,
    this.debugMessage,
    this.cause,
  });

  final String userMessage;
  final String? code;
  final String? debugMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}

class ValidationException extends AppException {
  const ValidationException(
    super.userMessage, {
    super.code,
    super.debugMessage,
    super.cause,
  });
}

class DatabaseException extends AppException {
  const DatabaseException(
    super.userMessage, {
    super.code,
    super.debugMessage,
    super.cause,
  });
}

class NetworkException extends AppException {
  const NetworkException(
    super.userMessage, {
    super.code,
    super.debugMessage,
    super.cause,
  });
}

class UnknownAppException extends AppException {
  const UnknownAppException(
    super.userMessage, {
    super.code,
    super.debugMessage,
    super.cause,
  });
}

class AuthRequiredException extends AppException {
  const AuthRequiredException(
    super.userMessage, {
    super.code,
    super.debugMessage,
    super.cause,
  });
}

class AdminMappingException extends AppException {
  const AdminMappingException(
    super.userMessage, {
    super.code,
    super.debugMessage,
    super.cause,
  });
}
