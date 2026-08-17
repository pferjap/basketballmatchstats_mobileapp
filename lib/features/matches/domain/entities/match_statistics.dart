import 'match_score.dart';
import 'player_match_stats.dart';

/// Full statistics snapshot for a match: the live score plus per-player lines.
///
/// Returned by `GET /matches/:id/statistics` (Agent_Mobile §7.1).
class MatchStatistics {
  const MatchStatistics({required this.score, required this.playerStats});

  final MatchScore score;
  final List<PlayerMatchStats> playerStats;

  @override
  String toString() =>
      'MatchStatistics(score: $score, players: ${playerStats.length})';
}
