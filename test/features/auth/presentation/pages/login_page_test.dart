import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/error/exceptions.dart';
import 'package:hoop_analytics/core/theme/app_theme.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/auth/domain/repositories/auth_repository.dart';
import 'package:hoop_analytics/features/auth/presentation/pages/login_page.dart';
import 'package:hoop_analytics/features/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = User(
  id: 'u1',
  email: 'coach@club.com',
  name: 'Coach Carter',
  role: UserRole.coach,
);

Widget _wrap(AuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const LoginPage(),
    ),
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.text('Iniciar sesión');
  await tester.ensureVisible(submit);
  await tester.tap(submit);
}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  testWidgets('renders the branded header and welcome copy', (tester) async {
    await tester.pumpWidget(_wrap(repository));

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  testWidgets('shows validation errors for empty fields', (tester) async {
    await tester.pumpWidget(_wrap(repository));

    await _tapSubmit(tester);
    await tester.pump();

    expect(find.text('Introduce tu correo electrónico'), findsOneWidget);
    expect(find.text('Introduce tu contraseña'), findsOneWidget);
    verifyNever(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
  });

  testWidgets('rejects an invalid email format', (tester) async {
    await tester.pumpWidget(_wrap(repository));

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await _tapSubmit(tester);
    await tester.pump();

    expect(find.text('Introduce un correo electrónico válido'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await tester.pumpWidget(_wrap(repository));

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('submits valid credentials to the repository', (tester) async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _user);
    await tester.pumpWidget(_wrap(repository));

    await tester.enterText(
      find.byType(TextFormField).first,
      'coach@club.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await _tapSubmit(tester);
    await tester.pump();

    verify(() => repository.login(
          email: 'coach@club.com',
          password: 'secret123',
        )).called(1);
  });

  testWidgets('surfaces a login error in a SnackBar', (tester) async {
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
    await tester.pumpWidget(_wrap(repository));

    await tester.enterText(
      find.byType(TextFormField).first,
      'coach@club.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await _tapSubmit(tester);
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(SnackBar, 'Credenciales inválidas'),
        findsOneWidget);
  });
}
