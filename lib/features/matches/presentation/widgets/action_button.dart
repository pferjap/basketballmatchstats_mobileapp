import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';

/// A large, tappable action tile (icon over label) used in the annotation grid
/// (Plan.md T-019). Touch target ≥ 56dp; fires light haptic feedback on tap.
class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.selected = false,
    this.dangerBackground = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Highlights the tile when it is the currently selected action.
  final bool selected;

  /// Uses a red-tinted background (for the FALTAS section).
  final bool dangerBackground;

  @override
  Widget build(BuildContext context) {
    final background = dangerBackground
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.surface;
    final border = selected
        ? color
        : dangerBackground
        ? AppColors.error.withValues(alpha: 0.4)
        : AppColors.divider;

    return Semantics(
      button: true,
      selected: selected,
      label: label.replaceAll('\n', ' '),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(
              minHeight: kActionButtonSize,
              minWidth: kActionButtonSize,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: kSpacingM,
              horizontal: kSpacingS,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: selected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: color, size: 30),
                const SizedBox(height: kSpacingS),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
