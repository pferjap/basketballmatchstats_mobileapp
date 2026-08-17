import '../../../../core/models/paginated.dart';
import '../entities/team.dart';

/// Input for creating a team. [name] and [clubId] are required by the backend.
class CreateTeamParams {
  const CreateTeamParams({
    required this.name,
    required this.clubId,
    this.category,
    this.logoUrl,
    this.seasonId,
  });

  final String name;
  final String clubId;
  final String? category;
  final String? logoUrl;
  final String? seasonId;
}

/// Input for updating a team.
///
/// Every field is optional: only the ones that are non-null are sent, so an
/// omitted field leaves the stored value untouched.
class UpdateTeamParams {
  const UpdateTeamParams({
    this.name,
    this.clubId,
    this.category,
    this.logoUrl,
    this.seasonId,
  });

  final String? name;
  final String? clubId;
  final String? category;
  final String? logoUrl;
  final String? seasonId;
}

/// CRUD operations for teams (Plan.md T-024).
abstract interface class TeamRepository {
  /// Lists teams, paginated. [clubId] restricts the list to one club and
  /// [search] filters by name server-side.
  Future<Paginated<Team>> getTeams({
    int? page,
    int? limit,
    String? clubId,
    String? search,
  });

  /// Fetches a single team by id.
  Future<Team> getTeam(String teamId);

  /// Creates a team and returns the persisted entity.
  Future<Team> createTeam(CreateTeamParams params);

  /// Updates a team and returns the persisted entity.
  Future<Team> updateTeam(String teamId, UpdateTeamParams params);

  /// Permanently removes a team.
  Future<void> deleteTeam(String teamId);
}
