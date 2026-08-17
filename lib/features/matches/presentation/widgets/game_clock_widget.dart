import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The central game clock (Plan.md T-018): a large orange `mm:ss` countdown
/// with a play/pause control beneath it.
///
/// Owns its own ticking so the rest of the screen doesn't rebuild every second;
/// [onTick] reports the current value (used to timestamp recorded events) and
/// [initialSeconds] resets the clock (pass a period-derived key to restart).
class GameClockWidget extends StatefulWidget {
  const GameClockWidget({required this.initialSeconds, this.onTick, super.key});

  final int initialSeconds;
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
    // Report the initial value after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTick?.call(_formatted);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remaining <= 0) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining = (_remaining - 1).clamp(0, widget.initialSeconds);
      });
      widget.onTick?.call(_formatted);
      if (_remaining <= 0) {
        _timer?.cancel();
        setState(() => _running = false);
      }
    });
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
