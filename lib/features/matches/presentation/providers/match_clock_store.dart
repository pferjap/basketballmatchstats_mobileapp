import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A restored game-clock reading for a match: the remaining seconds and whether
/// the clock was running when it was last saved.
class MatchClockSnapshot {
  const MatchClockSnapshot({
    required this.remainingSeconds,
    required this.running,
  });

  final int remainingSeconds;
  final bool running;
}

/// Persists the match game clock locally (keyed by match id) so it survives
/// leaving and re-entering the Court View / live screens.
///
/// The clock is purely client-side (the API has no running-clock state), so we
/// store an *anchor*: the remaining seconds, whether it was running, and the
/// wall-clock timestamp of the save. When a running clock is read back, the
/// real time elapsed since the anchor is subtracted, so the clock keeps
/// advancing while the screen is closed (and stays in sync between the
/// annotator and a spectator on the same device).
class MatchClockStore {
  const MatchClockStore._();

  static String _key(String matchId) => 'match.clock.$matchId';

  /// Saves the current clock position for [matchId].
  static Future<void> save(
    String matchId, {
    required int remainingSeconds,
    required bool running,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(matchId),
      jsonEncode(<String, dynamic>{
        'remaining': remainingSeconds,
        'running': running,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  /// Reads the last saved clock for [matchId], advancing it by the real time
  /// elapsed since the save when it was left running. Returns `null` when no
  /// clock has been stored yet.
  static Future<MatchClockSnapshot?> read(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(matchId));
    if (raw == null) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final remaining = (map['remaining'] as num).toInt();
      final running = map['running'] as bool? ?? false;
      final updatedAt = (map['updatedAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;
      if (!running) {
        return MatchClockSnapshot(remainingSeconds: remaining, running: false);
      }
      final elapsed =
          (DateTime.now().millisecondsSinceEpoch - updatedAt) ~/ 1000;
      final adjusted = (remaining - elapsed).clamp(0, remaining);
      return MatchClockSnapshot(
        remainingSeconds: adjusted,
        running: adjusted > 0,
      );
    } catch (_) {
      return null;
    }
  }
}
