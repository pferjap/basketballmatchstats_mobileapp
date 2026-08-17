import '../../../../core/models/paginated.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/team.dart';
import '../repositories/team_repository.dart';

/// Parameters for [GetTeamsUseCase].
class GetTeamsParams {
  const GetTeamsParams({this.page, this.limit, this.clubId, this.search});

  final int? page;
  final int? limit;

  /// Restricts the list to a single club.
  final String? clubId;

  /// Free-text name filter applied by the backend.
  final String? search;
}

/// Fetches a paginated list of teams.
class GetTeamsUseCase implements UseCase<Paginated<Team>, GetTeamsParams> {
  const GetTeamsUseCase(this.repository);

  final TeamRepository repository;

  @override
  Future<Paginated<Team>> call(GetTeamsParams params) => repository.getTeams(
    page: params.page,
    limit: params.limit,
    clubId: params.clubId,
    search: params.search,
  );
}
