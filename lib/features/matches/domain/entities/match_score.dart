/// Live scoreboard state for a match.
///
/// Plain, dependency-free value object; data-layer models map into this via
/// their `toEntity()` methods.
class MatchScore {
  const MatchScore({
    required this.matchId,
    required this.homeTeamScore,
    required this.awayTeamScore,
    required this.currentPeriod,
    required this.gameClock,
  });

  final String matchId;
  final int homeTeamScore;
  final int awayTeamScore;

  /// Current period: 1–4 for regulation, 5+ for overtime.
  final int currentPeriod;

  /// Remaining game clock formatted as `mm:ss`.
  final String gameClock;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchScore &&
          other.matchId == matchId &&
          other.homeTeamScore == homeTeamScore &&
          other.awayTeamScore == awayTeamScore &&
          other.currentPeriod == currentPeriod &&
          other.gameClock == gameClock;

  @override
  int get hashCode => Object.hash(
    matchId,
    homeTeamScore,
    awayTeamScore,
    currentPeriod,
    gameClock,
  );

  @override
  String toString() =>
      'MatchScore(matchId: $matchId, $homeTeamScore-$awayTeamScore, '
      'period: $currentPeriod, clock: $gameClock)';
}
