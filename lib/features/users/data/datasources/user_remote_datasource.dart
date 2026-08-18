import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response_parser.dart';
import '../models/app_user_model.dart';

/// A page of user DTOs plus the response's pagination metadata.
typedef PagedUsers = ({List<AppUserModel> items, ApiMeta? meta});

/// Remote calls against the REST API's `users` module (Plan.md T-032):
/// `GET /users`, `PATCH /users/:id/role`, `PATCH /users/:id/club`.
///
/// Responses are unwrapped through [ApiResponseParser]; transport-level Dio
/// failures are translated into typed [AppException]s so callers never see a
/// raw `DioException`.
class UserRemoteDataSource {
  UserRemoteDataSource(this.dio);

  final Dio dio;

  /// `GET /users` — paginated, newest first.
  Future<PagedUsers> getUsers({int? page, int? limit, String? search}) async {
    final body = await _get(
      '/users',
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
                AppUserModel.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
    return (items: items, meta: ApiResponseParser.meta(body));
  }

  /// `PATCH /users/:id/role` — changes a user's role.
  Future<AppUserModel> updateRole(String userId, String role) async {
    final body = await _patch(
      '/users/$userId/role',
      data: <String, dynamic>{'role': role},
    );
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          AppUserModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  /// `PATCH /users/:id/club` — associates/unassigns a user's club.
  Future<AppUserModel> updateClub(String userId, String? clubId) async {
    final body = await _patch(
      '/users/$userId/club',
      data: <String, dynamic>{'clubId': clubId},
    );
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          AppUserModel.fromJson((data! as Map).cast<String, dynamic>()),
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

  Future<Map<String, dynamic>> _patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(path, data: data);
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
