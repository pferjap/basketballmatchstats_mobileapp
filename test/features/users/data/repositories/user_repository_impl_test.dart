import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/api_response_parser.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/users/data/datasources/user_remote_datasource.dart';
import 'package:hoop_analytics/features/users/data/models/app_user_model.dart';
import 'package:hoop_analytics/features/users/data/repositories/user_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements UserRemoteDataSource {}

AppUserModel _model(String id, UserRole role) => AppUserModel(
      id: id,
      firstName: 'Ana',
      lastName: 'García',
      email: '$id@club.com',
      role: role,
      createdAt: DateTime.parse('2026-08-10T12:00:00.000Z'),
    );

void main() {
  late _MockRemote remote;
  late UserRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = UserRepositoryImpl(remote: remote);
  });

  group('getUsers', () {
    test('maps the DTO page and pagination meta to domain entities', () async {
      when(() => remote.getUsers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
          )).thenAnswer(
        (_) async => (
          items: <AppUserModel>[_model('u1', UserRole.viewer)],
          meta: const ApiMeta(page: 1, limit: 10, total: 1),
        ),
      );

      final result = await repository.getUsers(page: 1, limit: 10);

      expect(result.items.single.id, 'u1');
      expect(result.items.single.role, UserRole.viewer);
      expect(result.page, 1);
      expect(result.total, 1);
    });
  });

  group('updateUserRole', () {
    test('sends the API role string and returns the updated entity', () async {
      when(() => remote.updateRole(any(), any()))
          .thenAnswer((_) async => _model('u1', UserRole.statistician));

      final user =
          await repository.updateUserRole('u1', UserRole.statistician);

      expect(user.role, UserRole.statistician);
      verify(() => remote.updateRole('u1', 'STATISTICIAN')).called(1);
    });
  });

  group('updateUserClub', () {
    test('forwards the club id and returns the updated entity', () async {
      when(() => remote.updateClub(any(), any()))
          .thenAnswer((_) async => _model('u1', UserRole.viewer));

      await repository.updateUserClub('u1', 'club-9');

      verify(() => remote.updateClub('u1', 'club-9')).called(1);
    });

    test('supports clearing the club with a null id', () async {
      when(() => remote.updateClub(any(), any()))
          .thenAnswer((_) async => _model('u1', UserRole.viewer));

      await repository.updateUserClub('u1', null);

      verify(() => remote.updateClub('u1', null)).called(1);
    });
  });
}
