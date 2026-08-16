import '../../../../core/network/ws_manager.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/entities/match_score.dart';
import '../models/event_model.dart';
import '../models/match_model.dart';
import '../models/match_score_model.dart';

/// Adapts the shared [WsManager] read channel (Agent_Mobile §7.2) into typed
/// domain streams for a live match.
///
/// The manager emits normalized `Map<String, dynamic>` payloads; this datasource
/// unwraps the inner object (tolerating `{ data: {...} }` / `{ event: {...} }`
/// envelopes) and maps it to the corresponding domain entity.
class MatchWsDataSource {
  MatchWsDataSource(this._wsManager);

  final WsManager _wsManager;

  /// Connection state transitions, for the UI indicator and reconciliation.
  Stream<WsConnectionState> get connectionState => _wsManager.connectionState;

  /// New events created for the joined match (`event.created`).
  Stream<MatchEvent> get onEventCreated => _wsManager.onEventCreated.map(
        (payload) => EventModel.fromJson(_unwrap(payload)).toEntity(),
      );

  /// Live score updates (`score.updated`).
  Stream<MatchScore> get onScoreUpdated => _wsManager.onScoreUpdated.map(
        (payload) => MatchScoreModel.fromJson(_unwrap(payload)).toEntity(),
      );

  /// Match state changes (`match.updated`).
  Stream<Match> get onMatchUpdated => _wsManager.onMatchUpdated.map(
        (payload) => MatchModel.fromJson(_unwrap(payload)).toEntity(),
      );

  /// Opens the socket connection (idempotent).
  Future<void> connect() => _wsManager.connect();

  /// Subscribes to realtime updates for [matchId].
  void joinMatch(String matchId) => _wsManager.joinMatch(matchId);

  /// Unsubscribes from realtime updates for [matchId].
  void leaveMatch(String matchId) => _wsManager.leaveMatch(matchId);

  /// Closes the socket connection.
  void disconnect() => _wsManager.disconnect();

  /// Extracts the inner object from a socket payload, tolerating common
  /// envelope keys.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> payload) {
    for (final key in const <String>['data', 'event', 'score', 'match']) {
      final inner = payload[key];
      if (inner is Map) {
        return inner.cast<String, dynamic>();
      }
    }
    return payload;
  }
}
