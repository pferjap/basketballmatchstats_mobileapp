import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/court_view_args.dart';

/// A single player in the selector carousel (Plan.md T-020): a circle with the
/// jersey number and the name beneath. Selected chips are filled orange.
class PlayerChip extends StatelessWidget {
  const PlayerChip({
    required this.player,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final RosterPlayer player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final numberColor = selected ? AppColors.background : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '#${player.number} ${player.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: Text(
                  '${player.number}',
                  style: TextStyle(
                    color: numberColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 68,
                child: Text(
                  player.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
