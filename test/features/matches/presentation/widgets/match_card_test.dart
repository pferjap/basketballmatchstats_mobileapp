import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/match_card.dart';

Match _match(MatchStatus status) {
  return Match(
    id: 'm1',
    homeTeamId: 'Tigres',
    awayTeamId: 'Águilas',
    status: status,
    scheduledAt: DateTime(2024, 3, 12, 20, 30),
    competitionId: 'Liga ACB',
  );
}

Future<void> _pump(WidgetTester tester, Match match, VoidCallback onTap) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MatchCard(match: match, onTap: onTap),
      ),
    ),
  );
}

void main() {
  testWidgets('renders teams, competition and formatted date', (tester) async {
    await _pump(tester, _match(MatchStatus.scheduled), () {});

    expect(find.text('Tigres  vs  Águilas'), findsOneWidget);
    expect(find.text('Liga ACB'), findsOneWidget);
    expect(find.text('12 mar 2024 · 20:30'), findsOneWidget);
  });

  testWidgets('shows the right badge per status', (tester) async {
    await _pump(tester, _match(MatchStatus.scheduled), () {});
    expect(find.text('PROGRAMADO'), findsOneWidget);

    await _pump(tester, _match(MatchStatus.inProgress), () {});
    expect(find.text('EN DIRECTO'), findsOneWidget);

    await _pump(tester, _match(MatchStatus.finished), () {});
    expect(find.text('FINALIZADO'), findsOneWidget);
  });

  testWidgets('invokes onTap when pressed', (tester) async {
    var tapped = false;
    await _pump(tester, _match(MatchStatus.inProgress), () => tapped = true);

    await tester.tap(find.byType(MatchCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  test('formatMatchDateTime formats in Spanish', () {
    expect(
      formatMatchDateTime(DateTime(2024, 1, 5, 9, 5)),
      '5 ene 2024 · 09:05',
    );
  });
}
