import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response_parser.dart';
import '../models/club_model.dart';

/// A page of club DTOs plus the response's pagination metadata.
typedef PagedClubs = ({List<ClubModel> items, ApiMeta? meta});

/// Remote club CRUD calls against the REST API (Plan.md T-023).
///
/// Responses are unwrapped through [ApiResponseParser], which throws a
/// `ServerException` on non-success bodies. Transport-level Dio failures are
/// translated into the data layer's typed [AppException]s so callers never see
/// a raw `DioException`.
class ClubRemoteDataSource {
  ClubRemoteDataSource(this.dio);

  final Dio dio;

  /// `GET /clubs` — paginated list of clubs.
  Future<PagedClubs> getClubs({int? page, int? limit, String? search}) async {
    final body = await _get(
      '/clubs',
      queryParameters: <String, dynamic>{
        'page': ?page,
        'limit': ?limit,
        'search': ?search,
      },
    );
    final items = ApiResponseParser.data(
      body,
      (Object? data) => (data as List? ?? const <dynamic>[])
          .map(
            (dynamic e) =>
                ClubModel.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
    return (items: items, meta: ApiResponseParser.meta(body));
  }

  /// `GET /clubs/:id` — a single club.
  Future<ClubModel> getClub(String clubId) async {
    final body = await _get('/clubs/$clubId');
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          ClubModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `POST /clubs` — creates a club.
  Future<ClubModel> createClub(Map<String, dynamic> payload) async {
    final body = await _post('/clubs', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          ClubModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `PUT /clubs/:id` — updates a club.
  Future<ClubModel> updateClub(
    String clubId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _put('/clubs/$clubId', data: payload);
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          ClubModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `DELETE /clubs/:id` — removes a club.
  Future<void> deleteClub(String clubId) async {
    final body = await _delete('/clubs/$clubId');
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
