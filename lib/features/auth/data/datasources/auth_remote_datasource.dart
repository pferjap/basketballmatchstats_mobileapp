import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../domain/entities/auth_tokens.dart';
import '../models/login_response_model.dart';

/// Remote authentication calls against `POST /auth/login` and
/// `POST /auth/refresh` (Agent_Mobile.md §7.1, §9.2).
///
/// Responses are unwrapped through [ApiResponseParser], which throws a
/// `ServerException` on non-success bodies. Transport-level Dio failures are
/// translated into the data layer's typed [AppException]s so callers never see
/// a raw `DioException`.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this.dio);

  final Dio dio;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final body = await _post(
      '/auth/login',
      <String, dynamic>{'email': email, 'password': password},
    );
    return ApiResponseParser.data(
      body,
      (Object? data) =>
          LoginResponseModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  Future<AuthTokens> refresh({required String refreshToken}) async {
    final body = await _post(
      '/auth/refresh',
      <String, dynamic>{'refreshToken': refreshToken},
    );
    return ApiResponseParser.data(
      body,
      (Object? data) {
        final map = (data! as Map).cast<String, dynamic>();
        return AuthTokens(
          accessToken: map['accessToken'] as String,
          refreshToken: map['refreshToken'] as String,
        );
      },
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(path, data: data);
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map<String, dynamic>) {
        throw ErrorMapper.exceptionFromResponse(
          body,
          statusCode: error.response?.statusCode,
        );
      }
      throw NetworkException(error.message ?? 'No internet connection');
    }
  }
}
