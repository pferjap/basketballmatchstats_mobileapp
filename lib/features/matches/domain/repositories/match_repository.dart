import '../../../../core/models/paginated.dart';
import '../entities/match.dart';
import '../entities/match_event.dart';
import '../entities/match_statistics.dart';

/// Input for scheduling a match. Both teams and a kick-off time are required.
class CreateMatchParams {
  const CreateMatchParams({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.scheduledAt,
    this.competitionId,
    this.seasonId,
    this.venue,
  });

  final String homeTeamId;
  final String awayTeamId;
  final DateTime scheduledAt;
  final String? competitionId;
  final String? seasonId;
  final String? venue;
}

/// Input for updating a scheduled match.
///
/// Every field is optional: only the ones that are non-null are sent, so an
/// omitted field leaves the stored value untouched.
class UpdateMatchParams {
  const UpdateMatchParams({
    this.homeTeamId,
    this.awayTeamId,
    this.scheduledAt,
    this.competitionId,
    this.seasonId,
    this.venue,
  });

  final String? homeTeamId;
  final String? awayTeamId;
  final DateTime? scheduledAt;
  final String? competitionId;
  final String? seasonId;
  final String? venue;
}

/// Read/lifecycle operations for matches (Agent_Mobile §7.1).
///
/// Implementations coordinate the REST datasource, the WebSocket read channel
/// and the local cache. Errors surface as `AppException` subtypes.
abstract interface class MatchRepository {
  /// Lists matches, newest first, paginated.
  Future<Paginated<Match>> getMatches({int? page, int? limit});

  /// Fetches a single match by id.
  Future<Match> getMatch(String matchId);

  /// Starts a scheduled match (`POST /matches/:id/start`).
  Future<Match> startMatch(String matchId);

  /// Schedules a new match (`POST /matches`) — admin panel (Plan.md T-030).
  Future<Match> createMatch(CreateMatchParams params);

  /// Updates a match's scheduling details (`PUT /matches/:id`).
  Future<Match> updateMatch(String matchId, UpdateMatchParams params);

  /// Permanently removes a match (`DELETE /matches/:id`).
  Future<void> deleteMatch(String matchId);

  /// Fetches the aggregated statistics (score + player lines) for a match.
  Future<MatchStatistics> getMatchStatistics(String matchId);

  /// Lists a match's events, paginated. When [since] is provided, only events
  /// created after that timestamp are returned (§7.3 reconciliation).
  Future<Paginated<MatchEvent>> getMatchEvents(
    String matchId, {
    DateTime? since,
    int? page,
    int? limit,
  });
}
