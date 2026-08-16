import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/models/paginated.dart';
import 'package:hoop_analytics/core/network/ws_manager.dart';
import 'package:hoop_analytics/features/matches/data/datasources/match_ws_datasource.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_event.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_score.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_statistics.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/match_repository.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/live_match_provider.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements MatchRepository {}

class _FakeWs implements MatchWsDataSource {
  final StreamController<MatchEvent> events =
      StreamController<MatchEvent>.broadcast();
  final StreamController<MatchScore> scores =
      StreamController<MatchScore>.broadcast();
  final StreamController<WsConnectionState> connections =
      StreamController<WsConnectionState>.broadcast();

  bool joined = false;
  bool left = false;

  @override
  Stream<MatchEvent> get onEventCreated => events.stream;

  @override
  Stream<MatchScore> get onScoreUpdated => scores.stream;

  @override
  Stream<Match> get onMatchUpdated => Stream<Match>.empty();

  @override
  Stream<WsConnectionState> get connectionState => connections.stream;

  @override
  Future<void> connect() async {}

  @override
  void joinMatch(String matchId) => joined = true;

  @override
  void leaveMatch(String matchId) => left = true;

  @override
  void disconnect() {}
}

MatchEvent event(String id, DateTime at, {EventType type = EventType.assist}) {
  return MatchEvent(
    id: id,
    matchId: 'm1',
    teamId: 'home',
    eventType: type,
    period: 1,
    gameClock: '10:00',
    createdAt: at,
  );
}

const _score = MatchScore(
  matchId: 'm1',
  homeTeamScore: 10,
  awayTeamScore: 8,
  currentPeriod: 1,
  gameClock: '08:00',
);

Future<void> _flush() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late _MockRepository repository;
  late _FakeWs ws;
  late ProviderContainer container;

  final base = DateTime.utc(2024, 1, 1, 20);

  setUp(() {
    repository = _MockRepository();
    ws = _FakeWs();

    when(() => repository.getMatchStatistics(any())).thenAnswer(
      (_) async => const MatchStatistics(score: _score, playerStats: []),
    );
    when(() => repository.getMatchEvents(
          any(),
          since: any(named: 'since'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer((invocation) async {
      final since = invocation.namedArguments[#since] as DateTime?;
      if (since != null) {
        // Reconciliation call: return an event created during the gap.
        return Paginated<MatchEvent>(
          items: <MatchEvent>[
            event('recon', base.add(const Duration(minutes: 5))),
          ],
        );
      }
      return Paginated<MatchEvent>(
        items: <MatchEvent>[
          event('older', base),
          event('newer', base.add(const Duration(minutes: 1))),
        ],
        page: 1,
        limit: 50,
        total: 2,
      );
    });

    container = ProviderContainer(
      overrides: <Override>[
        matchWsDataSourceProvider.overrideWithValue(ws),
        matchRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('loads initial score and events sorted newest-first', () async {
    container.listen(liveMatchControllerProvider('m1'), (_, _) {});
    await _flush();

    final state = container.read(liveMatchControllerProvider('m1'));
    expect(state.isLoading, isFalse);
    expect(state.score, _score);
    expect(state.events.map((e) => e.id).toList(), <String>['newer', 'older']);
    expect(ws.joined, isTrue);
  });

  test('prepends and de-duplicates realtime events', () async {
    container.listen(liveMatchControllerProvider('m1'), (_, _) {});
    await _flush();

    ws.events.add(event('live', base.add(const Duration(minutes: 2))));
    await _flush();

    final state = container.read(liveMatchControllerProvider('m1'));
    expect(state.events.first.id, 'live');
    expect(state.events.length, 3);

    // Duplicate id should not grow the list.
    ws.events.add(event('live', base.add(const Duration(minutes: 2))));
    await _flush();
    expect(
      container.read(liveMatchControllerProvider('m1')).events.length,
      3,
    );
  });

  test('reconciles missed events on reconnect', () async {
    container.listen(liveMatchControllerProvider('m1'), (_, _) {});
    await _flush();

    ws.connections.add(WsConnectionState.disconnected);
    await _flush();
    ws.connections.add(WsConnectionState.connected);
    await _flush();

    final state = container.read(liveMatchControllerProvider('m1'));
    expect(state.connection, WsConnectionState.connected);
    expect(state.events.any((e) => e.id == 'recon'), isTrue);
    verify(() => repository.getMatchEvents('m1', since: any(named: 'since')))
        .called(1);
  });

  test('leaves the match room on dispose', () async {
    final sub = container.listen(liveMatchControllerProvider('m1'), (_, _) {});
    await _flush();
    sub.close();
    // Allow autoDispose to tear the provider down.
    await _flush();
    expect(ws.left, isTrue);
  });
}
