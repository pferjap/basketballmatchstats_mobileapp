import '../entities/coordinates.dart';
import '../entities/event_type.dart';
import '../entities/match_event.dart';

/// Input for recording a new match event.
///
/// The repository supplies the generated id and `createdAt`, so callers only
/// provide the descriptive fields. [playerId] is `null` for team-level events.
class EventParams {
  const EventParams({
    required this.teamId,
    required this.eventType,
    required this.period,
    required this.gameClock,
    this.playerId,
    this.coordinates,
    this.metadata,
  });

  final String teamId;
  final String? playerId;
  final EventType eventType;
  final int period;
  final String gameClock;
  final Coordinates? coordinates;
  final Map<String, dynamic>? metadata;
}

/// Write operations for match events (Agent_Mobile §7.1, §10).
///
/// Recording is offline-first: events are persisted locally before the network
/// call so nothing is lost when connectivity drops.
abstract interface class EventRepository {
  /// Records a new event for [matchId].
  ///
  /// On a business rejection (4xx) the local copy is marked failed and the
  /// error is rethrown so the UI can roll back its optimistic update. On a
  /// transient/offline failure the event stays queued and the locally
  /// constructed event is returned.
  Future<MatchEvent> recordEvent(String matchId, EventParams params);

  /// Undoes the most recent event for [matchId] (compensation/soft-delete).
  Future<void> undoLastEvent(String matchId);
}
