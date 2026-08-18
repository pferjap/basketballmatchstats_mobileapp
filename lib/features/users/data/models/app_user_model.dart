import '../../../auth/data/models/user_model.dart' show UserRoleConverter;
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/app_user.dart';

/// Data-layer DTO for a user, aligned with the backend `UserResponseDto`
/// (`id`, `email`, `firstName`, `lastName`, `role`, `clubId`, `clubName`,
/// `createdAt`). `avatarUrl` is parsed defensively in case the backend adds it.
///
/// Hand-written (no Freezed) to match the plain value-object style used across
/// the app, and reusing [UserRoleConverter] from the auth feature.
class AppUserModel {
  const AppUserModel({
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

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String,
      role: const UserRoleConverter().fromJson(json['role'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      clubId: json['clubId'] as String?,
      clubName: json['clubName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? clubId;
  final String? clubName;
  final String? avatarUrl;

  /// Maps this DTO to its domain [AppUser] entity.
  AppUser toEntity() => AppUser(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        createdAt: createdAt,
        clubId: clubId,
        clubName: clubName,
        avatarUrl: avatarUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUserModel &&
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
