import 'package:dio/dio.dart';

import '../../../../core/network/api_response_parser.dart';
import '../../domain/entities/auth_tokens.dart';
import '../models/login_response_model.dart';

/// Remote authentication calls against `POST /auth/login` and
/// `POST /auth/refresh` (Agent_Mobile.md §7.1, §9.2).
///
/// Responses are unwrapped through [ApiResponseParser], which throws a
/// `ServerException` on non-success bodies.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this.dio);

  final Dio dio;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: <String, dynamic>{'email': email, 'password': password},
    );
    return ApiResponseParser.data(
      response.data ?? const <String, dynamic>{},
      (Object? data) =>
          LoginResponseModel.fromJson((data! as Map).cast<String, dynamic>()),
    );
  }

  Future<AuthTokens> refresh({required String refreshToken}) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: <String, dynamic>{'refreshToken': refreshToken},
    );
    return ApiResponseParser.data(
      response.data ?? const <String, dynamic>{},
      (Object? data) {
        final map = (data! as Map).cast<String, dynamic>();
        return AuthTokens(
          accessToken: map['accessToken'] as String,
          refreshToken: map['refreshToken'] as String,
        );
      },
    );
  }
}
