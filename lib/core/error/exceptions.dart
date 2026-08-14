/// Exceptions thrown by the data layer (datasources).
///
/// Datasources throw these low-level exceptions; repositories catch them and
/// translate them into typed `Failure`s (see `error_mapper.dart`).
/// See Plan.md T-005.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Human-readable message describing the error.
  final String message;

  @override
  String toString() => '$runtimeType(message: $message)';
}

/// Thrown when the backend responds with a non-2xx status and an error body.
final class ServerException extends AppException {
  const ServerException({
    required String message,
    required this.code,
    required this.statusCode,
  }) : super(message);

  /// Business error code from the API (`errors[0].code`).
  final String code;

  /// HTTP status code of the response.
  final int statusCode;

  @override
  String toString() =>
      'ServerException(message: $message, code: $code, statusCode: $statusCode)';
}

/// Thrown when a request fails due to connectivity problems / timeouts.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// Thrown when a local cache/database operation fails.
final class CacheException extends AppException {
  const CacheException([super.message = 'A cache error occurred']);
}
