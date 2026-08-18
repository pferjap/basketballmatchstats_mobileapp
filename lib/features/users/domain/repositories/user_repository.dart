import '../../../../core/models/paginated.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/app_user.dart';

/// Reads and mutates registered users for the admin screens (Plan.md T-032).
///
/// Backed by the REST API's `users` module; errors surface as `AppException`
/// subtypes. `getUsers` returns the newest accounts first, as the backend
/// orders by `createdAt desc`.
abstract interface class UserRepository {
  /// Lists users, paginated. [search] filters by name/email server-side.
  Future<Paginated<AppUser>> getUsers({int? page, int? limit, String? search});

  /// Changes [userId]'s role (`PATCH /users/:id/role`) and returns the updated
  /// user. SUPER_ADMIN cannot be assigned from here.
  Future<AppUser> updateUserRole(String userId, UserRole role);

  /// Associates [userId] with [clubId] (`PATCH /users/:id/club`), or clears it
  /// when [clubId] is `null`, and returns the updated user.
  Future<AppUser> updateUserClub(String userId, String? clubId);
}
