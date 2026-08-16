import '../../../../core/models/paginated.dart';
import '../entities/match.dart';
import '../entities/match_event.dart';
import '../entities/match_statistics.dart';

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
