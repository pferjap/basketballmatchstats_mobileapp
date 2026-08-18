import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response_parser.dart';
import '../models/team_model.dart';

/// A page of team DTOs plus the response's pagination metadata.
typedef PagedTeams = ({List<TeamModel> items, ApiMeta? meta});

/// Remote team CRUD calls against the REST API (Plan.md T-024).
///
/// Responses are unwrapped through [ApiResponseParser], which throws a
/// `ServerException` on non-success bodies. Transport-level Dio failures are
/// translated into the data layer's typed [AppException]s so callers never see
/// a raw `DioException`.
class TeamRemoteDataSource {
  TeamRemoteDataSource(this.dio);

  final Dio dio;

  /// `GET /teams` — paginated list of teams.
  Future<PagedTeams> getTeams({
    int? page,
    int? limit,
    String? clubId,
    String? search,
  }) async {
    final body = await _get(
      '/teams',
      queryParameters: <String, dynamic>{
        'page': ?page,
        'limit': ?limit,
        'clubId': ?clubId,
        'search': ?search,
      },
    );
    final items = ApiResponseParser.data(
      body,
      (Object? data) => (data as List? ?? const <dynamic>[])
          .map(
            (dynamic e) =>
                TeamModel.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
    return (items: items, meta: ApiResponseParser.meta(body));
  }

  /// `GET /teams/:id` — a single team.
  Future<TeamModel> getTeam(String teamId) async {
    final body = await _get('/teams/$teamId');
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          TeamModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `POST /teams` — creates a team.
  Future<TeamModel> createTeam(Map<String, dynamic> payload) async {
    final body = await _post('/teams', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          TeamModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `PUT /teams/:id` — updates a team.
  Future<TeamModel> updateTeam(
    String teamId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _put('/teams/$teamId', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          TeamModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `DELETE /teams/:id` — removes a team.
  Future<void> deleteTeam(String teamId) async {
    final body = await _delete('/teams/$teamId');
    ApiResponseParser.data(body, (_) => null);
  }

  /// `POST /teams/:id/logo` — uploads a team logo (multipart) and returns the
  /// updated team.
  Future<TeamModel> uploadLogo(
    String teamId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final body = await _postMultipart('/teams/$teamId/logo', form);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          TeamModel.fromJson((data! as Map).cast<String, dynamic>()),
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
