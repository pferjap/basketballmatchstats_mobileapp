import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/match_event.dart';
import '../../domain/repositories/event_repository.dart';
import '../models/annotation_action.dart';
import '../models/court_view_args.dart';
import 'match_providers.dart';

/// Sync lifecycle of a locally recorded event, surfaced in the history tab.
enum EventSyncStatus { pending, synced, failed }

/// An event recorded during this annotation session, plus its sync status and
/// the action it originated from (used to recompute score/fouls and to retry).
@immutable
class RecordedEvent {
  const RecordedEvent({
    required this.event,
    required this.action,
    required this.status,
  });

  final MatchEvent event;
  final AnnotationAction action;
  final EventSyncStatus status;

  RecordedEvent copyWith({MatchEvent? event, EventSyncStatus? status}) {
    return RecordedEvent(
      event: event ?? this.event,
      action: action,
      status: status ?? this.status,
    );
  }
}

/// Immutable state for the Court View annotation flow (Plan.md T-018–T-021).
@immutable
class AnnotationState {
  const AnnotationState({
    this.homeTeamId = 'home',
    this.awayTeamId = 'away',
    this.annotatingTeamId = 'home',
    this.currentPeriod = 1,
    this.baseHomeScore = 0,
    this.baseAwayScore = 0,
    this.events = const <RecordedEvent>[],
    this.selectedAction,
    this.selectedPlayer,
    this.currentStep = 1,
    this.isRecording = false,
    this.errorMessage,
  });

  final String homeTeamId;
  final String awayTeamId;

  /// Team currently being annotated (the bottom-bar team dropdown).
  final String annotatingTeamId;
  final int currentPeriod;

  /// Score before this session's events (loaded from the server).
  final int baseHomeScore;
  final int baseAwayScore;

  /// Events recorded this session, newest first.
  final List<RecordedEvent> events;

  final AnnotationAction? selectedAction;
  final RosterPlayer? selectedPlayer;

  /// 1 = pick action, 2 = pick player, 3 = optional details.
  final int currentStep;
  final bool isRecording;
  final String? errorMessage;

  bool get isAnnotatingHome => annotatingTeamId == homeTeamId;

  /// Live home score = base + made points from non-failed home events.
  int get homeScore => baseHomeScore + _scoreFor(homeTeamId);

  /// Live away score = base + made points from non-failed away events.
  int get awayScore => baseAwayScore + _scoreFor(awayTeamId);

  /// Team fouls counted for [homeTeamId] in [currentPeriod].
  int get homeFouls => _foulsFor(homeTeamId);

  /// Team fouls counted for [awayTeamId] in [currentPeriod].
  int get awayFouls => _foulsFor(awayTeamId);

  int _scoreFor(String teamId) {
    var total = 0;
    for (final recorded in events) {
      if (recorded.status == EventSyncStatus.failed) continue;
      if (recorded.event.teamId == teamId) {
        total += recorded.action.scoringPoints;
      }
    }
    return total;
  }

  int _foulsFor(String teamId) {
    var total = 0;
    for (final recorded in events) {
      if (recorded.status == EventSyncStatus.failed) continue;
      if (recorded.event.teamId == teamId &&
          recorded.event.period == currentPeriod &&
          recorded.action.isTeamFoul) {
        total++;
      }
    }
    return total;
  }

  AnnotationState copyWith({
    String? homeTeamId,
    String? awayTeamId,
    String? annotatingTeamId,
    int? currentPeriod,
    int? baseHomeScore,
    int? baseAwayScore,
    List<RecordedEvent>? events,
    AnnotationAction? selectedAction,
    RosterPlayer? selectedPlayer,
    int? currentStep,
    bool? isRecording,
    String? errorMessage,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return AnnotationState(
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      annotatingTeamId: annotatingTeamId ?? this.annotatingTeamId,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      baseHomeScore: baseHomeScore ?? this.baseHomeScore,
      baseAwayScore: baseAwayScore ?? this.baseAwayScore,
      events: events ?? this.events,
      selectedAction: clearSelection
          ? null
          : (selectedAction ?? this.selectedAction),
      selectedPlayer: clearSelection
          ? null
          : (selectedPlayer ?? this.selectedPlayer),
      currentStep: currentStep ?? this.currentStep,
      isRecording: isRecording ?? this.isRecording,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Drives the Court View annotation flow: the ≤3-tap action→player(→details)
/// sequence, optimistic scoring/fouls, offline-first recording and undo
/// (Plan.md T-020, Agent_Mobile §7.1/§10).
class AnnotationController
    extends AutoDisposeFamilyNotifier<AnnotationState, String> {
  EventRepository get _events => ref.read(eventRepositoryProvider);

  final Uuid _uuid = const Uuid();
  bool _configured = false;
  String _gameClock = '10:00';

  @override
  AnnotationState build(String matchId) => const AnnotationState();

  /// One-time configuration from the page's [CourtViewArgs]: seeds team ids,
  /// starting period and the base score from the server (best-effort).
  /// Also loads existing events so re-entering the screen shows the history.
  Future<void> configure(CourtViewArgs args) async {
    if (_configured) return;
    _configured = true;

    state = state.copyWith(
      homeTeamId: args.home.id,
      awayTeamId: args.away.id,
      annotatingTeamId: args.home.id,
      currentPeriod: args.initialPeriod,
    );

    try {
      final stats = await ref
          .read(matchRepositoryProvider)
          .getMatchStatistics(arg);
      state = state.copyWith(
        baseHomeScore: stats.score.homeTeamScore,
        baseAwayScore: stats.score.awayTeamScore,
        currentPeriod: stats.score.currentPeriod,
      );
    } catch (_) {
      // Best-effort: annotation still works from a 0–0 base when offline.
    }

    // Load previously recorded events so re-entering shows the history.
    try {
      final page = await ref
          .read(matchRepositoryProvider)
          .getMatchEvents(arg, limit: 100);
      if (page.items.isNotEmpty) {
        final defaultAction = kAnnotationActions.first;
        final loaded = page.items.map((e) {
          // Find the matching AnnotationAction by eventType, or use a default.
          final action = kAnnotationActions.cast<AnnotationAction?>().firstWhere(
                (a) => a!.eventType == e.eventType,
                orElse: () => null,
              ) ??
              defaultAction;
          return RecordedEvent(
            event: e,
            action: action,
            status: EventSyncStatus.synced,
          );
        }).toList(growable: false);
        state = state.copyWith(events: loaded);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  /// Reports the current game clock so recorded events carry an accurate time.
  void setGameClock(String value) => _gameClock = value;

  /// Step 1 → 2: an action was tapped.
  void selectAction(AnnotationAction action) {
    state = state.copyWith(
      selectedAction: action,
      selectedPlayer: null,
      currentStep: 2,
      clearError: true,
    );
  }

  /// Changes the team being annotated (bottom-bar dropdown), resetting the flow.
  void setAnnotatingTeam(String teamId) {
    state = state.copyWith(
      annotatingTeamId: teamId,
      clearSelection: true,
      currentStep: 1,
    );
  }

  /// Changes the active period (top dropdown), resetting the flow.
  void setPeriod(int period) {
    state = state.copyWith(
      currentPeriod: period,
      clearSelection: true,
      currentStep: 1,
    );
  }

  /// Step 2 → record (or → 3 for shots that carry optional details).
  Future<void> selectPlayer(RosterPlayer player) async {
    final action = state.selectedAction;
    if (action == null) return;
    if (action.requiresDetails) {
      state = state.copyWith(selectedPlayer: player, currentStep: 3);
      return;
    }
    state = state.copyWith(selectedPlayer: player);
    await _record(action, player);
  }

  /// Confirms the optional details step (3) and records the event.
  Future<void> confirmDetails() async {
    final action = state.selectedAction;
    final player = state.selectedPlayer;
    if (action == null || player == null) return;
    await _record(action, player);
  }

  /// Cancels the in-progress selection, returning to step 1.
  void cancelSelection() {
    state = state.copyWith(clearSelection: true, currentStep: 1);
  }

  Future<void> _record(AnnotationAction action, RosterPlayer player) async {
    final teamId = state.annotatingTeamId;
    final id = _uuid.v4();
    final createdAt = DateTime.now();

    // Optimistically place the event so score/fouls/history update instantly.
    final optimistic = _buildEvent(
      id: id,
      teamId: teamId,
      action: action,
      player: player,
      createdAt: createdAt,
    );
    final recorded = RecordedEvent(
      event: optimistic,
      action: action,
      status: EventSyncStatus.pending,
    );
    state = state.copyWith(
      events: <RecordedEvent>[recorded, ...state.events],
      isRecording: true,
      clearSelection: true,
      currentStep: 1,
      clearError: true,
    );

    await _send(recorded);
  }

  Future<void> _send(RecordedEvent recorded) async {
    final params = EventParams(
      teamId: recorded.event.teamId,
      playerId: recorded.event.playerId,
      eventType: recorded.event.eventType,
      period: recorded.event.period,
      gameClock: recorded.event.gameClock,
      coordinates: recorded.event.coordinates,
      metadata: recorded.event.metadata,
    );
    try {
      final serverEvent = await _events.recordEvent(arg, params);
      _replace(
        recorded.event.id,
        recorded.copyWith(event: serverEvent, status: EventSyncStatus.synced),
      );
    } catch (error) {
      _replace(
        recorded.event.id,
        recorded.copyWith(status: EventSyncStatus.failed),
      );
      state = state.copyWith(
        errorMessage: 'Error: $error',
      );
    } finally {
      if (state.isRecording) {
        state = state.copyWith(isRecording: false);
      }
    }
  }

  /// Retries a previously failed event.
  Future<void> retry(RecordedEvent recorded) async {
    _replace(
      recorded.event.id,
      recorded.copyWith(status: EventSyncStatus.pending),
    );
    final refreshed = state.events.firstWhere(
      (e) => e.event.id == recorded.event.id,
      orElse: () => recorded,
    );
    await _send(refreshed);
  }

  /// Undoes the most recent (non-failed) event via the compensation endpoint.
  Future<void> undoLast() async {
    final target =
        state.events.where((e) => e.status != EventSyncStatus.failed).isEmpty
        ? null
        : state.events.firstWhere((e) => e.status != EventSyncStatus.failed);
    if (target == null) return;
    try {
      await _events.undoLastEvent(arg);
      state = state.copyWith(
        events: state.events
            .where((e) => e.event.id != target.event.id)
            .toList(growable: false),
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo deshacer la acción.');
    }
  }

  /// Whether [recorded] can be swipe-undone: it must be the most recent event
  /// and recorded within the last 30 seconds.
  bool canUndo(RecordedEvent recorded) {
    if (state.events.isEmpty) return false;
    if (state.events.first.event.id != recorded.event.id) return false;
    return DateTime.now().difference(recorded.event.createdAt).inSeconds <= 30;
  }

  MatchEvent _buildEvent({
    required String id,
    required String teamId,
    required AnnotationAction action,
    required RosterPlayer player,
    required DateTime createdAt,
  }) {
    // Running score after applying this event, embedded so the feed can show
    // the partial score without another lookup.
    final addsHome = teamId == state.homeTeamId ? action.scoringPoints : 0;
    final addsAway = teamId == state.awayTeamId ? action.scoringPoints : 0;
    final metadata = <String, dynamic>{
      ...?action.buildMetadata(),
      'playerName': player.name,
      'playerNumber': player.number,
      'homeScore': state.homeScore + addsHome,
      'awayScore': state.awayScore + addsAway,
    };
    return MatchEvent(
      id: id,
      matchId: arg,
      teamId: teamId,
      playerId: player.id,
      eventType: action.eventType,
      period: state.currentPeriod,
      gameClock: _gameClock,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  void _replace(String eventId, RecordedEvent updated) {
    state = state.copyWith(
      events: <RecordedEvent>[
        for (final e in state.events)
          if (e.event.id == eventId) updated else e,
      ],
    );
  }
}

/// Annotation flow state for a given match id.
final annotationControllerProvider = NotifierProvider.autoDispose
    .family<AnnotationController, AnnotationState, String>(
      AnnotationController.new,
    );
