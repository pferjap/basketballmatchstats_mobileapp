import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoop_analytics/core/error/exceptions.dart';
import 'package:hoop_analytics/core/models/paginated.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/users/domain/entities/app_user.dart';
import 'package:hoop_analytics/features/users/domain/repositories/user_repository.dart';
import 'package:hoop_analytics/features/users/presentation/providers/users_admin_provider.dart';
import 'package:hoop_analytics/features/users/presentation/providers/users_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserRepository extends Mock implements UserRepository {}

AppUser _user(String id, UserRole role) => AppUser(
      id: id,
      firstName: 'Ana',
      lastName: 'García',
      email: '$id@club.com',
      role: role,
      createdAt: DateTime.parse('2026-08-10T12:00:00.000Z'),
    );

Paginated<AppUser> _page(List<AppUser> users) => Paginated<AppUser>(
      items: users,
      page: 1,
      limit: kUsersPageSize,
      total: users.length,
    );

void main() {
  setUpAll(() => registerFallbackValue(UserRole.viewer));

  late _MockUserRepository repository;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repository = _MockUserRepository();
    when(() => repository.getUsers(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          search: any(named: 'search'),
        )).thenAnswer((_) async => _page([_user('u1', UserRole.viewer)]));
  });

  test('loadUsers populates the list and pagination', () async {
    final container = makeContainer();
    final controller = container.read(usersAdminControllerProvider.notifier);

    await controller.loadUsers();

    final state = container.read(usersAdminControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.users.single.id, 'u1');
    expect(state.total, 1);
  });

  test('setSearch forwards the query and resets to page 1', () async {
    final container = makeContainer();
    final controller = container.read(usersAdminControllerProvider.notifier);

    await controller.setSearch('ana');

    verify(() => repository.getUsers(
          page: 1,
          limit: kUsersPageSize,
          search: 'ana',
        )).called(greaterThanOrEqualTo(1));
  });

  test('changeRole delegates to the repository and reloads', () async {
    when(() => repository.updateUserRole(any(), any()))
        .thenAnswer((_) async => _user('u1', UserRole.statistician));
    final container = makeContainer();
    final controller = container.read(usersAdminControllerProvider.notifier);
    await controller.loadUsers();

    final error = await controller.changeRole('u1', UserRole.statistician);

    expect(error, isNull);
    verify(() => repository.updateUserRole('u1', UserRole.statistician))
        .called(1);
  });

  test('changeRole surfaces the backend error message', () async {
    when(() => repository.updateUserRole(any(), any())).thenThrow(
      const ServerException(
        message: 'No puedes modificar tu propio rol',
        code: 'CANNOT_MODIFY_OWN_ROLE',
        statusCode: 403,
      ),
    );
    final container = makeContainer();
    final controller = container.read(usersAdminControllerProvider.notifier);
    await controller.loadUsers();

    final error = await controller.changeRole('u1', UserRole.clubAdmin);

    expect(error, 'No puedes modificar tu propio rol');
  });

  test('assignClub forwards the club id (and null clears it)', () async {
    when(() => repository.updateUserClub(any(), any()))
        .thenAnswer((_) async => _user('u1', UserRole.viewer));
    final container = makeContainer();
    final controller = container.read(usersAdminControllerProvider.notifier);
    await controller.loadUsers();

    await controller.assignClub('u1', 'club-9');
    await controller.assignClub('u1', null);

    verify(() => repository.updateUserClub('u1', 'club-9')).called(1);
    verify(() => repository.updateUserClub('u1', null)).called(1);
  });
}
