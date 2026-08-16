import '../../domain/entities/match_score.dart';

/// Data-layer DTO for the live scoreboard, aligned with the backend JSON.
class MatchScoreModel {
  const MatchScoreModel({
    required this.matchId,
    required this.homeTeamScore,
    required this.awayTeamScore,
    required this.currentPeriod,
    required this.gameClock,
  });

  factory MatchScoreModel.fromJson(Map<String, dynamic> json) =>
      MatchScoreModel(
        matchId: json['matchId'] as String,
        homeTeamScore: (json['homeTeamScore'] as num).toInt(),
        awayTeamScore: (json['awayTeamScore'] as num).toInt(),
        currentPeriod: (json['currentPeriod'] as num).toInt(),
        gameClock: json['gameClock'] as String,
      );

  final String matchId;
  final int homeTeamScore;
  final int awayTeamScore;
  final int currentPeriod;
  final String gameClock;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'matchId': matchId,
        'homeTeamScore': homeTeamScore,
        'awayTeamScore': awayTeamScore,
        'currentPeriod': currentPeriod,
        'gameClock': gameClock,
      };

  MatchScore toEntity() => MatchScore(
        matchId: matchId,
        homeTeamScore: homeTeamScore,
        awayTeamScore: awayTeamScore,
        currentPeriod: currentPeriod,
        gameClock: gameClock,
      );
}
