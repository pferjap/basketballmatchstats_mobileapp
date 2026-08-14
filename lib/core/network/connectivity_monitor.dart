import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports device network reachability as a boolean stream
/// (Agent_Mobile.md §8.2).
///
/// The device is considered online when at least one active transport (WiFi,
/// mobile, ethernet, …) is present. `connectivity_plus` reports radio status
/// only, not end-to-end reachability.
class ConnectivityMonitor {
  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits `true` while any non-`none` transport is available.
  Stream<bool> get isOnline =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  /// One-shot reachability check against the current transport status.
  Future<bool> checkOnce() async =>
      _isOnline(await _connectivity.checkConnectivity());

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);
}
