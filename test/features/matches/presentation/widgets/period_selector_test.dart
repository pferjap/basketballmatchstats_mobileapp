import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoop_analytics/features/matches/presentation/widgets/period_selector.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('PeriodSelector', () {
    testWidgets('labels quarters without overtime (rule 2.3)', (tester) async {
      expect(PeriodSelector.labelFor(1), '1er CUARTO');
      expect(PeriodSelector.labelFor(4), '4º CUARTO');
      expect(PeriodSelector.labelFor(5), '5º CUARTO');
    });

    testWidgets('shows exactly totalPeriods options', (tester) async {
      await tester.pumpWidget(
        wrap(
          PeriodSelector(
            period: 1,
            totalPeriods: 6,
            canAdvance: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      // Menu items + the selected value shown in the button => 6 + 1.
      expect(find.text('6º CUARTO'), findsWidgets);
      expect(find.text('1er CUARTO'), findsWidgets);
    });

    testWidgets('does not advance to next quarter while clock is running',
        (tester) async {
      int? selected;
      await tester.pumpWidget(
        wrap(
          PeriodSelector(
            period: 1,
            totalPeriods: 4,
            canAdvance: false,
            onChanged: (value) => selected = value,
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2º CUARTO').last);
      await tester.pumpAndSettle();
      expect(selected, isNull);
    });

    testWidgets('advances to next quarter once the clock has ended',
        (tester) async {
      int? selected;
      await tester.pumpWidget(
        wrap(
          PeriodSelector(
            period: 1,
            totalPeriods: 4,
            canAdvance: true,
            onChanged: (value) => selected = value,
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2º CUARTO').last);
      await tester.pumpAndSettle();
      expect(selected, 2);
    });
  });
}
