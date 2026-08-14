import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/retry_interceptor.dart';

/// Fake adapter that returns a predefined status code per attempt.
class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this.statuses);

  final List<int> statuses;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = calls < statuses.length ? calls : statuses.length - 1;
    final status = statuses[index];
    calls++;
    return ResponseBody.fromString(
      '{"success":true,"data":{"ok":true}}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _buildDio(_SequenceAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      config: const RetryConfig(initialBackoff: Duration(milliseconds: 1)),
    ),
  );
  return dio;
}

void main() {
  test('retries retryable status codes then succeeds', () async {
    final adapter = _SequenceAdapter([503, 503, 200]);
    final dio = _buildDio(adapter);

    final response = await dio.get<dynamic>('/resource');

    expect(response.statusCode, 200);
    expect(adapter.calls, 3); // 1 original + 2 retries
  });

  test('does not retry non-retryable 4xx errors', () async {
    final adapter = _SequenceAdapter([400]);
    final dio = _buildDio(adapter);

    await expectLater(
      dio.get<dynamic>('/resource'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          400,
        ),
      ),
    );
    expect(adapter.calls, 1);
  });

  test('stops after maxRetries when failures persist', () async {
    final adapter = _SequenceAdapter([500, 500, 500, 500, 500]);
    final dio = _buildDio(adapter);

    await expectLater(dio.get<dynamic>('/resource'), throwsA(isA<DioException>()));
    expect(adapter.calls, 4); // 1 original + 3 retries
  });
}
