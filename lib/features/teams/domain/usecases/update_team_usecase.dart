import '../../../../core/usecases/usecase.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

/// Parameters for [UpdateTeamUseCase].
class UpdateTeamArgs {
  const UpdateTeamArgs({required this.teamId, required this.params});

  final String teamId;
  final UpdateTeamParams params;
}

/// Updates an existing team.
class UpdateTeamUseCase implements UseCase<Team, UpdateTeamArgs> {
  const UpdateTeamUseCase(this.repository);

  final TeamRepository repository;

  @override
  Future<Team> call(UpdateTeamArgs args) =>
      repository.updateTeam(args.teamId, args.params);
}
