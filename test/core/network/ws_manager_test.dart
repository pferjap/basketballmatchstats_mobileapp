import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/ws_manager.dart';

void main() {
  group('ReconnectConfig.delayForAttempt', () {
    const config = ReconnectConfig(jitter: false);

    test('grows exponentially from the initial delay', () {
      expect(config.delayForAttempt(1).inMilliseconds, 1000);
      expect(config.delayForAttempt(2).inMilliseconds, 2000);
      expect(config.delayForAttempt(3).inMilliseconds, 4000);
      expect(config.delayForAttempt(4).inMilliseconds, 8000);
      expect(config.delayForAttempt(5).inMilliseconds, 16000);
    });

    test('caps at maxDelay', () {
      expect(config.delayForAttempt(6).inMilliseconds, 30000);
      expect(config.delayForAttempt(20).inMilliseconds, 30000);
    });

    test('applies jitter within ±jitterFactor of the base delay', () {
      const jittered = ReconnectConfig();
      final random = Random(42);
      for (var attempt = 1; attempt <= 5; attempt++) {
        final base = ReconnectConfig(jitter: false)
            .delayForAttempt(attempt)
            .inMilliseconds;
        final delay =
            jittered.delayForAttempt(attempt, random: random).inMilliseconds;
        expect(delay, greaterThanOrEqualTo((base * 0.8).floor()));
        expect(delay, lessThanOrEqualTo((base * 1.2).ceil()));
      }
    });
  });

  group('payloadToMap', () {
    test('returns typed maps unchanged', () {
      final input = <String, dynamic>{'a': 1};
      expect(payloadToMap(input), same(input));
    });

    test('stringifies keys of loosely typed maps', () {
      final result = payloadToMap(<dynamic, dynamic>{1: 'x', 'b': 2});
      expect(result, <String, dynamic>{'1': 'x', 'b': 2});
    });

    test('wraps non-map payloads under a data key', () {
      expect(payloadToMap('hello'), <String, dynamic>{'data': 'hello'});
      expect(payloadToMap(null), <String, dynamic>{'data': null});
    });
  });
}
