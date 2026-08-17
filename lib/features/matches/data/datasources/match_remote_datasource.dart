import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response_parser.dart';
import '../models/event_model.dart';
import '../models/match_model.dart';
import '../models/match_statistics_model.dart';

/// A page of DTOs plus the response's pagination metadata.
typedef PagedModels<T> = ({List<T> items, ApiMeta? meta});

/// Remote match/event calls against the REST API (Agent_Mobile §7.1).
///
/// Responses are unwrapped through [ApiResponseParser], which throws a
/// `ServerException` on non-success bodies. Transport-level Dio failures are
/// translated into the data layer's typed [AppException]s so callers never see
/// a raw `DioException`.
class MatchRemoteDataSource {
  MatchRemoteDataSource(this.dio);

  final Dio dio;

  /// `GET /matches` — paginated list of matches.
  Future<PagedModels<MatchModel>> getMatches({int? page, int? limit}) async {
    final body = await _get(
      '/matches',
      queryParameters: <String, dynamic>{'page': ?page, 'limit': ?limit},
    );
    final items = ApiResponseParser.data(
      body,
      (Object? data) => (data as List? ?? const <dynamic>[])
          .map(
            (dynamic e) =>
                MatchModel.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
    return (items: items, meta: ApiResponseParser.meta(body));
  }

  /// `GET /matches/:id` — a single match.
  Future<MatchModel> getMatch(String matchId) async {
    final body = await _get('/matches/$matchId');
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          MatchModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `POST /matches` — schedules a new match (admin panel, Plan.md T-030).
  Future<MatchModel> createMatch(Map<String, dynamic> payload) async {
    final body = await _post('/matches', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          MatchModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `PUT /matches/:id` — updates a match's scheduling details.
  Future<MatchModel> updateMatch(
    String matchId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _put('/matches/$matchId', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          MatchModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `DELETE /matches/:id` — removes a match.
  Future<void> deleteMatch(String matchId) async {
    final body = await _delete('/matches/$matchId');
    ApiResponseParser.data(body, (_) => null);
  }

  /// `POST /matches/:id/start` — starts a scheduled match.
  Future<MatchModel> startMatch(String matchId) async {
    final body = await _post('/matches/$matchId/start');
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          MatchModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `GET /matches/:id/statistics` — score + per-player lines.
  Future<MatchStatisticsModel> getMatchStatistics(String matchId) async {
    final body = await _get('/matches/$matchId/statistics');
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          MatchStatisticsModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `GET /matches/:id/events` — paginated events, optionally only those
  /// created after [since] (§7.3 reconciliation).
  Future<PagedModels<EventModel>> getMatchEvents(
    String matchId, {
    DateTime? since,
    int? page,
    int? limit,
  }) async {
    final body = await _get(
      '/matches/$matchId/events',
      queryParameters: <String, dynamic>{
        'since': ?since?.toIso8601String(),
        'page': ?page,
        'limit': ?limit,
      },
    );
    final items = ApiResponseParser.data(
      body,
      (Object? data) => (data as List? ?? const <dynamic>[])
          .map(
            (dynamic e) =>
                EventModel.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
    return (items: items, meta: ApiResponseParser.meta(body));
  }

  /// `POST /matches/:id/events` — records a new event, returning the server's
  /// canonical copy.
  Future<EventModel> recordEvent(
    String matchId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _post('/matches/$matchId/events', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          EventModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `DELETE /matches/:id/events/last` — undoes the most recent event
  /// (compensation/soft-delete, §11).
  Future<void> undoLastEvent(String matchId) async {
    final body = await _delete('/matches/$matchId/events/last');
    // Surface a non-success body as a ServerException; discard the payload.
    ApiResponseParser.data(body, (_) => null);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(path, data: data);
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(path, data: data);
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final response = await dio.delete<Map<String, dynamic>>(path);
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      return ErrorMapper.exceptionFromResponse(
        body,
        statusCode: error.response?.statusCode,
      );
    }
    return NetworkException(error.message ?? 'No internet connection');
  }
}
