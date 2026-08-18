import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/app_user.dart';
import '../repositories/user_repository.dart';

/// Parameters for [UpdateUserRoleUseCase].
class UpdateUserRoleParams {
  const UpdateUserRoleParams({required this.userId, required this.role});

  final String userId;
  final UserRole role;
}

/// Elevates or lowers a user's role (`PATCH /users/:id/role`).
class UpdateUserRoleUseCase implements UseCase<AppUser, UpdateUserRoleParams> {
  const UpdateUserRoleUseCase(this.repository);

  final UserRepository repository;

  @override
  Future<AppUser> call(UpdateUserRoleParams params) =>
      repository.updateUserRole(params.userId, params.role);
}
