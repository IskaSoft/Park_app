// lib/core/errors/app_exception.dart
// REPLACE entire file — no logic changes, just confirming it's correct.

sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Baglanyşyk ýok. Internet barlaň.']);
}

final class ServerException extends AppException {
  const ServerException(
      [super.message = 'Serwer ýalňyşlygy. Biraz soň synanyşyň.']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Tapylmady.']);
}

final class UnknownException extends AppException {
  const UnknownException([super.message = 'Näbelli ýalňyşlyk.']);
}
