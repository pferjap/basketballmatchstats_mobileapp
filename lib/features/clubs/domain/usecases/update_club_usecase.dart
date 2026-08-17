import '../../../../core/usecases/usecase.dart';
import '../entities/club.dart';
import '../repositories/club_repository.dart';

/// Parameters for [UpdateClubUseCase].
class UpdateClubArgs {
  const UpdateClubArgs({required this.clubId, required this.params});

  final String clubId;
  final UpdateClubParams params;
}

/// Updates an existing club.
class UpdateClubUseCase implements UseCase<Club, UpdateClubArgs> {
  const UpdateClubUseCase(this.repository);

  final ClubRepository repository;

  @override
  Future<Club> call(UpdateClubArgs args) =>
      repository.updateClub(args.clubId, args.params);
}
