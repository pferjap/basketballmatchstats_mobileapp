import '../../../auth/domain/entities/user.dart';

/// A registered user as seen by the users-management screens (Plan.md T-032).
///
/// Mirrors the backend `UserResponseDto` (`GET /users`, `PATCH /users/:id/*`).
/// [UserRole] is reused from the auth feature so role handling stays in one
/// place. Plain, dependency-free value object; the data-layer model maps into
/// this via its `toEntity()`.
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.clubId,
    this.clubName,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;

  /// When the account was created; used for the "más recientes primero" order
  /// and the "Registrado hace N días" label.
  final DateTime createdAt;

  /// Club the user belongs to; `null` right after sign-up (backend sets it).
  final String? clubId;

  /// Human-readable club name, when the user is associated with one.
  final String? clubName;
  final String? avatarUrl;

  /// Full display name, e.g. "Carlos Núñez".
  String get fullName => '$firstName $lastName'.trim();

  /// Uppercase initials for the avatar fallback, e.g. "CN".
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    final buffer = StringBuffer();
    if (first.isNotEmpty) buffer.write(first.substring(0, 1));
    if (last.isNotEmpty) buffer.write(last.substring(0, 1));
    final result = buffer.toString().toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  AppUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    String? clubId,
    String? clubName,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.email == email &&
          other.role == role &&
          other.createdAt == createdAt &&
          other.clubId == clubId &&
          other.clubName == clubName &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(
        id,
        firstName,
        lastName,
        email,
        role,
        createdAt,
        clubId,
        clubName,
        avatarUrl,
      );
}
