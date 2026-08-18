import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/models/paginated.dart';
import 'package:hoop_analytics/core/theme/app_theme.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/clubs/domain/entities/club.dart';
import 'package:hoop_analytics/features/clubs/domain/repositories/club_repository.dart';
import 'package:hoop_analytics/features/clubs/presentation/providers/clubs_providers.dart';
import 'package:hoop_analytics/features/users/domain/entities/app_user.dart';
import 'package:hoop_analytics/features/users/domain/repositories/user_repository.dart';
import 'package:hoop_analytics/features/users/presentation/pages/users_page.dart';
import 'package:hoop_analytics/features/users/presentation/providers/users_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockClubRepository extends Mock implements ClubRepository {}

AppUser _user(String id, UserRole role) => AppUser(
      id: id,
      firstName: 'Ana',
      lastName: 'García',
      email: '$id@club.com',
      role: role,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );

Future<void> _pump(
  WidgetTester tester, {
  required UserRepository userRepository,
  ClubRepository? clubRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        if (clubRepository != null)
          clubRepositoryProvider.overrideWithValue(clubRepository),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const UsersPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(UserRole.viewer));

  late _MockUserRepository userRepository;

  setUp(() {
    userRepository = _MockUserRepository();
  });

  testWidgets('renders a user row with role chip and "Sin club"',
      (tester) async {
    when(() => userRepository.getUsers(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        )).thenAnswer(
      (_) async => Paginated<AppUser>(
        items: [_user('u1', UserRole.viewer)],
        page: 1,
        limit: 10,
        total: 1,
      ),
    );

    await _pump(tester, userRepository: userRepository);

    expect(find.text('Ana García'), findsOneWidget);
    expect(find.text('u1@club.com'), findsOneWidget);
    expect(find.text('Espectador'), findsOneWidget);
    expect(find.text('Sin club'), findsOneWidget);
    expect(find.text('Cambiar rol'), findsOneWidget);
    expect(find.text('Asignar club'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no users', (tester) async {
    when(() => userRepository.getUsers(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        )).thenAnswer(
      (_) async => const Paginated<AppUser>(
        items: <AppUser>[],
        page: 1,
        limit: 10,
        total: 0,
      ),
    );

    await _pump(tester, userRepository: userRepository);

    expect(
      find.text('Todavía no hay usuarios registrados.'),
      findsOneWidget,
    );
  });

  testWidgets('"Cambiar rol" opens the role dialog with a warning',
      (tester) async {
    when(() => userRepository.getUsers(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        )).thenAnswer(
      (_) async => Paginated<AppUser>(
        items: [_user('u1', UserRole.viewer)],
        page: 1,
        limit: 10,
        total: 1,
      ),
    );

    await _pump(tester, userRepository: userRepository);
    await tester.tap(find.text('Cambiar rol'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo rol'), findsOneWidget);
    expect(
      find.textContaining('modifica los permisos del usuario'),
      findsOneWidget,
    );
  });

  testWidgets('"Asignar club" loads the clubs into the dialog', (tester) async {
    when(() => userRepository.getUsers(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        )).thenAnswer(
      (_) async => Paginated<AppUser>(
        items: [_user('u1', UserRole.viewer)],
        page: 1,
        limit: 10,
        total: 1,
      ),
    );
    final clubRepository = _MockClubRepository();
    when(() => clubRepository.getClubs(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        )).thenAnswer(
      (_) async => const Paginated<Club>(
        items: [Club(id: 'club-1', name: 'CB Ejemplo')],
        page: 1,
        limit: 100,
        total: 1,
      ),
    );

    await _pump(
      tester,
      userRepository: userRepository,
      clubRepository: clubRepository,
    );
    await tester.tap(find.text('Asignar club'));
    await tester.pumpAndSettle();

    // The dialog loaded the clubs; opening the dropdown reveals the club name.
    expect(find.text('Sin club'), findsWidgets);
    await tester.tap(find.text('Sin club').last);
    await tester.pumpAndSettle();
    expect(find.text('CB Ejemplo'), findsOneWidget);
  });
}
