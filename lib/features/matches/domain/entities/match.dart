/// Lifecycle state of a match, mirroring the backend status enum.
///
/// The API string representation lives in the data layer
/// (`data/models/match_model.dart` — `MatchStatusConverter`).
enum MatchStatus { scheduled, inProgress, finished, cancelled, postponed, suspended }

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
    this.totalPeriods = 4,
    this.periodDurationMinutes = 10,
    this.suspensionReason,
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

  /// Number of regular periods (quarters) configured for the match.
  final int totalPeriods;

  /// Duration of each period in minutes.
  final int periodDurationMinutes;

  /// Reason recorded when the match was suspended, when applicable.
  final String? suspensionReason;

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
    int? totalPeriods,
    int? periodDurationMinutes,
    String? suspensionReason,
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
      totalPeriods: totalPeriods ?? this.totalPeriods,
      periodDurationMinutes:
          periodDurationMinutes ?? this.periodDurationMinutes,
      suspensionReason: suspensionReason ?? this.suspensionReason,
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
          other.venue == venue &&
          other.totalPeriods == totalPeriods &&
          other.periodDurationMinutes == periodDurationMinutes &&
          other.suspensionReason == suspensionReason;

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
    totalPeriods,
    periodDurationMinutes,
    suspensionReason,
  );

  @override
  String toString() =>
      'Match(id: $id, home: $homeTeamId, away: $awayTeamId, status: $status)';
}
