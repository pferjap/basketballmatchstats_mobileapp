import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/auth/data/models/user_model.dart';
import 'package:hoop_analytics/features/auth/domain/entities/user.dart';

void main() {
  group('UserRoleConverter', () {
    const converter = UserRoleConverter();

    test('maps every backend role string to its domain enum', () {
      expect(converter.fromJson('SUPER_ADMIN'), UserRole.superAdmin);
      expect(converter.fromJson('CLUB_ADMIN'), UserRole.clubAdmin);
      expect(converter.fromJson('COACH'), UserRole.coach);
      expect(converter.fromJson('STATISTICIAN'), UserRole.statistician);
      expect(converter.fromJson('VIEWER'), UserRole.viewer);
    });

    test('serializes every domain enum back to its backend string', () {
      expect(converter.toJson(UserRole.superAdmin), 'SUPER_ADMIN');
      expect(converter.toJson(UserRole.clubAdmin), 'CLUB_ADMIN');
      expect(converter.toJson(UserRole.coach), 'COACH');
      expect(converter.toJson(UserRole.statistician), 'STATISTICIAN');
      expect(converter.toJson(UserRole.viewer), 'VIEWER');
    });

    test('throws FormatException on an unknown role', () {
      expect(
        () => converter.fromJson('GALAXY_OVERLORD'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('UserModel', () {
    test('fromJson parses all fields including the role converter', () {
      final model = UserModel.fromJson(<String, dynamic>{
        'id': 'u1',
        'email': 'coach@club.com',
        'name': 'Coach Carter',
        'role': 'COACH',
        'clubId': 'club-7',
        'avatarUrl': 'https://cdn/avatar.png',
      });

      expect(model.id, 'u1');
      expect(model.email, 'coach@club.com');
      expect(model.name, 'Coach Carter');
      expect(model.role, UserRole.coach);
      expect(model.clubId, 'club-7');
      expect(model.avatarUrl, 'https://cdn/avatar.png');
    });

    test('fromJson tolerates missing optional fields', () {
      final model = UserModel.fromJson(<String, dynamic>{
        'id': 'u2',
        'email': 'admin@ha.com',
        'name': 'Super',
        'role': 'SUPER_ADMIN',
      });

      expect(model.clubId, isNull);
      expect(model.avatarUrl, isNull);
      expect(model.role, UserRole.superAdmin);
    });

    test('toEntity maps the DTO to the domain User', () {
      const model = UserModel(
        id: 'u3',
        email: 'stat@club.com',
        name: 'Stat Keeper',
        role: UserRole.statistician,
        clubId: 'club-3',
      );

      expect(
        model.toEntity(),
        const User(
          id: 'u3',
          email: 'stat@club.com',
          name: 'Stat Keeper',
          role: UserRole.statistician,
          clubId: 'club-3',
        ),
      );
    });

    test('toJson round-trips the role back to the backend string', () {
      const model = UserModel(
        id: 'u4',
        email: 'viewer@club.com',
        name: 'Viewer',
        role: UserRole.viewer,
      );

      expect(model.toJson()['role'], 'VIEWER');
    });
  });
}
