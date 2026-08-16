import '../../domain/entities/match.dart';

/// Maps the backend match-status strings (`SCHEDULED`, …) to the domain
/// [MatchStatus] enum.
class MatchStatusConverter {
  const MatchStatusConverter();

  static const Map<String, MatchStatus> _fromApi = <String, MatchStatus>{
    'SCHEDULED': MatchStatus.scheduled,
    'IN_PROGRESS': MatchStatus.inProgress,
    'FINISHED': MatchStatus.finished,
  };

  static const Map<MatchStatus, String> _toApi = <MatchStatus, String>{
    MatchStatus.scheduled: 'SCHEDULED',
    MatchStatus.inProgress: 'IN_PROGRESS',
    MatchStatus.finished: 'FINISHED',
  };

  MatchStatus fromJson(String json) {
    final status = _fromApi[json];
    if (status == null) {
      throw FormatException('Unknown match status: $json');
    }
    return status;
  }

  String toJson(MatchStatus object) => _toApi[object]!;
}

/// Data-layer DTO for a match, aligned with the backend JSON.
///
/// Hand-written (no Freezed) to stay compatible with the installed Dart SDK.
class MatchModel {
  const MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.status,
    required this.scheduledAt,
    this.competitionId,
    this.seasonId,
    this.startedAt,
    this.finishedAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final startedAt = json['startedAt'] as String?;
    final finishedAt = json['finishedAt'] as String?;
    return MatchModel(
      id: json['id'] as String,
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      status:
          const MatchStatusConverter().fromJson(json['status'] as String),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      competitionId: json['competitionId'] as String?,
      seasonId: json['seasonId'] as String?,
      startedAt: startedAt == null ? null : DateTime.parse(startedAt),
      finishedAt: finishedAt == null ? null : DateTime.parse(finishedAt),
    );
  }

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final MatchStatus status;
  final DateTime scheduledAt;
  final String? competitionId;
  final String? seasonId;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'status': const MatchStatusConverter().toJson(status),
        'scheduledAt': scheduledAt.toIso8601String(),
        'competitionId': competitionId,
        'seasonId': seasonId,
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
      };

  Match toEntity() => Match(
        id: id,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        status: status,
        scheduledAt: scheduledAt,
        competitionId: competitionId,
        seasonId: seasonId,
        startedAt: startedAt,
        finishedAt: finishedAt,
      );
}
