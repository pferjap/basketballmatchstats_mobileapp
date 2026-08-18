import '../../../../core/models/paginated.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_remote_datasource.dart';
import '../models/team_model.dart';

/// REST-backed implementation of [TeamRepository] (Plan.md T-024).
class TeamRepositoryImpl implements TeamRepository {
  const TeamRepositoryImpl({required this.remote});

  final TeamRemoteDataSource remote;

  @override
  Future<Paginated<Team>> getTeams({
    int? page,
    int? limit,
    String? clubId,
    String? search,
  }) async {
    final result = await remote.getTeams(
      page: page,
      limit: limit,
      clubId: clubId,
      search: search,
    );
    return Paginated<Team>(
      items: result.items
          .map((TeamModel t) => t.toEntity())
          .toList(growable: false),
      page: result.meta?.page,
      limit: result.meta?.limit,
      total: result.meta?.total,
    );
  }

  @override
  Future<Team> getTeam(String teamId) async {
    final model = await remote.getTeam(teamId);
    return model.toEntity();
  }

  @override
  Future<Team> createTeam(CreateTeamParams params) async {
    final model = await remote.createTeam(<String, dynamic>{
      'name': params.name,
      'clubId': params.clubId,
      'category': ?params.category,
      'logoUrl': ?params.logoUrl,
      'seasonId': ?params.seasonId,
    });
    return model.toEntity();
  }

  @override
  Future<Team> updateTeam(String teamId, UpdateTeamParams params) async {
    // Only non-null fields travel, so an omitted field leaves the stored value
    // untouched rather than being cleared.
    final model = await remote.updateTeam(teamId, <String, dynamic>{
      'name': ?params.name,
      'clubId': ?params.clubId,
      'category': ?params.category,
      'logoUrl': ?params.logoUrl,
      'seasonId': ?params.seasonId,
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteTeam(String teamId) => remote.deleteTeam(teamId);

  @override
  Future<Team> uploadTeamLogo(
    String teamId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final model = await remote.uploadLogo(
      teamId,
      bytes: bytes,
      filename: filename,
    );
    return model.toEntity();
  }
}
