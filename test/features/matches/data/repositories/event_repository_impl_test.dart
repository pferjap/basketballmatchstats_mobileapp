import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/error/exceptions.dart';
import 'package:hoop_analytics/features/matches/data/datasources/match_local_datasource.dart';
import 'package:hoop_analytics/features/matches/data/datasources/match_remote_datasource.dart';
import 'package:hoop_analytics/features/matches/data/models/event_model.dart';
import 'package:hoop_analytics/features/matches/data/repositories/event_repository_impl.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/event_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements MatchRemoteDataSource {}

class _MockLocal extends Mock implements MatchLocalDataSource {}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late EventRepositoryImpl repository;

  final fixedTime = DateTime.utc(2024, 3, 1, 19, 30);
  const generatedId = 'local-id-1';

  const params = EventParams(
    teamId: 't1',
    playerId: 'p1',
    eventType: EventType.pointsMade,
    period: 1,
    gameClock: '09:12',
  );

  EventModel serverEvent() => EventModel(
        id: 'server-id',
        matchId: 'm1',
        teamId: 't1',
        playerId: 'p1',
        eventType: EventType.pointsMade,
        period: 1,
        gameClock: '09:12',
        createdAt: fixedTime,
      );

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repository = EventRepositoryImpl(
      remote: remote,
      local: local,
      idGenerator: () => generatedId,
      clock: () => fixedTime,
    );

    when(() => local.enqueueEvent(
          id: any(named: 'id'),
          matchId: any(named: 'matchId'),
          eventPayload: any(named: 'eventPayload'),
          createdAt: any(named: 'createdAt'),
        )).thenAnswer((_) async {});
    when(() => local.markEventSynced(any())).thenAnswer((_) async {});
    when(() => local.markEventFailed(any())).thenAnswer((_) async {});
    when(() => local.markEventRetryable(any())).thenAnswer((_) async {});
  });

  group('recordEvent', () {
    test('queues locally, posts, marks synced, returns server event', () async {
      when(() => remote.recordEvent(any(), any()))
          .thenAnswer((_) async => serverEvent());

      final event = await repository.recordEvent('m1', params);

      expect(event.id, 'server-id');
      verify(() => local.enqueueEvent(
            id: generatedId,
            matchId: 'm1',
            eventPayload: any(named: 'eventPayload'),
            createdAt: fixedTime,
          )).called(1);
      verify(() => local.markEventSynced(generatedId)).called(1);
      verifyNever(() => local.markEventRetryable(any()));
      verifyNever(() => local.markEventFailed(any()));
    });

    test('marks failed and rethrows on a 4xx business rejection', () async {
      when(() => remote.recordEvent(any(), any())).thenThrow(
        const ServerException(
          message: 'Invalid event',
          code: 'VALIDATION',
          statusCode: 422,
        ),
      );

      await expectLater(
        repository.recordEvent('m1', params),
        throwsA(isA<ServerException>()),
      );
      verify(() => local.markEventFailed(generatedId)).called(1);
      verifyNever(() => local.markEventSynced(any()));
    });

    test('keeps queued and returns optimistic event when offline', () async {
      when(() => remote.recordEvent(any(), any()))
          .thenThrow(const NetworkException());

      final event = await repository.recordEvent('m1', params);

      expect(event.id, generatedId);
      expect(event.eventType, EventType.pointsMade);
      verify(() => local.markEventRetryable(generatedId)).called(1);
      verifyNever(() => local.markEventFailed(any()));
    });

    test('keeps queued and returns optimistic event on a 5xx error', () async {
      when(() => remote.recordEvent(any(), any())).thenThrow(
        const ServerException(
          message: 'Server down',
          code: 'INTERNAL',
          statusCode: 503,
        ),
      );

      final event = await repository.recordEvent('m1', params);

      expect(event.id, generatedId);
      verify(() => local.markEventRetryable(generatedId)).called(1);
      verifyNever(() => local.markEventFailed(any()));
    });
  });

  group('undoLastEvent', () {
    test('delegates to the remote datasource', () async {
      when(() => remote.undoLastEvent(any())).thenAnswer((_) async {});

      await repository.undoLastEvent('m1');

      verify(() => remote.undoLastEvent('m1')).called(1);
    });
  });
}
