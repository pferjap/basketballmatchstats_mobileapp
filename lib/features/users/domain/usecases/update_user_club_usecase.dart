import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/user_repository.dart';

/// Parameters for [UpdateUserClubUseCase].
class UpdateUserClubParams {
  const UpdateUserClubParams({required this.userId, required this.clubId});

  final String userId;

  /// Target club, or `null` to unassign the user from any club.
  final String? clubId;
}

/// Associates a user with a club, or clears it (`PATCH /users/:id/club`).
class UpdateUserClubUseCase implements UseCase<AppUser, UpdateUserClubParams> {
  const UpdateUserClubUseCase(this.repository);

  final UserRepository repository;

  @override
  Future<AppUser> call(UpdateUserClubParams params) =>
      repository.updateUserClub(params.userId, params.clubId);
}
