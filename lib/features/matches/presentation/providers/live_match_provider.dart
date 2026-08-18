import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/ws_manager.dart';
import '../../data/datasources/match_ws_datasource.dart';
import '../../domain/entities/event_type.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/entities/match_score.dart';
import '../../domain/repositories/match_repository.dart';
import 'match_providers.dart';

/// Immutable state for the live-match spectator screen (Plan.md T-017).
@immutable
class LiveMatchState {
  const LiveMatchState({
    this.score,
    this.events = const <MatchEvent>[],
    this.connection = WsConnectionState.disconnected,
    this.isLoading = true,
    this.isLoadingEarlier = false,
    this.hasMoreEarlier = true,
    this.errorMessage,
    this.homeTeamId = '',
    this.awayTeamId = '',
  });

  /// Latest scoreboard, or `null` until the initial load completes.
  final MatchScore? score;

  /// Play-by-play feed, newest first.
  final List<MatchEvent> events;

  /// Current realtime connection state, for the connection indicator.
  final WsConnectionState connection;

  /// Whether the initial load is in flight.
  final bool isLoading;

  /// Whether an older-events page is being loaded.
  final bool isLoadingEarlier;

  /// Whether more historical events may still be loaded.
  final bool hasMoreEarlier;

  /// User-facing error message from the initial load, if any.
  final String? errorMessage;

  final String homeTeamId;
  final String awayTeamId;

  LiveMatchState copyWith({
    MatchScore? score,
    List<MatchEvent>? events,
    WsConnectionState? connection,
    bool? isLoading,
    bool? isLoadingEarlier,
    bool? hasMoreEarlier,
    String? errorMessage,
    String? homeTeamId,
    String? awayTeamId,
  }) {
    return LiveMatchState(
      score: score ?? this.score,
      events: events ?? this.events,
      connection: connection ?? this.connection,
      isLoading: isLoading ?? this.isLoading,
      isLoadingEarlier: isLoadingEarlier ?? this.isLoadingEarlier,
      hasMoreEarlier: hasMoreEarlier ?? this.hasMoreEarlier,
      errorMessage: errorMessage,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveMatchState &&
          other.score == score &&
          listEquals(other.events, events) &&
          other.connection == connection &&
          other.isLoading == isLoading &&
          other.isLoadingEarlier == isLoadingEarlier &&
          other.hasMoreEarlier == hasMoreEarlier &&
          other.errorMessage == errorMessage &&
          other.homeTeamId == homeTeamId &&
          other.awayTeamId == awayTeamId;

  @override
  int get hashCode => Object.hash(
    score,
    Object.hashAll(events),
    connection,
    isLoading,
    isLoadingEarlier,
    hasMoreEarlier,
    errorMessage,
    homeTeamId,
    awayTeamId,
  );
}

/// Drives the live-match screen: subscribes to the WebSocket read channel on
/// entry, exposes the score and play-by-play feed, reconciles missed events on
/// reconnect, and unsubscribes on dispose (Plan.md T-017, Agent_Mobile §7.2/7.3).
class LiveMatchController
    extends AutoDisposeFamilyNotifier<LiveMatchState, String> {
  MatchWsDataSource get _ws => ref.read(matchWsDataSourceProvider);
  MatchRepository get _repository => ref.read(matchRepositoryProvider);

  /// Datasource captured at build time so teardown never reads a provider from
  /// an already-disposed container (e.g. when the whole scope is torn down).
  MatchWsDataSource? _wsForCleanUp;

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  bool _disposed = false;
  int _nextEarlierPage = 2;

  /// Newest event timestamp seen so far, used as the reconciliation cursor.
  DateTime? _lastEventAt;

  @override
  LiveMatchState build(String matchId) {
    _disposed = false;
    ref.onDispose(_cleanUp);

    final ws = _ws;
    _wsForCleanUp = ws;
    _subscriptions
      ..add(ws.onScoreUpdated.listen(_onScore))
      ..add(ws.onEventCreated.listen(_onEvent))
      ..add(ws.connectionState.listen(_onConnection));

    unawaited(_initialize(matchId));
    return const LiveMatchState();
  }

  Future<void> _initialize(String matchId) async {
    try {
      await _ws.connect();
      _ws.joinMatch(matchId);

      // Load match details for period/gameClock and team IDs.
      String homeTeamId = '';
      String awayTeamId = '';
      int currentPeriod = 1;
      String gameClock = '00:00';
      try {
        final match = await _repository.getMatch(matchId);
        homeTeamId = match.homeTeamId;
        awayTeamId = match.awayTeamId;
      } catch (_) {
        // Best-effort.
      }

      // Try dedicated statistics endpoint first.
      MatchScore? score;
      try {
        final statistics = await _repository.getMatchStatistics(matchId);
        score = statistics.score;
      } catch (_) {
        // Statistics unavailable; derive from events below.
      }

      final page = await _repository.getMatchEvents(matchId, limit: 50);
      final events = _sorted(page.items);
      _lastEventAt = events.isNotEmpty ? events.first.createdAt : null;

      // Derive score from events when statistics endpoint is unavailable.
      if (score == null && homeTeamId.isNotEmpty) {
        score = _computeScore(matchId, events, homeTeamId, awayTeamId,
            currentPeriod, gameClock);
      }

      _setState(
        state.copyWith(
          score: score,
          events: events,
          isLoading: false,
          hasMoreEarlier: page.hasMore,
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
        ),
      );
    } catch (error) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo cargar el partido. Comprueba tu conexión.',
        ),
      );
    }
  }

  /// Loads the next page of older events, appending them to the feed.
  Future<void> loadEarlier() async {
    final matchId = arg;
    if (state.isLoadingEarlier || !state.hasMoreEarlier) {
      return;
    }
    _setState(state.copyWith(isLoadingEarlier: true));
    try {
      final page = await _repository.getMatchEvents(
        matchId,
        page: _nextEarlierPage,
        limit: 50,
      );
      _nextEarlierPage++;
      final merged = _mergeEvents(state.events, page.items);
      _setState(
        state.copyWith(
          events: merged,
          isLoadingEarlier: false,
          hasMoreEarlier: page.hasMore,
        ),
      );
    } catch (_) {
      _setState(state.copyWith(isLoadingEarlier: false));
    }
  }

  void _onScore(MatchScore score) => _setState(state.copyWith(score: score));

  void _onEvent(MatchEvent event) {
    final merged = _mergeEvents(<MatchEvent>[event], state.events);
    if (_lastEventAt == null || event.createdAt.isAfter(_lastEventAt!)) {
      _lastEventAt = event.createdAt;
    }
    // Recompute score from all events.
    final score = state.homeTeamId.isNotEmpty
        ? _computeScore(arg, merged, state.homeTeamId, state.awayTeamId,
            state.score?.currentPeriod ?? 1, state.score?.gameClock ?? '00:00')
        : state.score;
    _setState(state.copyWith(events: merged, score: score));
  }

  void _onConnection(WsConnectionState next) {
    final previous = state.connection;
    _setState(state.copyWith(connection: next));
    // On a fresh (re)connection, pull anything missed during the gap (§7.3).
    if (next == WsConnectionState.connected &&
        previous != WsConnectionState.connected) {
      unawaited(_reconcile());
    }
  }

  Future<void> _reconcile() async {
    final matchId = arg;
    try {
      final page = await _repository.getMatchEvents(
        matchId,
        since: _lastEventAt,
      );
      MatchScore? score;
      try {
        final statistics = await _repository.getMatchStatistics(matchId);
        score = statistics.score;
      } catch (_) {
        // Statistics endpoint may not be available.
      }
      final merged = _mergeEvents(page.items, state.events);
      if (merged.isNotEmpty) {
        _lastEventAt = merged.first.createdAt;
      }
      _setState(state.copyWith(events: merged, score: score ?? state.score));
    } catch (_) {
      // Reconciliation is best-effort; live updates continue regardless.
    }
  }

  /// Merges two event lists, de-duplicating by id and keeping newest first.
  List<MatchEvent> _mergeEvents(List<MatchEvent> a, List<MatchEvent> b) {
    final byId = <String, MatchEvent>{};
    for (final event in <MatchEvent>[...a, ...b]) {
      byId[event.id] = event;
    }
    return _sorted(byId.values.toList(growable: false));
  }

  List<MatchEvent> _sorted(List<MatchEvent> events) {
    final sorted = <MatchEvent>[...events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Derives a [MatchScore] by aggregating POINTS_MADE events.
  MatchScore _computeScore(
    String matchId,
    List<MatchEvent> events,
    String homeTeamId,
    String awayTeamId,
    int period,
    String gameClock,
  ) {
    int homeScore = 0;
    int awayScore = 0;
    int maxPeriod = period;
    String latestClock = gameClock;

    for (final event in events) {
      if (event.eventType == EventType.pointsMade) {
        final points = (event.metadata?['points'] as num?)?.toInt() ?? 2;
        if (event.teamId == homeTeamId) {
          homeScore += points;
        } else if (event.teamId == awayTeamId) {
          awayScore += points;
        }
      }
      if (event.period > maxPeriod) {
        maxPeriod = event.period;
      }
    }

    // Use the most recent event's clock and period.
    if (events.isNotEmpty) {
      latestClock = events.first.gameClock;
      maxPeriod = events.first.period;
    }

    return MatchScore(
      matchId: matchId,
      homeTeamScore: homeScore,
      awayTeamScore: awayScore,
      currentPeriod: maxPeriod,
      gameClock: latestClock,
    );
  }

  void _setState(LiveMatchState next) {
    if (!_disposed) {
      state = next;
    }
  }

  void _cleanUp() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _wsForCleanUp?.leaveMatch(arg);
    _wsForCleanUp = null;
  }
}

/// Live-match state for a given match id.
final liveMatchControllerProvider = NotifierProvider.autoDispose
    .family<LiveMatchController, LiveMatchState, String>(
      LiveMatchController.new,
    );
