sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause == null ? '' : ' ($cause)'}';
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.cause});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

final class ConflictException extends AppException {
  const ConflictException(super.message, {super.cause});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

final class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {super.cause});
}
