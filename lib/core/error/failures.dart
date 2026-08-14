/// Typed failures returned by the domain layer.
///
/// Repositories catch data-layer exceptions (see `exceptions.dart`) and map
/// them to a [Failure] so the presentation layer can react in a type-safe way.
/// See Plan.md T-005 and Agent_Mobile.md §5/§6.
sealed class Failure {
  const Failure(this.message);

  /// Human-readable message suitable for surfacing to the user.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.runtimeType == runtimeType &&
      other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType(message: $message)';
}

/// A failure returned by the backend (non-2xx response with an error body).
final class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    required this.code,
    required this.statusCode,
  }) : super(message);

  /// Business error code from the API (`errors[0].code`).
  final String code;

  /// HTTP status code of the response.
  final int statusCode;

  @override
  bool operator ==(Object other) =>
      other is ServerFailure &&
      other.message == message &&
      other.code == code &&
      other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(runtimeType, message, code, statusCode);

  @override
  String toString() =>
      'ServerFailure(message: $message, code: $code, statusCode: $statusCode)';
}

/// A failure caused by the absence of network connectivity.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// A failure reading from or writing to the local cache/database.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'A cache error occurred']);
}

/// Authentication failure — token expired and could not be refreshed.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Your session has expired']);
}
