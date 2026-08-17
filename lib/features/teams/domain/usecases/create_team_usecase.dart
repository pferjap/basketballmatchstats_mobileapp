import '../../../../core/usecases/usecase.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

/// Creates a new team.
class CreateTeamUseCase implements UseCase<Team, CreateTeamParams> {
  const CreateTeamUseCase(this.repository);

  final TeamRepository repository;

  @override
  Future<Team> call(CreateTeamParams params) => repository.createTeam(params);
}
