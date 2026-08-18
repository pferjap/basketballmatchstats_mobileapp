import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_event.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_score.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_statistics.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/event_repository.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/match_repository.dart';
import 'package:hoop_analytics/features/matches/presentation/models/annotation_action.dart';
import 'package:hoop_analytics/features/matches/presentation/models/court_view_args.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/annotation_state_provider.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventRepository extends Mock implements EventRepository {}

class _MockMatchRepository extends Mock implements MatchRepository {}

class _FakeEventParams extends Fake implements EventParams {}

const _args = CourtViewArgs(
  home: CourtTeam(
    id: 'home',
    name: 'Tigres',
    roster: <RosterPlayer>[RosterPlayer(id: 'h7', number: 7, name: 'J. Pérez')],
  ),
  away: CourtTeam(
    id: 'away',
    name: 'Águilas',
    roster: <RosterPlayer>[RosterPlayer(id: 'a5', number: 5, name: 'A. Ruiz')],
  ),
);

const _homePlayer = RosterPlayer(id: 'h7', number: 7, name: 'J. Pérez');

MatchEvent _serverEvent(String id) => MatchEvent(
      id: id,
      matchId: 'm1',
      teamId: 'home',
      eventType: EventType.assist,
      period: 1,
      gameClock: '10:00',
      createdAt: DateTime.now(),
    );

AnnotationAction _action(AnnotationActionId id) =>
    kAnnotationActions.firstWhere((a) => a.id == id);

void main() {
  setUpAll(() => registerFallbackValue(_FakeEventParams()));

  late _MockEventRepository events;
  late _MockMatchRepository matches;
  late ProviderContainer container;

  setUp(() {
    events = _MockEventRepository();
    matches = _MockMatchRepository();

    when(() => matches.getMatchStatistics(any())).thenAnswer(
      (_) async => const MatchStatistics(
        score: MatchScore(
          matchId: 'm1',
          homeTeamScore: 0,
          awayTeamScore: 0,
          currentPeriod: 1,
          gameClock: '10:00',
        ),
        playerStats: <Never>[],
      ),
    );
    when(() => events.recordEvent(any(), any()))
        .thenAnswer((_) async => _serverEvent('srv'));
    when(() => events.undoLastEvent(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: <Override>[
        eventRepositoryProvider.overrideWithValue(events),
        matchRepositoryProvider.overrideWithValue(matches),
      ],
    );
    addTearDown(container.dispose);
  });

  AnnotationController controller() =>
      container.read(annotationControllerProvider('m1').notifier);
  AnnotationState read() => container.read(annotationControllerProvider('m1'));

  test('records a non-shot action in three taps and marks it synced', () async {
    container.listen(annotationControllerProvider('m1'), (_, _) {});
    await controller().configure(_args);

    controller().selectAction(_action(AnnotationActionId.assist));
    expect(read().currentStep, 2);
    expect(read().selectedAction?.id, AnnotationActionId.assist);

    await controller().selectPlayer(_homePlayer);
    expect(read().currentStep, 3);
    expect(read().events, isEmpty);

    await controller().confirmDetails();

    final state = read();
    expect(state.events.length, 1);
    expect(state.events.first.status, EventSyncStatus.synced);
    expect(state.currentStep, 1); // flow reset
    verify(() => events.recordEvent('m1', any())).called(1);
  });

  test('shot actions require the details step before recording', () async {
    container.listen(annotationControllerProvider('m1'), (_, _) {});
    await controller().configure(_args);

    controller().selectAction(_action(AnnotationActionId.twoPoints));
    await controller().selectPlayer(_homePlayer);
    // Not recorded yet: waiting on details confirmation.
    expect(read().currentStep, 3);
    expect(read().events, isEmpty);

    await controller().confirmDetails();
    expect(read().events.length, 1);
    expect(read().homeScore, 2);
  });

  test('personal fouls bump the team foul count for the period', () async {
    container.listen(annotationControllerProvider('m1'), (_, _) {});
    await controller().configure(_args);

    controller().selectAction(_action(AnnotationActionId.foulPersonal));
    await controller().selectPlayer(_homePlayer);
    await controller().confirmDetails();

    expect(read().homeFouls, 1);
    expect(read().awayFouls, 0);
  });

  test('undo removes the most recent event', () async {
    container.listen(annotationControllerProvider('m1'), (_, _) {});
    await controller().configure(_args);
    controller().selectAction(_action(AnnotationActionId.assist));
    await controller().selectPlayer(_homePlayer);
    await controller().confirmDetails();
    expect(read().events.length, 1);

    await controller().undoLast();
    expect(read().events, isEmpty);
    verify(() => events.undoLastEvent('m1')).called(1);
  });

  test('a failed record is marked failed and rolls back its score', () async {
    when(() => events.recordEvent(any(), any()))
        .thenThrow(Exception('rejected'));
    container.listen(annotationControllerProvider('m1'), (_, _) {});
    await controller().configure(_args);

    controller().selectAction(_action(AnnotationActionId.twoPoints));
    await controller().selectPlayer(_homePlayer);
    await controller().confirmDetails();

    final state = read();
    expect(state.events.single.status, EventSyncStatus.failed);
    expect(state.homeScore, 0); // failed events excluded from the score
    expect(state.errorMessage, isNotNull);
  });
}
