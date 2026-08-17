import '../../../../core/usecases/usecase.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

/// Fetches a single team by id.
class GetTeamUseCase implements UseCase<Team, String> {
  const GetTeamUseCase(this.repository);

  final TeamRepository repository;

  @override
  Future<Team> call(String teamId) => repository.getTeam(teamId);
}
