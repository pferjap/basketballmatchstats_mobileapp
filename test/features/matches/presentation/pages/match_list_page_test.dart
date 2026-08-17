import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/models/paginated.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/match_repository.dart';
import 'package:hoop_analytics/features/matches/presentation/pages/match_list_page.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_list_provider.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_providers.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/match_card.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements MatchRepository {}

Match _match(String id, MatchStatus status) {
  return Match(
    id: id,
    homeTeamId: 'home-$id',
    awayTeamId: 'away-$id',
    status: status,
    scheduledAt: DateTime(2024, 3, 12, 20, 30),
    competitionId: 'liga',
  );
}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
  });

  Future<void> pumpPage(WidgetTester tester, MatchListMode mode) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          matchRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(home: MatchListPage(mode: mode)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('renders a card per filtered match', (tester) async {
    when(() => repository.getMatches(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer(
      (_) async => Paginated<Match>(
        items: <Match>[
          _match('1', MatchStatus.inProgress),
          _match('2', MatchStatus.inProgress),
        ],
        page: 1,
        limit: 20,
        total: 2,
      ),
    );

    await pumpPage(tester, MatchListMode.spectate);

    expect(find.byType(MatchCard), findsNWidgets(2));
    expect(find.text('Asistir a un partido'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no matches',
      (tester) async {
    when(() => repository.getMatches(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenAnswer(
      (_) async => const Paginated<Match>(items: <Match>[]),
    );

    await pumpPage(tester, MatchListMode.spectate);

    expect(find.byType(MatchCard), findsNothing);
    expect(find.text('No hay partidos en directo ahora mismo.'),
        findsOneWidget);
  });

  testWidgets('shows an error message when the load fails', (tester) async {
    when(() => repository.getMatches(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        )).thenThrow(Exception('boom'));

    await pumpPage(tester, MatchListMode.annotate);

    expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
  });
}
