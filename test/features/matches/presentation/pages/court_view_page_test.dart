import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_score.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_statistics.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/event_repository.dart';
import 'package:hoop_analytics/features/matches/domain/repositories/match_repository.dart';
import 'package:hoop_analytics/features/matches/presentation/models/court_view_args.dart';
import 'package:hoop_analytics/features/matches/presentation/pages/court_view_page.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_providers.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/action_button.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/player_chip.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventRepository extends Mock implements EventRepository {}

class _MockMatchRepository extends Mock implements MatchRepository {}

const _args = CourtViewArgs(
  home: CourtTeam(
    id: 'home',
    name: 'Tigres',
    roster: <RosterPlayer>[
      RosterPlayer(id: 'h4', number: 4, name: 'M. López'),
      RosterPlayer(id: 'h7', number: 7, name: 'J. Pérez'),
    ],
  ),
  away: CourtTeam(id: 'away', name: 'Águilas'),
  competitionLabel: 'Liga Nacional',
);

void main() {
  late _MockMatchRepository matches;

  setUp(() {
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
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          eventRepositoryProvider.overrideWithValue(_MockEventRepository()),
          matchRepositoryProvider.overrideWithValue(matches),
        ],
        child: const MaterialApp(
          home: CourtViewPage(matchId: 'm1', args: _args),
        ),
      ),
    );
    await tester.pump(); // run the post-frame configure()
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('renders the header, grid, stepper and player selector',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('1er CUARTO'), findsOneWidget);
    expect(find.text('TIGRES'), findsWidgets);
    expect(find.text('TIRO'), findsOneWidget);
    expect(find.byType(ActionButton), findsNWidgets(9));
    expect(find.text('JUGADOR'), findsWidgets);
    expect(find.byType(PlayerChip), findsNWidgets(2));
  });

  testWidgets('selecting an action advances the flow stepper', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('ASISTENCIA'));
    await tester.pump();

    // Step 2 "JUGADOR" label appears in the stepper (plus the section title).
    expect(find.text('JUGADOR'), findsWidgets);
  });

  testWidgets('switches to the HISTORIAL tab', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('HISTORIAL'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay acciones registradas.'), findsOneWidget);
  });
}
