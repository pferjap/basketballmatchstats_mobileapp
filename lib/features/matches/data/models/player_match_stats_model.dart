import '../../domain/entities/player_match_stats.dart';

/// Data-layer DTO for a player's aggregated box-score line.
class PlayerMatchStatsModel {
  const PlayerMatchStatsModel({
    required this.playerId,
    required this.points,
    required this.rebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.turnovers,
    required this.fouls,
    required this.minutes,
  });

  factory PlayerMatchStatsModel.fromJson(Map<String, dynamic> json) =>
      PlayerMatchStatsModel(
        playerId: json['playerId'] as String,
        points: (json['points'] as num?)?.toInt() ?? 0,
        rebounds: (json['rebounds'] as num?)?.toInt() ?? 0,
        assists: (json['assists'] as num?)?.toInt() ?? 0,
        steals: (json['steals'] as num?)?.toInt() ?? 0,
        blocks: (json['blocks'] as num?)?.toInt() ?? 0,
        turnovers: (json['turnovers'] as num?)?.toInt() ?? 0,
        fouls: (json['fouls'] as num?)?.toInt() ?? 0,
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      );

  final String playerId;
  final int points;
  final int rebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;
  final int fouls;
  final int minutes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'playerId': playerId,
        'points': points,
        'rebounds': rebounds,
        'assists': assists,
        'steals': steals,
        'blocks': blocks,
        'turnovers': turnovers,
        'fouls': fouls,
        'minutes': minutes,
      };

  PlayerMatchStats toEntity() => PlayerMatchStats(
        playerId: playerId,
        points: points,
        rebounds: rebounds,
        assists: assists,
        steals: steals,
        blocks: blocks,
        turnovers: turnovers,
        fouls: fouls,
        minutes: minutes,
      );
}
