import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/connectivity_monitor.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late ConnectivityMonitor monitor;

  setUp(() {
    connectivity = _MockConnectivity();
    monitor = ConnectivityMonitor(connectivity: connectivity);
  });

  group('checkOnce', () {
    test('is false when the only transport is none', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.none],
      );
      expect(await monitor.checkOnce(), isFalse);
    });

    test('is true when any active transport is present', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[
          ConnectivityResult.wifi,
          ConnectivityResult.mobile,
        ],
      );
      expect(await monitor.checkOnce(), isTrue);
    });
  });

  group('isOnline', () {
    test('maps transport changes to booleans and de-duplicates', () {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream<List<ConnectivityResult>>.fromIterable(
          <List<ConnectivityResult>>[
            <ConnectivityResult>[ConnectivityResult.none],
            <ConnectivityResult>[ConnectivityResult.wifi],
            <ConnectivityResult>[ConnectivityResult.ethernet],
            <ConnectivityResult>[ConnectivityResult.none],
          ],
        ),
      );

      expect(
        monitor.isOnline,
        emitsInOrder(<Object>[false, true, false, emitsDone]),
      );
    });
  });
}
