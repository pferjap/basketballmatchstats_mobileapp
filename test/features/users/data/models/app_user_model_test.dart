import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';
import 'package:hoop_analytics/features/users/data/models/app_user_model.dart';

void main() {
  final json = <String, dynamic>{
    'id': 'u1',
    'email': 'ana@club.com',
    'firstName': 'Ana',
    'lastName': 'García',
    'role': 'STATISTICIAN',
    'clubId': 'club-7',
    'clubName': 'CB Ejemplo',
    'createdAt': '2026-08-10T12:00:00.000Z',
  };

  test('fromJson parses every field, including createdAt and clubName', () {
    final model = AppUserModel.fromJson(json);

    expect(model.id, 'u1');
    expect(model.email, 'ana@club.com');
    expect(model.firstName, 'Ana');
    expect(model.lastName, 'García');
    expect(model.role, UserRole.statistician);
    expect(model.clubId, 'club-7');
    expect(model.clubName, 'CB Ejemplo');
    expect(model.createdAt, DateTime.parse('2026-08-10T12:00:00.000Z'));
    expect(model.avatarUrl, isNull);
  });

  test('toEntity maps to the domain AppUser with derived helpers', () {
    final user = AppUserModel.fromJson(json).toEntity();

    expect(user.fullName, 'Ana García');
    expect(user.initials, 'AG');
    expect(user.role, UserRole.statistician);
    expect(user.clubName, 'CB Ejemplo');
  });

  test('missing clubId/clubName parse as null (post sign-up VIEWER)', () {
    final model = AppUserModel.fromJson(<String, dynamic>{
      'id': 'u2',
      'email': 'new@club.com',
      'firstName': 'New',
      'lastName': 'User',
      'role': 'VIEWER',
      'clubId': null,
      'clubName': null,
      'createdAt': '2026-08-18T09:00:00.000Z',
    });

    expect(model.role, UserRole.viewer);
    expect(model.clubId, isNull);
    expect(model.clubName, isNull);
    expect(model.toEntity().initials, 'NU');
  });
}
