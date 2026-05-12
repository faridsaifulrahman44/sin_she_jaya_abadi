import 'app_exception.dart';

enum FailureType {
  validation,
  auth,
  network,
  database,
  unknown,
}

class Failure {
  const Failure({
    required this.type,
    required this.message,
    this.code,
  });

  final FailureType type;
  final String message;
  final String? code;
}

class FailureMapper {
  const FailureMapper._();

  static Failure fromException(Object error) {
    if (error is ValidationException) {
      return Failure(
        type: FailureType.validation,
        message: error.userMessage,
        code: error.code,
      );
    }
    if (error is AuthRequiredException || error is AdminMappingException) {
      return Failure(
        type: FailureType.auth,
        message: error is AppException
            ? error.userMessage
            : 'Autentikasi dibutuhkan.',
        code: error is AppException ? error.code : null,
      );
    }
    if (error is NetworkException) {
      return Failure(
        type: FailureType.network,
        message: error.userMessage,
        code: error.code,
      );
    }
    if (error is DatabaseException) {
      return Failure(
        type: FailureType.database,
        message: error.userMessage,
        code: error.code,
      );
    }
    if (error is AppException) {
      return Failure(
        type: FailureType.unknown,
        message: error.userMessage,
        code: error.code,
      );
    }
    return const Failure(
      type: FailureType.unknown,
      message: 'Terjadi kesalahan tidak terduga.',
    );
  }
}
