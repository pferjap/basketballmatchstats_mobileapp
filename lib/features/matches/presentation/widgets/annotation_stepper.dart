import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';

/// The 1-2-3 flow indicator under the action grid (Plan.md T-019): TIPO DE
/// ACCIÓN → JUGADOR → DETALLES (OPCIONAL), with [currentStep] highlighted.
class AnnotationStepper extends StatelessWidget {
  const AnnotationStepper({required this.currentStep, super.key});

  final int currentStep;

  static const List<String> _labels = <String>[
    'TIPO DE ACCIÓN',
    'JUGADOR',
    'DETALLES (OPCIONAL)',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingS,
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _labels.length; i++) ...<Widget>[
            if (i > 0)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: kSpacingXS),
                  child: DottedLine(),
                ),
              ),
            _Step(
              index: i + 1,
              label: _labels[i],
              active: currentStep == i + 1,
              done: currentStep > i + 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final highlight = active || done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight ? AppColors.primary : AppColors.divider,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: highlight ? AppColors.background : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A thin dashed connector between stepper nodes.
class DottedLine extends StatelessWidget {
  const DottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 6).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              dashCount.clamp(1, 40),
              (_) => const SizedBox(
                width: 3,
                height: 1,
                child: ColoredBox(color: AppColors.divider),
              ),
            ),
          );
        },
      ),
    );
  }
}
