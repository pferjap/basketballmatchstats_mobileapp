import '../../../../core/models/paginated.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_remote_datasource.dart';
import '../models/player_model.dart';

/// REST-backed implementation of [PlayerRepository] (Plan.md T-025).
class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl({required this.remote});

  final PlayerRemoteDataSource remote;

  static const PlayerPositionConverter _position = PlayerPositionConverter();

  @override
  Future<Paginated<Player>> getPlayers({
    int? page,
    int? limit,
    String? teamId,
    String? search,
  }) async {
    final result = await remote.getPlayers(
      page: page,
      limit: limit,
      teamId: teamId,
      search: search,
    );
    return Paginated<Player>(
      items: result.items
          .map((PlayerModel p) => p.toEntity())
          .toList(growable: false),
      page: result.meta?.page,
      limit: result.meta?.limit,
      total: result.meta?.total,
    );
  }

  @override
  Future<Player> getPlayer(String playerId) async {
    final model = await remote.getPlayer(playerId);
    return model.toEntity();
  }

  @override
  Future<Player> createPlayer(CreatePlayerParams params) async {
    final position = params.position;
    final model = await remote.createPlayer(<String, dynamic>{
      'firstName': params.firstName,
      'lastName': params.lastName,
      'teamId': params.teamId,
      'jerseyNumber': ?params.jerseyNumber,
      'position': ?(position == null ? null : _position.toJson(position)),
      'photoUrl': ?params.photoUrl,
      'birthDate': ?params.birthDate?.toUtc().toIso8601String(),
      'height': ?params.height,
      'weight': ?params.weight,
    });
    return model.toEntity();
  }

  @override
  Future<Player> updatePlayer(
    String playerId,
    UpdatePlayerParams params,
  ) async {
    // Only non-null fields travel, so an omitted field leaves the stored value
    // untouched rather than being cleared.
    final position = params.position;
    final model = await remote.updatePlayer(playerId, <String, dynamic>{
      'firstName': ?params.firstName,
      'lastName': ?params.lastName,
      'teamId': ?params.teamId,
      'jerseyNumber': ?params.jerseyNumber,
      'position': ?(position == null ? null : _position.toJson(position)),
      'photoUrl': ?params.photoUrl,
      'birthDate': ?params.birthDate?.toUtc().toIso8601String(),
      'height': ?params.height,
      'weight': ?params.weight,
    });
    return model.toEntity();
  }

  @override
  Future<void> deletePlayer(String playerId) => remote.deletePlayer(playerId);

  @override
  Future<Player> uploadPlayerPhoto(
    String playerId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final model = await remote.uploadPhoto(
      playerId,
      bytes: bytes,
      filename: filename,
    );
    return model.toEntity();
  }
}
