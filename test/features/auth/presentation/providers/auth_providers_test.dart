import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/error/exceptions.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/auth/domain/repositories/auth_repository.dart';
import 'package:hoop_analytics/features/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = User(
  id: 'u1',
  email: 'coach@club.com',
  name: 'Coach Carter',
  role: UserRole.coach,
  clubId: 'club-7',
);

ProviderContainer _containerWith(AuthRepository repository) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  test('initial state is idle', () {
    final container = _containerWith(repository);
    expect(container.read(authStateProvider).status, AuthStatus.idle);
    expect(container.read(currentUserProvider), isNull);
  });

  test('login success authenticates and exposes the current user', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _user);
    final container = _containerWith(repository);

    await container
        .read(authStateProvider.notifier)
        .login(email: 'coach@club.com', password: 'secret');

    final state = container.read(authStateProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.isAuthenticated, isTrue);
    expect(state.user, _user);
    expect(container.read(currentUserProvider), _user);
  });

  test('login maps a server exception to a friendly error message', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(
      const ServerException(
        message: 'Credenciales inválidas',
        code: 'INVALID_CREDENTIALS',
        statusCode: 401,
      ),
    );
    final container = _containerWith(repository);

    await container
        .read(authStateProvider.notifier)
        .login(email: 'coach@club.com', password: 'wrong');

    final state = container.read(authStateProvider);
    expect(state.status, AuthStatus.error);
    expect(state.errorMessage, 'Credenciales inválidas');
    expect(state.user, isNull);
  });

  test('login maps an unexpected error to a generic message', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('boom'));
    final container = _containerWith(repository);

    await container
        .read(authStateProvider.notifier)
        .login(email: 'coach@club.com', password: 'secret');

    final state = container.read(authStateProvider);
    expect(state.status, AuthStatus.error);
    expect(state.errorMessage, contains('inesperado'));
  });

  test('restoreSession authenticates when a user is cached', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => _user);
    final container = _containerWith(repository);

    await container.read(authStateProvider.notifier).restoreSession();

    expect(container.read(authStateProvider).status, AuthStatus.authenticated);
    expect(container.read(currentUserProvider), _user);
  });

  test('restoreSession stays idle when no user is cached', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
    final container = _containerWith(repository);

    await container.read(authStateProvider.notifier).restoreSession();

    expect(container.read(authStateProvider).status, AuthStatus.idle);
  });

  test('logout clears the session back to idle', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _user);
    when(() => repository.logout()).thenAnswer((_) async {});
    final container = _containerWith(repository);
    await container
        .read(authStateProvider.notifier)
        .login(email: 'coach@club.com', password: 'secret');

    await container.read(authStateProvider.notifier).logout();

    expect(container.read(authStateProvider).status, AuthStatus.idle);
    expect(container.read(currentUserProvider), isNull);
    verify(() => repository.logout()).called(1);
  });
}
