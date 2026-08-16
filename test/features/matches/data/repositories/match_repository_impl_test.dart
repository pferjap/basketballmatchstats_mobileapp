import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/api_response_parser.dart';
import 'package:hoop_analytics/features/matches/data/datasources/match_local_datasource.dart';
import 'package:hoop_analytics/features/matches/data/datasources/match_remote_datasource.dart';
import 'package:hoop_analytics/features/matches/data/datasources/match_ws_datasource.dart';
import 'package:hoop_analytics/features/matches/data/models/event_model.dart';
import 'package:hoop_analytics/features/matches/data/models/match_model.dart';
import 'package:hoop_analytics/features/matches/data/models/match_score_model.dart';
import 'package:hoop_analytics/features/matches/data/models/match_statistics_model.dart';
import 'package:hoop_analytics/features/matches/data/models/player_match_stats_model.dart';
import 'package:hoop_analytics/features/matches/data/repositories/match_repository_impl.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements MatchRemoteDataSource {}

class _MockWs extends Mock implements MatchWsDataSource {}

class _MockLocal extends Mock implements MatchLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockWs ws;
  late _MockLocal local;
  late MatchRepositoryImpl repository;

  final scheduledAt = DateTime.utc(2024, 2, 1, 18);

  MatchModel matchModel(String id) => MatchModel(
        id: id,
        homeTeamId: 'home',
        awayTeamId: 'away',
        status: MatchStatus.scheduled,
        scheduledAt: scheduledAt,
      );

  setUp(() {
    remote = _MockRemote();
    ws = _MockWs();
    local = _MockLocal();
    repository = MatchRepositoryImpl(remote: remote, ws: ws, local: local);
  });

  group('getMatches', () {
    test('maps models to entities and carries pagination metadata', () async {
      when(() => remote.getMatches(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => (
            items: <MatchModel>[matchModel('m1'), matchModel('m2')],
            meta: const ApiMeta(page: 1, limit: 20, total: 2),
          ));

      final result = await repository.getMatches(page: 1, limit: 20);

      expect(result.items, hasLength(2));
      expect(result.items.first, isA<Match>());
      expect(result.items.first.id, 'm1');
      expect(result.page, 1);
      expect(result.limit, 20);
      expect(result.total, 2);
      expect(result.hasMore, isFalse);
    });
  });

  group('getMatch', () {
    test('caches the match and returns the entity', () async {
      when(() => remote.getMatch(any()))
          .thenAnswer((_) async => matchModel('m1'));
      when(() => local.cacheMatch(
            matchId: any(named: 'matchId'),
            data: any(named: 'data'),
          )).thenAnswer((_) async {});

      final match = await repository.getMatch('m1');

      expect(match.id, 'm1');
      verify(() => local.cacheMatch(
            matchId: 'm1',
            data: any(named: 'data'),
          )).called(1);
    });
  });

  group('reconcile', () {
    test('aggregates missed events and latest statistics', () async {
      final since = DateTime.utc(2024, 2, 1, 19);
      when(() => remote.getMatchEvents(
            any(),
            since: any(named: 'since'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => (
            items: <EventModel>[
              EventModel(
                id: 'e1',
                matchId: 'm1',
                teamId: 't1',
                eventType: EventType.assist,
                period: 2,
                gameClock: '04:00',
                createdAt: DateTime.utc(2024, 2, 1, 19, 5),
              ),
            ],
            meta: null,
          ));
      when(() => remote.getMatchStatistics(any())).thenAnswer(
        (_) async => const MatchStatisticsModel(
          score: MatchScoreModel(
            matchId: 'm1',
            homeTeamScore: 10,
            awayTeamScore: 8,
            currentPeriod: 2,
            gameClock: '04:00',
          ),
          playerStats: <PlayerMatchStatsModel>[],
        ),
      );

      final result = await repository.reconcile('m1', since: since);

      expect(result.missedEvents, hasLength(1));
      expect(result.missedEvents.first.eventType, EventType.assist);
      expect(result.statistics.score.homeTeamScore, 10);
      verify(() => remote.getMatchEvents('m1', since: since)).called(1);
    });
  });
}
