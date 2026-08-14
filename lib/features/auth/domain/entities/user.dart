/// Role of a user, mirroring the backend roles (Agent_Mobile.md §13).
enum UserRole { superAdmin, clubAdmin, coach, statistician, viewer }

/// Authenticated user in the domain layer.
///
/// Plain, dependency-free value object; data-layer models map into this via
/// their `toEntity()` methods.
class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.clubId,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;

  /// Club the user belongs to; `null` for club-agnostic roles (e.g. super admin).
  final String? clubId;
  final String? avatarUrl;

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? clubId,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      clubId: clubId ?? this.clubId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.role == role &&
          other.clubId == clubId &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode =>
      Object.hash(id, email, name, role, clubId, avatarUrl);

  @override
  String toString() =>
      'User(id: $id, email: $email, name: $name, role: $role, '
      'clubId: $clubId)';
}
