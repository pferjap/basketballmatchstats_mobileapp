import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/models/paginated.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/match_repository.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_list_provider.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements MatchRepository {}

Match _match(String id, MatchStatus status) {
  return Match(
    id: id,
    homeTeamId: 'home-$id',
    awayTeamId: 'away-$id',
    status: status,
    scheduledAt: DateTime.utc(2024, 3, 12, 20, 30),
    competitionId: 'liga',
  );
}

Future<void> _flush() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late _MockRepository repository;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: <Override>[
        matchRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repository = _MockRepository();
  });

  test('annotate mode keeps scheduled and in-progress matches only', () async {
    when(() => repository.getMatches(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer(
      (_) async => Paginated<Match>(
        items: <Match>[
          _match('1', MatchStatus.scheduled),
          _match('2', MatchStatus.inProgress),
          _match('3', MatchStatus.finished),
        ],
        page: 1,
        limit: 20,
        total: 3,
      ),
    );

    final container = makeContainer();
    container.listen(
      matchListControllerProvider(MatchListMode.annotate),
      (_, _) {},
    );
    await _flush();

    final state =
        container.read(matchListControllerProvider(MatchListMode.annotate));
    expect(state.isLoading, isFalse);
    expect(state.matches.map((m) => m.id).toList(), <String>['1', '2']);
  });

  test('spectate mode keeps in-progress matches only', () async {
    when(() => repository.getMatches(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer(
      (_) async => Paginated<Match>(
        items: <Match>[
          _match('1', MatchStatus.scheduled),
          _match('2', MatchStatus.inProgress),
          _match('3', MatchStatus.finished),
        ],
        page: 1,
        limit: 20,
        total: 3,
      ),
    );

    final container = makeContainer();
    container.listen(
      matchListControllerProvider(MatchListMode.spectate),
      (_, _) {},
    );
    await _flush();

    final state =
        container.read(matchListControllerProvider(MatchListMode.spectate));
    expect(state.matches.map((m) => m.id).toList(), <String>['2']);
  });

  test('surfaces an error message when the initial load fails', () async {
    when(() => repository.getMatches(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenThrow(Exception('boom'));

    final container = makeContainer();
    container.listen(
      matchListControllerProvider(MatchListMode.annotate),
      (_, _) {},
    );
    await _flush();

    final state =
        container.read(matchListControllerProvider(MatchListMode.annotate));
    expect(state.isLoading, isFalse);
    expect(state.matches, isEmpty);
    expect(state.errorMessage, isNotNull);
    expect(state.hasMore, isFalse);
  });

  test('loadMore appends the next page and de-duplicates by id', () async {
    when(() => repository.getMatches(page: 1, limit: any(named: 'limit')))
        .thenAnswer(
      (_) async => Paginated<Match>(
        items: <Match>[_match('1', MatchStatus.inProgress)],
        page: 1,
        limit: 1,
        total: 2,
      ),
    );
    when(() => repository.getMatches(page: 2, limit: any(named: 'limit')))
        .thenAnswer(
      (_) async => Paginated<Match>(
        items: <Match>[
          _match('1', MatchStatus.inProgress),
          _match('2', MatchStatus.inProgress),
        ],
        page: 2,
        limit: 1,
        total: 2,
      ),
    );

    final container = makeContainer();
    container.listen(
      matchListControllerProvider(MatchListMode.spectate),
      (_, _) {},
    );
    await _flush();

    expect(
      container
          .read(matchListControllerProvider(MatchListMode.spectate))
          .hasMore,
      isTrue,
    );

    await container
        .read(matchListControllerProvider(MatchListMode.spectate).notifier)
        .loadMore();
    await _flush();

    final state =
        container.read(matchListControllerProvider(MatchListMode.spectate));
    expect(state.matches.map((m) => m.id).toList(), <String>['1', '2']);
    expect(state.hasMore, isFalse);
  });

  test('refresh reloads from the first page', () async {
    when(() => repository.getMatches(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer(
      (_) async => Paginated<Match>(
        items: <Match>[_match('1', MatchStatus.inProgress)],
        page: 1,
        limit: 20,
        total: 1,
      ),
    );

    final container = makeContainer();
    container.listen(
      matchListControllerProvider(MatchListMode.spectate),
      (_, _) {},
    );
    await _flush();

    await container
        .read(matchListControllerProvider(MatchListMode.spectate).notifier)
        .refresh();
    await _flush();

    final state =
        container.read(matchListControllerProvider(MatchListMode.spectate));
    expect(state.isRefreshing, isFalse);
    expect(state.matches.map((m) => m.id).toList(), <String>['1']);
  });
}
