import '../../../../core/usecases/usecase.dart';
import '../repositories/club_repository.dart';

/// Permanently removes a club.
class DeleteClubUseCase implements UseCase<void, String> {
  const DeleteClubUseCase(this.repository);

  final ClubRepository repository;

  @override
  Future<void> call(String clubId) => repository.deleteClub(clubId);
}
