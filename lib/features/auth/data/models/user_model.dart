import '../../domain/entities/user.dart';

/// Maps the backend role strings (`SUPER_ADMIN`, …) to the domain [UserRole]
/// enum, keeping the domain layer free of serialization concerns.
class UserRoleConverter {
  const UserRoleConverter();

  static const Map<String, UserRole> _fromApi = <String, UserRole>{
    'SUPER_ADMIN': UserRole.superAdmin,
    'CLUB_ADMIN': UserRole.clubAdmin,
    'COACH': UserRole.coach,
    'STATISTICIAN': UserRole.statistician,
    'VIEWER': UserRole.viewer,
  };

  static const Map<UserRole, String> _toApi = <UserRole, String>{
    UserRole.superAdmin: 'SUPER_ADMIN',
    UserRole.clubAdmin: 'CLUB_ADMIN',
    UserRole.coach: 'COACH',
    UserRole.statistician: 'STATISTICIAN',
    UserRole.viewer: 'VIEWER',
  };

  UserRole fromJson(String json) {
    final role = _fromApi[json];
    if (role == null) {
      throw FormatException('Unknown user role: $json');
    }
    return role;
  }

  String toJson(UserRole object) => _toApi[object]!;
}

/// Data-layer DTO for a user, aligned with the backend JSON.
///
/// Hand-written (no Freezed) to stay compatible with the installed Dart SDK,
/// mirroring the plain value-object style of the domain entities.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.clubId,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ??
        '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: name,
      role: const UserRoleConverter().fromJson(json['role'] as String),
      clubId: json['clubId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? clubId;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'name': name,
        'role': const UserRoleConverter().toJson(role),
        'clubId': clubId,
        'avatarUrl': avatarUrl,
      };

  /// Maps this DTO to its domain [User] entity.
  User toEntity() => User(
        id: id,
        email: email,
        name: name,
        role: role,
        clubId: clubId,
        avatarUrl: avatarUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.role == role &&
          other.clubId == clubId &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, email, name, role, clubId, avatarUrl);
}
