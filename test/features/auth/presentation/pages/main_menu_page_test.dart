import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/app_router.dart';
import 'package:hoop_analytics/core/config/env_config.dart';
import 'package:hoop_analytics/core/config/environment.dart';
import 'package:hoop_analytics/core/theme/app_theme.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/auth/domain/repositories/auth_repository.dart';
import 'package:hoop_analytics/features/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

User _user(UserRole role) => User(
      id: 'u1',
      email: 'user@club.com',
      name: 'Carlos Núñez',
      role: role,
      clubId: 'club-1',
    );

/// Logs in as [role] against a mock repository and pumps the real router at the
/// home route, so [MainMenuPage] renders with a valid navigation context.
Future<ProviderContainer> _pumpMenu(
  WidgetTester tester,
  UserRole role,
) async {
  EnvConfig.init(Environment.dev);
  final repository = _MockAuthRepository();
  when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
  when(() => repository.logout()).thenAnswer((_) async {});
  when(() => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => _user(role));

  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  await container
      .read(authStateProvider.notifier)
      .login(email: 'user@club.com', password: 'secret');

  final router = container.read(goRouterProvider);
  router.go(AppRoutes.home);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer container) => container
    .read(goRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

const _tomarAnotaciones = 'Tomar anotaciones';
const _asistir = 'Asistir a un partido';
const _panelAdmin = 'Panel de administración';

void main() {
  testWidgets('renders header, brand and section prompt', (tester) async {
    await _pumpMenu(tester, UserRole.superAdmin);

    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(find.text('Tu perfil'), findsOneWidget);
    expect(find.text('¿Qué quieres hacer?'), findsOneWidget);
    expect(find.text('PARTIDO EN DIRECTO'), findsOneWidget);
    expect(find.text('ADMINISTRACIÓN'), findsOneWidget);
  });

  testWidgets('viewer sees only the spectator card', (tester) async {
    await _pumpMenu(tester, UserRole.viewer);

    expect(find.text(_asistir), findsOneWidget);
    expect(find.text(_tomarAnotaciones), findsNothing);
    expect(find.text(_panelAdmin), findsNothing);
  });

  testWidgets('statistician also sees the annotation card', (tester) async {
    await _pumpMenu(tester, UserRole.statistician);

    expect(find.text(_tomarAnotaciones), findsOneWidget);
    expect(find.text(_asistir), findsOneWidget);
    expect(find.text(_panelAdmin), findsNothing);
  });

  testWidgets('coach sees only the spectator card', (tester) async {
    await _pumpMenu(tester, UserRole.coach);

    expect(find.text(_asistir), findsOneWidget);
    expect(find.text(_tomarAnotaciones), findsNothing);
    expect(find.text(_panelAdmin), findsNothing);
  });

  testWidgets('club admin sees annotation and spectator but not admin panel',
      (tester) async {
    await _pumpMenu(tester, UserRole.clubAdmin);

    expect(find.text(_tomarAnotaciones), findsOneWidget);
    expect(find.text(_asistir), findsOneWidget);
    expect(find.text(_panelAdmin), findsNothing);
  });

  testWidgets('super admin sees all three cards', (tester) async {
    await _pumpMenu(tester, UserRole.superAdmin);

    expect(find.text(_tomarAnotaciones), findsOneWidget);
    expect(find.text(_asistir), findsOneWidget);
    expect(find.text(_panelAdmin), findsOneWidget);
  });

  testWidgets('tapping a card navigates to its route', (tester) async {
    final container = await _pumpMenu(tester, UserRole.superAdmin);

    final card = find.text(_panelAdmin);
    await tester.ensureVisible(card);
    await tester.tap(card);

    expect(_location(container), AppRoutes.adminPanel);
  });

  testWidgets('tapping "Tu perfil" opens settings', (tester) async {
    final container = await _pumpMenu(tester, UserRole.viewer);

    await tester.tap(find.text('Tu perfil'));
    await tester.pumpAndSettle();

    expect(_location(container), AppRoutes.settings);
  });
}
