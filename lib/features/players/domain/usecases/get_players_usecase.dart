import '../../../../core/models/paginated.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

/// Parameters for [GetPlayersUseCase].
class GetPlayersParams {
  const GetPlayersParams({this.page, this.limit, this.teamId, this.search});

  final int? page;
  final int? limit;

  /// Restricts the list to a single team.
  final String? teamId;

  /// Free-text name filter applied by the backend.
  final String? search;
}

/// Fetches a paginated list of players.
class GetPlayersUseCase
    implements UseCase<Paginated<Player>, GetPlayersParams> {
  const GetPlayersUseCase(this.repository);

  final PlayerRepository repository;

  @override
  Future<Paginated<Player>> call(GetPlayersParams params) =>
      repository.getPlayers(
        page: params.page,
        limit: params.limit,
        teamId: params.teamId,
        search: params.search,
      );
}
