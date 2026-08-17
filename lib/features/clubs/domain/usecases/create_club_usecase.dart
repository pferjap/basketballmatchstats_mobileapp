import '../../../../core/usecases/usecase.dart';
import '../entities/club.dart';
import '../repositories/club_repository.dart';

/// Creates a new club.
class CreateClubUseCase implements UseCase<Club, CreateClubParams> {
  const CreateClubUseCase(this.repository);

  final ClubRepository repository;

  @override
  Future<Club> call(CreateClubParams params) => repository.createClub(params);
}
