import 'dart:async';

import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Injects the JWT access token on every request and transparently refreshes it
/// on a 401 response. See Agent_Mobile.md §9.2.
///
/// When several requests receive a 401 concurrently, only one refresh call is
/// performed — the rest await the shared [Completer]. If the refresh fails, all
/// tokens are cleared and [onSessionExpired] is invoked (e.g. redirect to login).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.refreshClient,
    required this.retryClient,
    this.refreshPath = '/auth/refresh',
    this.onSessionExpired,
  });

  final TokenStorage tokenStorage;

  /// Interceptor-free client used to call the refresh endpoint (avoids recursion).
  final Dio refreshClient;

  /// Client used to replay the original request after a successful refresh.
  final Dio retryClient;

  final String refreshPath;
  final void Function()? onSessionExpired;

  static const String _retriedKey = '__auth_retried__';

  Completer<String>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final alreadyRetried = options.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 || alreadyRetried) {
      return handler.next(err);
    }

    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _endSession();
      return handler.next(err);
    }

    try {
      final newAccessToken = await _refreshTokens();
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await retryClient.fetch<dynamic>(options);
      return handler.resolve(response);
    } catch (_) {
      await _endSession();
      return handler.next(err);
    }
  }

  /// Performs the refresh call, de-duplicating concurrent attempts.
  Future<String> _refreshTokens() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<String>();
    _refreshCompleter = completer;

    unawaited(_doRefresh(completer));

    return completer.future;
  }

  Future<void> _doRefresh(Completer<String> completer) async {
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      final response = await refreshClient.post<dynamic>(
        refreshPath,
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      final payload = body is Map && body['data'] is Map
          ? body['data'] as Map
          : body as Map;

      final accessToken = payload['accessToken'] as String?;
      final newRefreshToken =
          (payload['refreshToken'] as String?) ?? refreshToken!;

      if (accessToken == null || accessToken.isEmpty) {
        throw StateError('Refresh response did not contain an access token');
      }

      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      completer.complete(accessToken);
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _endSession() async {
    await tokenStorage.clear();
    onSessionExpired?.call();
  }
}
