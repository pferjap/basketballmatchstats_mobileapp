import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/app_router.dart';
import 'package:hoop_analytics/core/theme/app_theme.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/auth/domain/repositories/auth_repository.dart';
import 'package:hoop_analytics/features/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

User _user(UserRole role) => User(
      id: 'u1',
      email: 'user@club.com',
      name: 'Test User',
      role: role,
      clubId: 'club-1',
    );

/// Pumps the real [goRouterProvider] with a controllable auth repository and,
/// optionally, an already-authenticated session for the given [role].
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  UserRole? authenticatedAs,
  String initialLocation = AppRoutes.home,
}) async {
  final repository = _MockAuthRepository();
  when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
  when(() => repository.logout()).thenAnswer((_) async {});

  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  if (authenticatedAs != null) {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _user(authenticatedAs));
    await container
        .read(authStateProvider.notifier)
        .login(email: 'user@club.com', password: 'secret');
  }

  final router = container.read(goRouterProvider);
  router.go(initialLocation);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String _currentLocation(ProviderContainer container) {
  final router = container.read(goRouterProvider);
  return router
      .routerDelegate.currentConfiguration.uri
      .toString();
}

void main() {
  testWidgets('redirects an unauthenticated user to /login', (tester) async {
    final container = await _pumpApp(tester, initialLocation: AppRoutes.home);

    expect(_currentLocation(container), AppRoutes.login);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });

  testWidgets('protected deep link is guarded before rendering',
      (tester) async {
    final container = await _pumpApp(
      tester,
      initialLocation: '/matches/42/live',
    );

    expect(_currentLocation(container), AppRoutes.login);
  });

  testWidgets('authenticated user reaches home', (tester) async {
    final container = await _pumpApp(
      tester,
      authenticatedAs: UserRole.coach,
      initialLocation: AppRoutes.home,
    );

    expect(_currentLocation(container), AppRoutes.home);
    expect(find.text('¿Qué quieres hacer?'), findsOneWidget);
  });

  testWidgets('authenticated user on /login is sent home', (tester) async {
    final container = await _pumpApp(
      tester,
      authenticatedAs: UserRole.coach,
      initialLocation: AppRoutes.login,
    );

    expect(_currentLocation(container), AppRoutes.home);
  });

  testWidgets('statistician can open the annotation route', (tester) async {
    final container = await _pumpApp(
      tester,
      authenticatedAs: UserRole.statistician,
      initialLocation: '/matches/42/annotate',
    );

    expect(_currentLocation(container), '/matches/42/annotate');
    expect(find.text('Anotación'), findsWidgets);
  });

  testWidgets('club admin can open the annotation route', (tester) async {
    final container = await _pumpApp(
      tester,
      authenticatedAs: UserRole.clubAdmin,
      initialLocation: '/matches/42/annotate',
    );

    expect(_currentLocation(container), '/matches/42/annotate');
  });

  testWidgets('viewer is blocked from the annotation route and sent home',
      (tester) async {
    final container = await _pumpApp(
      tester,
      authenticatedAs: UserRole.viewer,
      initialLocation: '/matches/42/annotate',
    );

    expect(_currentLocation(container), AppRoutes.home);
  });

  testWidgets('logout returns the user to /login', (tester) async {
    final container = await _pumpApp(
      tester,
      authenticatedAs: UserRole.coach,
      initialLocation: AppRoutes.home,
    );
    expect(_currentLocation(container), AppRoutes.home);

    await container.read(authStateProvider.notifier).logout();
    await tester.pumpAndSettle();

    expect(_currentLocation(container), AppRoutes.login);
  });
}
