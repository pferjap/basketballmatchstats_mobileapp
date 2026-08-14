import 'exceptions.dart';
import 'failures.dart';

/// Maps backend error payloads and data-layer exceptions to typed [Failure]s.
///
/// The backend returns errors using the standard wrapper documented in
/// Agent_Mobile.md §6:
/// ```json
/// {
///   "success": false,
///   "statusCode": 422,
///   "errors": [{ "code": "PLAYER_NOT_ON_COURT", "message": "...", "details": {} }],
///   "timestamp": "..."
/// }
/// ```
abstract final class ErrorMapper {
  static const String _defaultCode = 'UNKNOWN';
  static const String _defaultMessage = 'An unexpected server error occurred';

  /// Parses a backend error JSON body into a [ServerFailure].
  ///
  /// The first entry of `errors` is used for the user-facing message and code,
  /// mirroring the app's `errors[0].message` convention.
  static ServerFailure mapErrorResponse(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final resolvedStatus =
        statusCode ?? (json['statusCode'] as num?)?.toInt() ?? 0;

    var code = _defaultCode;
    var message = _defaultMessage;

    final errors = json['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map) {
        final firstCode = first['code'];
        final firstMessage = first['message'];
        if (firstCode != null) code = firstCode.toString();
        if (firstMessage != null) message = firstMessage.toString();
      }
    }

    return ServerFailure(
      message: message,
      code: code,
      statusCode: resolvedStatus,
    );
  }

  /// Builds a [ServerException] from a backend error JSON body.
  static ServerException exceptionFromResponse(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final failure = mapErrorResponse(json, statusCode: statusCode);
    return ServerException(
      message: failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }

  /// Translates a data-layer [AppException] into a domain [Failure].
  static Failure mapException(Object error) {
    return switch (error) {
      ServerException(:final message, :final code, :final statusCode) =>
        statusCode == 401
            ? AuthFailure(message)
            : ServerFailure(
                message: message,
                code: code,
                statusCode: statusCode,
              ),
      NetworkException(:final message) => NetworkFailure(message),
      CacheException(:final message) => CacheFailure(message),
      Failure() => error,
      _ => const ServerFailure(
          message: _defaultMessage,
          code: _defaultCode,
          statusCode: 0,
        ),
    };
  }
}
