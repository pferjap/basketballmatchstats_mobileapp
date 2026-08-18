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

const _newUser = User(
  id: 'u9',
  email: 'nuevo@club.com',
  name: 'Nuevo Usuario',
  role: UserRole.viewer,
);

Future<ProviderContainer> _pumpRegister(
  WidgetTester tester,
  AuthRepository repository,
) async {
  when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
  when(() => repository.logout()).thenAnswer((_) async {});

  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);

  final router = container.read(goRouterProvider);
  router.go(AppRoutes.register);

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

Future<void> _fillValidForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Nuevo');
  await tester.enterText(fields.at(1), 'Usuario');
  await tester.enterText(fields.at(2), 'nuevo@club.com');
  await tester.enterText(fields.at(3), 'password8');
  await tester.enterText(fields.at(4), 'password8');
  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const RegisterParams(
        email: 'x@y.com',
        password: 'password8',
        firstName: 'X',
        lastName: 'Y',
      ),
    );
  });

  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  testWidgets('unauthenticated user can reach /register', (tester) async {
    final container = await _pumpRegister(tester, repository);

    expect(_location(container), AppRoutes.register);
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(
      find.textContaining('Tu cuenta se creará como espectador'),
      findsOneWidget,
    );
  });

  testWidgets('does not submit while the terms are unaccepted', (tester) async {
    await _pumpRegister(tester, repository);
    await _fillValidForm(tester);

    final submit = find.widgetWithText(ElevatedButton, 'Crear cuenta');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    verifyNever(() => repository.register(any()));
  });

  testWidgets('valid sign-up registers and lands on the menu', (tester) async {
    when(() => repository.register(any())).thenAnswer((_) async => _newUser);
    final container = await _pumpRegister(tester, repository);

    await _fillValidForm(tester);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final submit = find.widgetWithText(ElevatedButton, 'Crear cuenta');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    verify(() => repository.register(any())).called(1);
    expect(_location(container), AppRoutes.home);
  });

  testWidgets('the login link routes back to /login', (tester) async {
    final container = await _pumpRegister(tester, repository);

    final loginLink = find.byType(TextButton);
    await tester.ensureVisible(loginLink);
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    expect(_location(container), AppRoutes.login);
  });
}
