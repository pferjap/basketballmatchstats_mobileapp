import 'package:dio/dio.dart';

import '../config/env_config.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';
import 'token_storage.dart';

/// Builds and holds the app's configured [Dio] instance.
///
/// The client targets `EnvConfig.baseUrl`, uses 15s connect/receive timeouts and
/// JSON content type, and runs every request through the auth + retry
/// interceptors. See Plan.md T-006 and Agent_Mobile.md §8.3/§9.2.
class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    EnvConfig? envConfig,
    void Function()? onSessionExpired,
    Dio? httpClient,
    Dio? refreshClient,
    RetryConfig retryConfig = const RetryConfig(),
  }) {
    final config = envConfig ?? EnvConfig.instance;

    final baseOptions = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, dynamic>{
        Headers.acceptHeader: Headers.jsonContentType,
      },
    );

    dio = (httpClient ?? Dio())..options = baseOptions;

    // A separate, interceptor-free client for the refresh call to avoid
    // re-entering the auth interceptor recursively.
    final refresh = (refreshClient ?? Dio())
      ..options = BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      );

    dio.interceptors.addAll([
      AuthInterceptor(
        tokenStorage: tokenStorage,
        refreshClient: refresh,
        retryClient: dio,
        onSessionExpired: onSessionExpired,
      ),
      RetryInterceptor(dio: dio, config: retryConfig),
    ]);
  }

  /// The configured Dio instance used for all REST calls.
  late final Dio dio;
}
