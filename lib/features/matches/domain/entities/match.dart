/// Lifecycle state of a match, mirroring the backend status enum.
///
/// The API string representation lives in the data layer
/// (`data/models/match_model.dart` — `MatchStatusConverter`).
enum MatchStatus { scheduled, inProgress, finished }

/// A basketball match in the domain layer.
///
/// Plain, dependency-free value object; data-layer models map into this via
/// their `toEntity()` methods.
class Match {
  const Match({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.status,
    required this.scheduledAt,
    this.competitionId,
    this.seasonId,
    this.startedAt,
    this.finishedAt,
    this.venue,
  });

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final MatchStatus status;
  final DateTime scheduledAt;
  final String? competitionId;
  final String? seasonId;

  /// Set once the match transitions to [MatchStatus.inProgress].
  final DateTime? startedAt;

  /// Set once the match transitions to [MatchStatus.finished].
  final DateTime? finishedAt;

  /// Court or arena where the match is played, when recorded.
  final String? venue;

  Match copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    MatchStatus? status,
    DateTime? scheduledAt,
    String? competitionId,
    String? seasonId,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? venue,
  }) {
    return Match(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      competitionId: competitionId ?? this.competitionId,
      seasonId: seasonId ?? this.seasonId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      venue: venue ?? this.venue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Match &&
          other.id == id &&
          other.homeTeamId == homeTeamId &&
          other.awayTeamId == awayTeamId &&
          other.status == status &&
          other.scheduledAt == scheduledAt &&
          other.competitionId == competitionId &&
          other.seasonId == seasonId &&
          other.startedAt == startedAt &&
          other.finishedAt == finishedAt &&
          other.venue == venue;

  @override
  int get hashCode => Object.hash(
    id,
    homeTeamId,
    awayTeamId,
    status,
    scheduledAt,
    competitionId,
    seasonId,
    startedAt,
    finishedAt,
    venue,
  );

  @override
  String toString() =>
      'Match(id: $id, home: $homeTeamId, away: $awayTeamId, status: $status)';
}
