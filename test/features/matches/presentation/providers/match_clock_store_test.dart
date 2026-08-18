import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/match_clock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('returns null when nothing has been stored', () async {
    expect(await MatchClockStore.read('m1'), isNull);
  });

  test('round-trips a paused clock unchanged', () async {
    await MatchClockStore.save('m1', remainingSeconds: 300, running: false);

    final snapshot = await MatchClockStore.read('m1');
    expect(snapshot, isNotNull);
    expect(snapshot!.remainingSeconds, 300);
    expect(snapshot.running, isFalse);
  });

  test('advances a running clock by the elapsed real time', () async {
    final prefs = await SharedPreferences.getInstance();
    // Simulate a clock saved 5 seconds ago that was left running.
    final fiveSecondsAgo =
        DateTime.now().millisecondsSinceEpoch - 5000;
    await prefs.setString(
      'match.clock.m1',
      '{"remaining":300,"running":true,"updatedAt":$fiveSecondsAgo}',
    );

    final snapshot = await MatchClockStore.read('m1');
    expect(snapshot, isNotNull);
    expect(snapshot!.running, isTrue);
    // 300 - ~5 elapsed; allow a little scheduling slack.
    expect(snapshot.remainingSeconds, lessThanOrEqualTo(295));
    expect(snapshot.remainingSeconds, greaterThanOrEqualTo(293));
  });

  test('a running clock that fully elapsed is reported as stopped at zero',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final longAgo = DateTime.now().millisecondsSinceEpoch - 60000;
    await prefs.setString(
      'match.clock.m1',
      '{"remaining":10,"running":true,"updatedAt":$longAgo}',
    );

    final snapshot = await MatchClockStore.read('m1');
    expect(snapshot!.remainingSeconds, 0);
    expect(snapshot.running, isFalse);
  });
}
