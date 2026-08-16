import '../../domain/entities/event_type.dart';
import '../../domain/entities/match_event.dart';
import 'coordinates_model.dart';
import 'event_type.dart';

/// Data-layer DTO for a match event, aligned with the backend JSON
/// (Agent_Mobile §6).
///
/// Hand-written (no Freezed) to stay compatible with the installed Dart SDK.
class EventModel {
  const EventModel({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.eventType,
    required this.period,
    required this.gameClock,
    required this.createdAt,
    this.playerId,
    this.coordinates,
    this.metadata,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'];
    final metadata = json['metadata'];
    return EventModel(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      teamId: json['teamId'] as String,
      playerId: json['playerId'] as String?,
      eventType:
          const EventTypeConverter().fromJson(json['eventType'] as String),
      period: (json['period'] as num).toInt(),
      gameClock: json['gameClock'] as String,
      coordinates: coordinates is Map
          ? CoordinatesModel.fromJson(coordinates.cast<String, dynamic>())
          : null,
      metadata:
          metadata is Map ? metadata.cast<String, dynamic>() : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String matchId;
  final String teamId;
  final String? playerId;
  final EventType eventType;
  final int period;
  final String gameClock;
  final CoordinatesModel? coordinates;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'matchId': matchId,
        'teamId': teamId,
        'playerId': playerId,
        'eventType': const EventTypeConverter().toJson(eventType),
        'period': period,
        'gameClock': gameClock,
        'coordinates': coordinates?.toJson(),
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };

  MatchEvent toEntity() => MatchEvent(
        id: id,
        matchId: matchId,
        teamId: teamId,
        playerId: playerId,
        eventType: eventType,
        period: period,
        gameClock: gameClock,
        coordinates: coordinates?.toEntity(),
        metadata: metadata,
        createdAt: createdAt,
      );
}
