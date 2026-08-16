import 'package:flutter/material.dart';

import '../../../../core/network/ws_manager.dart';
import '../../../../core/theme/app_colors.dart';

/// A small colored dot reflecting the realtime [WsConnectionState]
/// (green = connected, amber = reconnecting, red = disconnected).
///
/// Plan.md T-017 / Agent_Mobile §8.2.
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({
    required this.state,
    this.showLabel = false,
    super.key,
  });

  final WsConnectionState state;

  /// Whether to render the textual status next to the dot.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            _labelFor(state),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  static Color _colorFor(WsConnectionState state) {
    switch (state) {
      case WsConnectionState.connected:
        return AppColors.success;
      case WsConnectionState.reconnecting:
        return AppColors.warning;
      case WsConnectionState.disconnected:
        return AppColors.error;
    }
  }

  static String _labelFor(WsConnectionState state) {
    switch (state) {
      case WsConnectionState.connected:
        return 'Conectado';
      case WsConnectionState.reconnecting:
        return 'Reconectando…';
      case WsConnectionState.disconnected:
        return 'Sin conexión';
    }
  }
}
