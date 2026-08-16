import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/presentation/models/court_view_args.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/annotation_bottom_bar.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/player_carousel.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/player_chip.dart';

const _home = CourtTeam(
  id: 'home',
  name: 'Tigres',
  roster: <RosterPlayer>[
    RosterPlayer(id: 'p4', number: 4, name: 'M. López'),
    RosterPlayer(id: 'p7', number: 7, name: 'J. Pérez'),
    RosterPlayer(id: 'p11', number: 11, name: 'A. García'),
  ],
);
const _away = CourtTeam(id: 'away', name: 'Águilas');

void main() {
  group('PlayerCarousel', () {
    testWidgets('renders a chip per player and reports selection',
        (tester) async {
      RosterPlayer? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerCarousel(
              players: _home.roster,
              selectedPlayerId: 'p7',
              onPlayerSelected: (p) => tapped = p,
            ),
          ),
        ),
      );

      expect(find.byType(PlayerChip), findsNWidgets(3));
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('J. Pérez'), findsOneWidget);

      await tester.tap(find.text('M. López'));
      expect(tapped?.id, 'p4');
    });
  });

  group('AnnotationBottomBar', () {
    testWidgets('shows the annotated team and disables undo when empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationBottomBar(
              home: _home,
              away: _away,
              annotatingTeamId: 'home',
              onTeamChanged: (_) {},
              onUndo: () {},
              undoEnabled: false,
            ),
          ),
        ),
      );

      expect(find.text('TIGRES'), findsOneWidget);
      expect(find.text('DESHACER\nÚLTIMA ACCIÓN'), findsOneWidget);

      final undo = tester.widget<TextButton>(find.byType(TextButton));
      expect(undo.onPressed, isNull);
    });

    testWidgets('fires undo when enabled', (tester) async {
      var undone = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationBottomBar(
              home: _home,
              away: _away,
              annotatingTeamId: 'home',
              onTeamChanged: (_) {},
              onUndo: () => undone++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      expect(undone, 1);
    });
  });
}
