import '../../../../core/usecases/usecase.dart';
import '../entities/club.dart';
import '../repositories/club_repository.dart';

/// Fetches a single club by id.
class GetClubUseCase implements UseCase<Club, String> {
  const GetClubUseCase(this.repository);

  final ClubRepository repository;

  @override
  Future<Club> call(String clubId) => repository.getClub(clubId);
}
