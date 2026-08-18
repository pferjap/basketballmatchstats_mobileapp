import '../../../../core/models/paginated.dart';
import '../../../auth/data/models/user_model.dart' show UserRoleConverter;
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/app_user_model.dart';

/// REST-backed implementation of [UserRepository] (Plan.md T-032).
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl({required this.remote});

  final UserRemoteDataSource remote;

  @override
  Future<Paginated<AppUser>> getUsers({
    int? page,
    int? limit,
    String? search,
  }) async {
    final result = await remote.getUsers(
      page: page,
      limit: limit,
      search: search,
    );
    return Paginated<AppUser>(
      items: result.items
          .map((AppUserModel u) => u.toEntity())
          .toList(growable: false),
      page: result.meta?.page,
      limit: result.meta?.limit,
      total: result.meta?.total,
    );
  }

  @override
  Future<AppUser> updateUserRole(String userId, UserRole role) async {
    final model = await remote.updateRole(
      userId,
      const UserRoleConverter().toJson(role),
    );
    return model.toEntity();
  }

  @override
  Future<AppUser> updateUserClub(String userId, String? clubId) async {
    final model = await remote.updateClub(userId, clubId);
    return model.toEntity();
  }
}
