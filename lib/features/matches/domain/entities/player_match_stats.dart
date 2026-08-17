/// Aggregated box-score line for one player in a match.
///
/// Plain, dependency-free value object; data-layer models map into this via
/// their `toEntity()` methods.
class PlayerMatchStats {
  const PlayerMatchStats({
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

  final String playerId;
  final int points;
  final int rebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;
  final int fouls;

  /// Minutes played.
  final int minutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerMatchStats &&
          other.playerId == playerId &&
          other.points == points &&
          other.rebounds == rebounds &&
          other.assists == assists &&
          other.steals == steals &&
          other.blocks == blocks &&
          other.turnovers == turnovers &&
          other.fouls == fouls &&
          other.minutes == minutes;

  @override
  int get hashCode => Object.hash(
    playerId,
    points,
    rebounds,
    assists,
    steals,
    blocks,
    turnovers,
    fouls,
    minutes,
  );

  @override
  String toString() =>
      'PlayerMatchStats(playerId: $playerId, pts: $points, reb: $rebounds, '
      'ast: $assists)';
}
