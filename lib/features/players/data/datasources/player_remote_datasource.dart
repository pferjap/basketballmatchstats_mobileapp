import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response_parser.dart';
import '../models/player_model.dart';

/// A page of player DTOs plus the response's pagination metadata.
typedef PagedPlayers = ({List<PlayerModel> items, ApiMeta? meta});

/// Remote player CRUD calls against the REST API (Plan.md T-025).
///
/// Responses are unwrapped through [ApiResponseParser], which throws a
/// `ServerException` on non-success bodies. Transport-level Dio failures are
/// translated into the data layer's typed [AppException]s so callers never see
/// a raw `DioException`.
class PlayerRemoteDataSource {
  PlayerRemoteDataSource(this.dio);

  final Dio dio;

  /// `GET /players` — paginated list of players.
  Future<PagedPlayers> getPlayers({
    int? page,
    int? limit,
    String? teamId,
    String? search,
  }) async {
    final body = await _get(
      '/players',
      queryParameters: <String, dynamic>{
        'page': ?page,
        'limit': ?limit,
        'teamId': ?teamId,
        'search': ?search,
      },
    );
    final items = ApiResponseParser.data(
      body,
      (Object? data) => (data as List? ?? const <dynamic>[])
          .map(
            (dynamic e) =>
                PlayerModel.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
    return (items: items, meta: ApiResponseParser.meta(body));
  }

  /// `GET /players/:id` — a single player.
  Future<PlayerModel> getPlayer(String playerId) async {
    final body = await _get('/players/$playerId');
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          PlayerModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `POST /players` — creates a player.
  Future<PlayerModel> createPlayer(Map<String, dynamic> payload) async {
    final body = await _post('/players', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          PlayerModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `PUT /players/:id` — updates a player.
  Future<PlayerModel> updatePlayer(
    String playerId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _put('/players/$playerId', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          PlayerModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `DELETE /players/:id` — removes a player.
  Future<void> deletePlayer(String playerId) async {
    final body = await _delete('/players/$playerId');
    ApiResponseParser.data(body, (_) => null);
  }

  /// `POST /players/:id/photo` — uploads a player photo (multipart) and returns
  /// the updated player.
  Future<PlayerModel> uploadPhoto(
    String playerId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final body = await _postMultipart('/players/$playerId/photo', form);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          PlayerModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
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

  Future<Map<String, dynamic>> _postMultipart(
    String path,
    FormData data,
  ) async {
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
