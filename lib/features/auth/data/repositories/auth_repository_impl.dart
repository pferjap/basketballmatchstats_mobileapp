import '../../../../core/error/exceptions.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// [AuthRepository] implementation coordinating the remote API and local
/// secure storage (Plan.md T-010).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.local,
  });

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await remote.login(email: email, password: password);
    await local.saveTokens(response.toTokens());
    await local.cacheUser(response.user);
    return response.user.toEntity();
  }

  @override
  Future<User> register(RegisterParams params) async {
    final response = await remote.register(
      email: params.email,
      password: params.password,
      firstName: params.firstName,
      lastName: params.lastName,
    );
    // Persist the session exactly like login() so the user stays authenticated
    // without re-entering credentials.
    await local.saveTokens(response.toTokens());
    await local.cacheUser(response.user);
    return response.user.toEntity();
  }

  @override
  Future<AuthTokens> refresh() async {
    final refreshToken = await local.readRefreshToken();
    if (refreshToken == null) {
      throw const CacheException('No refresh token stored');
    }
    final tokens = await remote.refresh(refreshToken: refreshToken);
    await local.saveTokens(tokens);
    return tokens;
  }

  @override
  Future<void> logout() => local.clear();

  @override
  Future<User?> getCurrentUser() async {
    final model = await local.readUser();
    return model?.toEntity();
  }
}
