import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A row of dots showing a team's counted fouls for the current period: filled
/// (orange) up to [fouls], muted (grey) for the remaining slots up to [total]
/// (Plan.md T-018). The bonus threshold is [total] (FIBA: 5 team fouls).
class FoulIndicator extends StatelessWidget {
  const FoulIndicator({required this.fouls, this.total = 5, super.key});

  final int fouls;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'FALTAS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        for (int i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < fouls ? AppColors.primary : AppColors.divider,
              ),
            ),
          ),
      ],
    );
  }
}
