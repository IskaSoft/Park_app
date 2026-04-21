/// Typed exceptions propagated from the data layer upward.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error. Please try again.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found.']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}
