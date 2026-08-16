import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/game_clock_widget.dart';

void main() {
  testWidgets('shows the formatted clock and reports the initial value',
      (tester) async {
    final ticks = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameClockWidget(
            initialSeconds: 452,
            onTick: ticks.add,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('07:32'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(ticks, contains('07:32'));
  });

  testWidgets('toggles to pause and counts down when started', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GameClockWidget(initialSeconds: 452)),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('07:31'), findsOneWidget);

    // Stop the timer so the test can settle.
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
  });
}
