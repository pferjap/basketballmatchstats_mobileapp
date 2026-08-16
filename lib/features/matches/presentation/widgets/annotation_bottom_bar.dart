import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../models/court_view_args.dart';

/// The fixed bottom bar of the Court View (Plan.md T-020): a dropdown to switch
/// the team being annotated (left) and the emergency "undo last action" button
/// (right).
class AnnotationBottomBar extends StatelessWidget {
  const AnnotationBottomBar({
    required this.home,
    required this.away,
    required this.annotatingTeamId,
    required this.onTeamChanged,
    required this.onUndo,
    this.undoEnabled = true,
    super.key,
  });

  final CourtTeam home;
  final CourtTeam away;
  final String annotatingTeamId;
  final ValueChanged<String> onTeamChanged;
  final VoidCallback onUndo;
  final bool undoEnabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingM,
          vertical: kSpacingS,
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.groups, color: AppColors.primary, size: 22),
            const SizedBox(width: kSpacingS),
            const Text(
              'EQUIPO',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: kSpacingS),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: annotatingTeamId,
                isDense: true,
                dropdownColor: AppColors.surface,
                iconEnabledColor: AppColors.primary,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                onChanged: (value) {
                  if (value != null) onTeamChanged(value);
                },
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: home.id,
                    child: Text(home.name.toUpperCase()),
                  ),
                  DropdownMenuItem<String>(
                    value: away.id,
                    child: Text(away.name.toUpperCase()),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: undoEnabled ? onUndo : null,
              icon: const Icon(Icons.undo, color: AppColors.primary),
              label: const Text(
                'DESHACER\nÚLTIMA ACCIÓN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
