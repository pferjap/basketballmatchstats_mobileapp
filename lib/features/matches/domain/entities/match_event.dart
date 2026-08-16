import 'coordinates.dart';
import 'event_type.dart';

/// A single statistical event recorded during a match (Agent_Mobile §6).
///
/// Plain, dependency-free value object; data-layer models map into this via
/// their `toEntity()` methods. [playerId] is `null` for team-level events
/// (e.g. timeouts), and [coordinates]/[metadata] are optional.
class MatchEvent {
  const MatchEvent({
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

  /// Unique event id (UUID). Generated client-side for offline-first recording.
  final String id;
  final String matchId;
  final String teamId;

  /// `null` for team-level events that are not attributable to a player.
  final String? playerId;
  final EventType eventType;

  /// Match period: 1–4 for regulation, 5+ for overtime.
  final int period;

  /// Remaining game clock formatted as `mm:ss`.
  final String gameClock;

  /// Normalized court location, when applicable (e.g. shots).
  final Coordinates? coordinates;

  /// Free-form, event-specific details (e.g. points value, foul subtype).
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchEvent &&
          other.id == id &&
          other.matchId == matchId &&
          other.teamId == teamId &&
          other.playerId == playerId &&
          other.eventType == eventType &&
          other.period == period &&
          other.gameClock == gameClock &&
          other.coordinates == coordinates &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        matchId,
        teamId,
        playerId,
        eventType,
        period,
        gameClock,
        coordinates,
        createdAt,
      );

  @override
  String toString() =>
      'MatchEvent(id: $id, matchId: $matchId, eventType: $eventType, '
      'period: $period, gameClock: $gameClock)';
}
