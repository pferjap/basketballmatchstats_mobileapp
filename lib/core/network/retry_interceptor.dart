import 'dart:math';

import 'package:dio/dio.dart';

/// Configuration for [RetryInterceptor]. See Agent_Mobile.md §8.3.
class RetryConfig {
  const RetryConfig({
    this.maxRetries = 3,
    this.retryableStatuses = const {408, 429, 500, 502, 503, 504},
    this.initialBackoff = const Duration(milliseconds: 500),
    this.multiplier = 2.0,
  });

  final int maxRetries;
  final Set<int> retryableStatuses;
  final Duration initialBackoff;
  final double multiplier;
}

/// Retries transient HTTP failures with exponential backoff.
///
/// Retries on the configured status codes (408, 429, 500, 502, 503, 504) and on
/// connection/timeout errors, up to [RetryConfig.maxRetries] times with a
/// 500ms → 1s → 2s backoff. Business errors (other 4xx) are never retried.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.config = const RetryConfig()});

  final Dio dio;
  final RetryConfig config;

  static const String _attemptKey = '__retry_attempt__';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= config.maxRetries) {
      return handler.next(err);
    }

    final backoffMs =
        config.initialBackoff.inMilliseconds * pow(config.multiplier, attempt);
    await Future<void>.delayed(Duration(milliseconds: backoffMs.round()));

    options.extra[_attemptKey] = attempt + 1;

    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.reject(e);
    }
  }

  bool _shouldRetry(DioException err) {
    final status = err.response?.statusCode;
    if (status != null) {
      return config.retryableStatuses.contains(status);
    }
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
