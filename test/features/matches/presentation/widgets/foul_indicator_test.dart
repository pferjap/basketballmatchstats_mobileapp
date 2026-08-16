import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/theme/app_colors.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/foul_indicator.dart';

void main() {
  Color? dotColor(WidgetTester tester, int index) {
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .toList(growable: false);
    final decoration = containers[index].decoration! as BoxDecoration;
    return decoration.color;
  }

  testWidgets('fills a dot per counted foul and greys the rest',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: FoulIndicator(fouls: 2))),
      ),
    );

    expect(find.text('FALTAS'), findsOneWidget);
    // 5 dot Containers total; first two orange, remaining grey.
    expect(dotColor(tester, 0), AppColors.primary);
    expect(dotColor(tester, 1), AppColors.primary);
    expect(dotColor(tester, 2), AppColors.divider);
    expect(dotColor(tester, 4), AppColors.divider);
  });
}
