import '../../domain/entities/match_statistics.dart';
import 'match_score_model.dart';
import 'player_match_stats_model.dart';

/// Data-layer DTO for `GET /matches/:id/statistics`: the score plus the
/// per-player box-score lines.
///
/// The endpoint returns `{ matchScore: {...}, playerStats: [...] }`; the score
/// fields are also accepted at the top level for resilience.
class MatchStatisticsModel {
  const MatchStatisticsModel({
    required this.score,
    required this.playerStats,
  });

  factory MatchStatisticsModel.fromJson(Map<String, dynamic> json) {
    final scoreJson = json['matchScore'] ?? json['score'] ?? json;
    final players = json['playerStats'] ?? json['players'] ?? const <dynamic>[];
    return MatchStatisticsModel(
      score: MatchScoreModel.fromJson(
        (scoreJson as Map).cast<String, dynamic>(),
      ),
      playerStats: (players as List)
          .map((dynamic e) => PlayerMatchStatsModel.fromJson(
                (e as Map).cast<String, dynamic>(),
              ))
          .toList(growable: false),
    );
  }

  final MatchScoreModel score;
  final List<PlayerMatchStatsModel> playerStats;

  MatchStatistics toEntity() => MatchStatistics(
        score: score.toEntity(),
        playerStats:
            playerStats.map((e) => e.toEntity()).toList(growable: false),
      );
}
