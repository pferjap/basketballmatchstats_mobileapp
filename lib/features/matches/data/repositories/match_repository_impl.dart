import 'dart:convert';

import '../../../../core/models/paginated.dart';
import '../../../../core/network/ws_manager.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/entities/match_score.dart';
import '../../domain/entities/match_statistics.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_local_datasource.dart';
import '../datasources/match_remote_datasource.dart';
import '../datasources/match_ws_datasource.dart';
import '../models/event_model.dart';
import '../models/match_model.dart';

/// Outcome of a WebSocket reconnection reconciliation (Agent_Mobile §7.3).
class ReconcileResult {
  const ReconcileResult({required this.missedEvents, required this.statistics});

  /// Events created while the socket was disconnected.
  final List<MatchEvent> missedEvents;

  /// Latest authoritative statistics after the gap.
  final MatchStatistics statistics;
}

/// Coordinates the REST datasource, the WebSocket read channel and the local
/// cache to fulfil the [MatchRepository] contract.
class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl({
    required this.remote,
    required this.ws,
    required this.local,
  });

  final MatchRemoteDataSource remote;
  final MatchWsDataSource ws;
  final MatchLocalDataSource local;

  @override
  Future<Paginated<Match>> getMatches({int? page, int? limit}) async {
    final result = await remote.getMatches(page: page, limit: limit);
    return Paginated<Match>(
      items: result.items
          .map((MatchModel m) => m.toEntity())
          .toList(growable: false),
      page: result.meta?.page,
      limit: result.meta?.limit,
      total: result.meta?.total,
    );
  }

  @override
  Future<Match> getMatch(String matchId) async {
    final model = await remote.getMatch(matchId);
    await local.cacheMatch(matchId: matchId, data: jsonEncode(model.toJson()));
    return model.toEntity();
  }

  @override
  Future<Match> startMatch(String matchId) async {
    final model = await remote.startMatch(matchId);
    return model.toEntity();
  }

  @override
  Future<Match> createMatch(CreateMatchParams params) async {
    final model = await remote.createMatch(<String, dynamic>{
      'homeTeamId': params.homeTeamId,
      'awayTeamId': params.awayTeamId,
      'scheduledAt': params.scheduledAt.toUtc().toIso8601String(),
      'competitionId': ?params.competitionId,
      'seasonId': ?params.seasonId,
      'venue': ?params.venue,
    });
    return model.toEntity();
  }

  @override
  Future<Match> updateMatch(String matchId, UpdateMatchParams params) async {
    // Only non-null fields travel, so an omitted field leaves the stored value
    // untouched rather than being cleared.
    final model = await remote.updateMatch(matchId, <String, dynamic>{
      'homeTeamId': ?params.homeTeamId,
      'awayTeamId': ?params.awayTeamId,
      'scheduledAt': ?params.scheduledAt?.toUtc().toIso8601String(),
      'competitionId': ?params.competitionId,
      'seasonId': ?params.seasonId,
      'venue': ?params.venue,
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteMatch(String matchId) => remote.deleteMatch(matchId);

  @override
  Future<MatchStatistics> getMatchStatistics(String matchId) async {
    final model = await remote.getMatchStatistics(matchId);
    return model.toEntity();
  }

  @override
  Future<Paginated<MatchEvent>> getMatchEvents(
    String matchId, {
    DateTime? since,
    int? page,
    int? limit,
  }) async {
    final result = await remote.getMatchEvents(
      matchId,
      since: since,
      page: page,
      limit: limit,
    );
    return Paginated<MatchEvent>(
      items: result.items
          .map((EventModel e) => e.toEntity())
          .toList(growable: false),
      page: result.meta?.page,
      limit: result.meta?.limit,
      total: result.meta?.total,
    );
  }

  // --- Realtime read channel (consumed by the live-match presentation) ---

  /// Connection state transitions for the UI indicator and reconciliation.
  Stream<WsConnectionState> get connectionState => ws.connectionState;

  /// New events pushed for the joined match.
  Stream<MatchEvent> get eventUpdates => ws.onEventCreated;

  /// Live score updates for the joined match.
  Stream<MatchScore> get scoreUpdates => ws.onScoreUpdated;

  /// Match state changes for the joined match.
  Stream<Match> get matchUpdates => ws.onMatchUpdated;

  /// Opens the socket and subscribes to realtime updates for [matchId].
  Future<void> connectLive(String matchId) async {
    await ws.connect();
    ws.joinMatch(matchId);
  }

  /// Unsubscribes from realtime updates for [matchId].
  void disconnectLive(String matchId) => ws.leaveMatch(matchId);

  /// Reconciles after a WebSocket reconnect (§7.3): fetches events created
  /// after [since] plus the latest authoritative statistics, so the UI can
  /// merge whatever was missed during the gap.
  Future<ReconcileResult> reconcile(String matchId, {DateTime? since}) async {
    final events = await getMatchEvents(matchId, since: since);
    final statistics = await getMatchStatistics(matchId);
    return ReconcileResult(missedEvents: events.items, statistics: statistics);
  }
}
