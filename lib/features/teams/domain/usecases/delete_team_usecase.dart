import '../../../../core/usecases/usecase.dart';
import '../repositories/team_repository.dart';

/// Permanently removes a team.
class DeleteTeamUseCase implements UseCase<void, String> {
  const DeleteTeamUseCase(this.repository);

  final TeamRepository repository;

  @override
  Future<void> call(String teamId) => repository.deleteTeam(teamId);
}
