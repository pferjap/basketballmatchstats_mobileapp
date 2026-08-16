import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The period dropdown in the Court View top bar (Plan.md T-018): shows the
/// current period label (e.g. "1er CUARTO") and lets the annotator switch
/// between quarters and overtime.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    required this.period,
    required this.onChanged,
    this.maxRegularPeriods = 4,
    this.overtimePeriods = 2,
    super.key,
  });

  final int period;
  final ValueChanged<int> onChanged;
  final int maxRegularPeriods;
  final int overtimePeriods;

  static String labelFor(int period, int maxRegularPeriods) {
    if (period > maxRegularPeriods) {
      return 'PRÓRROGA ${period - maxRegularPeriods}';
    }
    const ordinals = <int, String>{1: '1er', 2: '2º', 3: '3er', 4: '4º'};
    return '${ordinals[period] ?? '$periodº'} CUARTO';
  }

  @override
  Widget build(BuildContext context) {
    final total = maxRegularPeriods + overtimePeriods;
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
          if (value != null) onChanged(value);
        },
        items: <DropdownMenuItem<int>>[
          for (int p = 1; p <= total; p++)
            DropdownMenuItem<int>(
              value: p,
              child: Text(labelFor(p, maxRegularPeriods)),
            ),
        ],
      ),
    );
  }
}
