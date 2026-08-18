import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/match_clock_store.dart';

/// The central game clock (Plan.md T-018): a large orange `mm:ss` countdown
/// with a play/pause control beneath it.
///
/// Owns its own ticking so the rest of the screen doesn't rebuild every second.
/// [onTick] reports the current value (used to timestamp recorded events) and
/// [initialSeconds] seeds a *fresh* clock. When [matchId] is provided the clock
/// is persisted locally via [MatchClockStore], so leaving and re-entering the
/// screen resumes exactly where it left off (and keeps ticking if it was
/// running) instead of resetting.
class GameClockWidget extends StatefulWidget {
  const GameClockWidget({
    required this.initialSeconds,
    this.matchId,
    this.onTick,
    super.key,
  });

  final int initialSeconds;

  /// Match this clock belongs to; enables local persistence when non-null.
  final String? matchId;
  final ValueChanged<String>? onTick;

  @override
  State<GameClockWidget> createState() => _GameClockWidgetState();
}

class _GameClockWidgetState extends State<GameClockWidget> {
  late int _remaining = widget.initialSeconds;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  /// Restores the persisted clock (if any) and resumes ticking when it was
  /// left running; otherwise reports the seeded value.
  Future<void> _restore() async {
    final id = widget.matchId;
    if (id != null) {
      final snapshot = await MatchClockStore.read(id);
      if (!mounted) return;
      if (snapshot != null) {
        setState(() => _remaining = snapshot.remainingSeconds);
        widget.onTick?.call(_formatted);
        if (snapshot.running && _remaining > 0) {
          _start();
        }
        return;
      }
    }
    widget.onTick?.call(_formatted);
  }

  @override
  void didUpdateWidget(GameClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-seed on an external change (e.g. a new period) while paused; a
    // running clock and any persisted position always win.
    if (widget.initialSeconds != oldWidget.initialSeconds && !_running) {
      setState(() => _remaining = widget.initialSeconds);
      widget.onTick?.call(_formatted);
      _persist();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Persist the exact position (and running flag) so re-entry resumes it.
    _persist();
    super.dispose();
  }

  void _persist() {
    final id = widget.matchId;
    if (id != null) {
      MatchClockStore.save(
        id,
        remainingSeconds: _remaining,
        running: _running,
      );
    }
  }

  String get _formatted {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _start() {
    if (_running || _remaining <= 0) return;
    setState(() => _running = true);
    _persist();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining = (_remaining - 1).clamp(0, _remaining));
      widget.onTick?.call(_formatted);
      if (_remaining <= 0) {
        _timer?.cancel();
        setState(() => _running = false);
        _persist();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
    _persist();
  }

  void _toggle() {
    if (_running) {
      _pause();
    } else {
      _start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _formatted,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          onPressed: _toggle,
          iconSize: 28,
          color: AppColors.primary,
          icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          tooltip: _running ? 'Pausar reloj' : 'Iniciar reloj',
        ),
      ],
    );
  }
}
