import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/error/exceptions.dart';
import 'package:hoop_analytics/core/network/api_response_parser.dart';

void main() {
  group('ApiResponseParser.data', () {
    test('unwraps data on a successful response', () {
      final body = <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'data': {'id': '42', 'name': 'Lakers'},
        'timestamp': '2026-01-01T00:00:00Z',
      };

      final result = ApiResponseParser.data<Map<String, dynamic>>(
        body,
        (data) => data! as Map<String, dynamic>,
      );

      expect(result['id'], '42');
      expect(result['name'], 'Lakers');
    });

    test('throws a ServerException on an unsuccessful response', () {
      final body = <String, dynamic>{
        'success': false,
        'statusCode': 422,
        'errors': [
          {'code': 'VALIDATION', 'message': 'Invalid payload'},
        ],
      };

      expect(
        () => ApiResponseParser.data<Object?>(body, (data) => data),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'VALIDATION')
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'Invalid payload'),
        ),
      );
    });
  });

  group('ApiResponseParser.meta', () {
    test('parses pagination metadata when present', () {
      final meta = ApiResponseParser.meta({
        'success': true,
        'data': <dynamic>[],
        'meta': {'page': 2, 'limit': 20, 'total': 55},
      });

      expect(meta, isNotNull);
      expect(meta!.page, 2);
      expect(meta.limit, 20);
      expect(meta.total, 55);
    });

    test('returns null when meta is absent', () {
      expect(ApiResponseParser.meta({'success': true, 'data': 1}), isNull);
    });
  });
}
