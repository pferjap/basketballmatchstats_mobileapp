import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_clock_store.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/game_clock_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

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

  testWidgets('restores a persisted clock position on re-entry',
      (tester) async {
    await MatchClockStore.save('m1', remainingSeconds: 300, running: false);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameClockWidget(initialSeconds: 600, matchId: 'm1'),
        ),
      ),
    );
    // Let the async restore complete.
    await tester.pump();
    await tester.pump();

    // Restored to 05:00 instead of the 10:00 seed.
    expect(find.text('05:00'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('resumes ticking when the persisted clock was running',
      (tester) async {
    await MatchClockStore.save('m1', remainingSeconds: 120, running: true);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameClockWidget(initialSeconds: 600, matchId: 'm1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Auto-resumed: the pause control is shown because it is running.
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // Stop the timer so the test can settle.
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
  });
}
