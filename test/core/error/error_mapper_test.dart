import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/error/error_mapper.dart';
import 'package:hoop_analytics/core/error/exceptions.dart';
import 'package:hoop_analytics/core/error/failures.dart';

void main() {
  group('ErrorMapper.mapErrorResponse', () {
    test('parses the first error entry from a backend error body', () {
      final json = <String, dynamic>{
        'success': false,
        'statusCode': 422,
        'errors': [
          {'code': 'PLAYER_NOT_ON_COURT', 'message': 'Player is not on court'},
          {'code': 'SECONDARY', 'message': 'ignored'},
        ],
        'timestamp': '2026-01-01T00:00:00Z',
      };

      final failure = ErrorMapper.mapErrorResponse(json);

      expect(
        failure,
        const ServerFailure(
          message: 'Player is not on court',
          code: 'PLAYER_NOT_ON_COURT',
          statusCode: 422,
        ),
      );
    });

    test('falls back to defaults when errors are missing', () {
      final failure = ErrorMapper.mapErrorResponse(
        <String, dynamic>{'success': false, 'statusCode': 500},
      );

      expect(failure.code, 'UNKNOWN');
      expect(failure.statusCode, 500);
      expect(failure.message, isNotEmpty);
    });

    test('honors an explicit statusCode override', () {
      final failure = ErrorMapper.mapErrorResponse(
        <String, dynamic>{'errors': <dynamic>[]},
        statusCode: 404,
      );

      expect(failure.statusCode, 404);
    });
  });

  group('ErrorMapper.mapException', () {
    test('maps a 401 ServerException to an AuthFailure', () {
      const exception = ServerException(
        message: 'expired',
        code: 'TOKEN_EXPIRED',
        statusCode: 401,
      );

      expect(ErrorMapper.mapException(exception), isA<AuthFailure>());
    });

    test('maps a non-401 ServerException to a ServerFailure', () {
      const exception = ServerException(
        message: 'bad request',
        code: 'VALIDATION',
        statusCode: 400,
      );

      expect(
        ErrorMapper.mapException(exception),
        const ServerFailure(
          message: 'bad request',
          code: 'VALIDATION',
          statusCode: 400,
        ),
      );
    });

    test('maps NetworkException and CacheException to their failures', () {
      expect(
        ErrorMapper.mapException(const NetworkException()),
        isA<NetworkFailure>(),
      );
      expect(
        ErrorMapper.mapException(const CacheException()),
        isA<CacheFailure>(),
      );
    });

    test('returns an existing Failure unchanged', () {
      const failure = NetworkFailure();
      expect(ErrorMapper.mapException(failure), same(failure));
    });
  });
}
