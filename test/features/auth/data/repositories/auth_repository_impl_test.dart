import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/error/exceptions.dart';
import 'package:hoop_analytics/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:hoop_analytics/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:hoop_analytics/features/auth/data/models/login_response_model.dart';
import 'package:hoop_analytics/features/auth/data/models/user_model.dart';
import 'package:hoop_analytics/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hoop_analytics/features/auth/domain/entities/auth_tokens.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockLocal extends Mock implements AuthLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late AuthRepositoryImpl repository;

  const userModel = UserModel(
    id: 'u1',
    email: 'coach@club.com',
    name: 'Coach Carter',
    role: UserRole.coach,
    clubId: 'club-7',
  );
  const loginResponse = LoginResponseModel(
    user: userModel,
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
  );

  setUpAll(() {
    registerFallbackValue(
      const AuthTokens(accessToken: 'x', refreshToken: 'y'),
    );
    registerFallbackValue(userModel);
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repository = AuthRepositoryImpl(remote: remote, local: local);
  });

  group('login', () {
    test('saves tokens, caches user, and returns the domain entity', () async {
      when(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => loginResponse);
      when(() => local.saveTokens(any())).thenAnswer((_) async {});
      when(() => local.cacheUser(any())).thenAnswer((_) async {});

      final user = await repository.login(
        email: 'coach@club.com',
        password: 'secret',
      );

      expect(user, userModel.toEntity());
      final savedTokens =
          verify(() => local.saveTokens(captureAny())).captured.single
              as AuthTokens;
      expect(savedTokens.accessToken, 'access-123');
      expect(savedTokens.refreshToken, 'refresh-456');
      verify(() => local.cacheUser(userModel)).called(1);
    });
  });

  group('register', () {
    test('saves tokens, caches user, and returns the domain entity', () async {
      when(() => remote.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
          )).thenAnswer((_) async => loginResponse);
      when(() => local.saveTokens(any())).thenAnswer((_) async {});
      when(() => local.cacheUser(any())).thenAnswer((_) async {});

      final user = await repository.register(
        const RegisterParams(
          email: 'coach@club.com',
          password: 'password8',
          firstName: 'Coach',
          lastName: 'Carter',
        ),
      );

      expect(user, userModel.toEntity());
      final savedTokens =
          verify(() => local.saveTokens(captureAny())).captured.single
              as AuthTokens;
      expect(savedTokens.accessToken, 'access-123');
      expect(savedTokens.refreshToken, 'refresh-456');
      verify(() => local.cacheUser(userModel)).called(1);
    });
  });

  group('refresh', () {
    test('exchanges the stored refresh token and persists new tokens',
        () async {
      const newTokens =
          AuthTokens(accessToken: 'access-new', refreshToken: 'refresh-new');
      when(() => local.readRefreshToken())
          .thenAnswer((_) async => 'refresh-456');
      when(() => remote.refresh(refreshToken: any(named: 'refreshToken')))
          .thenAnswer((_) async => newTokens);
      when(() => local.saveTokens(any())).thenAnswer((_) async {});

      final tokens = await repository.refresh();

      expect(tokens, newTokens);
      verify(() => remote.refresh(refreshToken: 'refresh-456')).called(1);
      verify(() => local.saveTokens(newTokens)).called(1);
    });

    test('throws CacheException when no refresh token is stored', () async {
      when(() => local.readRefreshToken()).thenAnswer((_) async => null);

      expect(repository.refresh(), throwsA(isA<CacheException>()));
      verifyNever(
        () => remote.refresh(refreshToken: any(named: 'refreshToken')),
      );
    });
  });

  group('logout', () {
    test('clears local storage', () async {
      when(() => local.clear()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => local.clear()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('maps the cached user model to a domain entity', () async {
      when(() => local.readUser()).thenAnswer((_) async => userModel);

      final user = await repository.getCurrentUser();

      expect(user, userModel.toEntity());
    });

    test('returns null when no user is cached', () async {
      when(() => local.readUser()).thenAnswer((_) async => null);

      expect(await repository.getCurrentUser(), isNull);
    });
  });
}
