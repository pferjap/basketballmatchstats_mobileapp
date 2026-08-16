import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../models/court_view_args.dart';
import 'player_chip.dart';

/// The horizontal roster selector (Plan.md T-020): a scrollable row of
/// [PlayerChip]s flanked by "<" / ">" arrows. Selecting a player calls
/// [onPlayerSelected].
class PlayerCarousel extends StatefulWidget {
  const PlayerCarousel({
    required this.players,
    required this.onPlayerSelected,
    this.selectedPlayerId,
    super.key,
  });

  final List<RosterPlayer> players;
  final ValueChanged<RosterPlayer> onPlayerSelected;
  final String? selectedPlayerId;

  @override
  State<PlayerCarousel> createState() => _PlayerCarouselState();
}

class _PlayerCarouselState extends State<PlayerCarousel> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nudge(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(kSpacingM),
        child: Text(
          'No hay jugadores en pista.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: () => _nudge(-160),
          icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          tooltip: 'Anterior',
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final player in widget.players)
                  PlayerChip(
                    key: ValueKey<String>(player.id),
                    player: player,
                    selected: player.id == widget.selectedPlayerId,
                    onTap: () => widget.onPlayerSelected(player),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => _nudge(160),
          icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          tooltip: 'Siguiente',
        ),
      ],
    );
  }
}
