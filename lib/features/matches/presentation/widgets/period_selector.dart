import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The period dropdown in the Court View top bar (Plan.md T-018): shows the
/// current period label (e.g. "1er CUARTO") and lets the annotator switch
/// between quarters.
///
/// Overtimes were removed (Plan.md T-046, rule 2.3): a match has exactly
/// [totalPeriods] regular quarters. Advancing to the next quarter is gated by
/// [canAdvance] (rule 2.2): the annotator cannot start the next quarter until
/// the current one's clock has reached `00:00`.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    required this.period,
    required this.onChanged,
    this.totalPeriods = 4,
    this.canAdvance = false,
    super.key,
  });

  final int period;
  final ValueChanged<int> onChanged;

  /// Number of regular quarters configured for the match.
  final int totalPeriods;

  /// Whether the current quarter has finished (clock at `00:00`), which unlocks
  /// selecting the next quarter.
  final bool canAdvance;

  static String labelFor(int period) {
    const ordinals = <int, String>{1: '1er', 2: '2º', 3: '3er', 4: '4º'};
    return '${ordinals[period] ?? '$periodº'} CUARTO';
  }

  bool _isSelectable(int p) {
    // Already-played quarters can be revisited; the next quarter unlocks only
    // once the current one's clock has run out.
    if (p <= period) {
      return true;
    }
    return p == period + 1 && canAdvance;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: period,
        isDense: true,
        dropdownColor: AppColors.surface,
        iconEnabledColor: AppColors.textPrimary,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        onChanged: (value) {
          if (value != null && _isSelectable(value)) onChanged(value);
        },
        items: <DropdownMenuItem<int>>[
          for (int p = 1; p <= totalPeriods; p++)
            DropdownMenuItem<int>(
              value: p,
              enabled: _isSelectable(p),
              child: Text(
                labelFor(p),
                style: TextStyle(
                  color: _isSelectable(p)
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
