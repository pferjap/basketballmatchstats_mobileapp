import '../../../../core/models/paginated.dart';
import '../entities/player.dart';

/// Input for creating a player. Names and [teamId] are required by the backend.
class CreatePlayerParams {
  const CreatePlayerParams({
    required this.firstName,
    required this.lastName,
    required this.teamId,
    this.jerseyNumber,
    this.position,
    this.photoUrl,
    this.birthDate,
    this.height,
    this.weight,
  });

  final String firstName;
  final String lastName;
  final String teamId;
  final int? jerseyNumber;
  final PlayerPosition? position;
  final String? photoUrl;
  final DateTime? birthDate;
  final int? height;
  final int? weight;
}

/// Input for updating a player.
///
/// Every field is optional: only the ones that are non-null are sent, so an
/// omitted field leaves the stored value untouched.
class UpdatePlayerParams {
  const UpdatePlayerParams({
    this.firstName,
    this.lastName,
    this.teamId,
    this.jerseyNumber,
    this.position,
    this.photoUrl,
    this.birthDate,
    this.height,
    this.weight,
  });

  final String? firstName;
  final String? lastName;
  final String? teamId;
  final int? jerseyNumber;
  final PlayerPosition? position;
  final String? photoUrl;
  final DateTime? birthDate;
  final int? height;
  final int? weight;
}

/// CRUD operations for players (Plan.md T-025).
abstract interface class PlayerRepository {
  /// Lists players, paginated. [teamId] restricts the list to one team and
  /// [search] filters by name server-side.
  Future<Paginated<Player>> getPlayers({
    int? page,
    int? limit,
    String? teamId,
    String? search,
  });

  /// Fetches a single player by id.
  Future<Player> getPlayer(String playerId);

  /// Creates a player and returns the persisted entity.
  Future<Player> createPlayer(CreatePlayerParams params);

  /// Updates a player and returns the persisted entity.
  Future<Player> updatePlayer(String playerId, UpdatePlayerParams params);

  /// Permanently removes a player.
  Future<void> deletePlayer(String playerId);

  /// Uploads a new photo for [playerId] and returns the updated player.
  Future<Player> uploadPlayerPhoto(
    String playerId, {
    required List<int> bytes,
    required String filename,
  });
}
