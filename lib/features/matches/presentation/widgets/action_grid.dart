import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../models/annotation_action.dart';
import 'action_button.dart';

/// The 3×3 grid of annotation actions grouped into TIRO / ACCIONES / FALTAS
/// sections (Plan.md T-019). Selecting a tile calls [onActionSelected].
class ActionGrid extends StatelessWidget {
  const ActionGrid({
    required this.onActionSelected,
    this.selectedAction,
    this.actions = kAnnotationActions,
    super.key,
  });

  final ValueChanged<AnnotationAction> onActionSelected;
  final AnnotationActionId? selectedAction;
  final List<AnnotationAction> actions;

  static const Map<AnnotationCategory, String> _sectionTitles =
      <AnnotationCategory, String>{
        AnnotationCategory.shot: 'TIRO',
        AnnotationCategory.action: 'ACCIONES',
        AnnotationCategory.foul: 'FALTAS',
      };

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: 2,
      ),
      children: <Widget>[
        for (final category in AnnotationCategory.values)
          _Section(
            title: _sectionTitles[category]!,
            actions: actions.where((a) => a.category == category).toList(),
            selectedAction: selectedAction,
            onActionSelected: onActionSelected,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.actions,
    required this.selectedAction,
    required this.onActionSelected,
  });

  final String title;
  final List<AnnotationAction> actions;
  final AnnotationActionId? selectedAction;
  final ValueChanged<AnnotationAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
          child: Row(
            children: <Widget>[
              const Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
        ),
        Row(
          children: <Widget>[
            for (int i = 0; i < actions.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: kSpacingS),
              Expanded(
                child: ActionButton(
                  label: actions[i].label,
                  icon: actions[i].icon,
                  color: actions[i].color,
                  selected: actions[i].id == selectedAction,
                  dangerBackground:
                      actions[i].category == AnnotationCategory.foul,
                  onTap: () => onActionSelected(actions[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
