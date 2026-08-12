// Basic smoke test for the HoopAnalytics application shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:hoop_analytics/app.dart';

void main() {
  testWidgets('App shell renders environment label', (WidgetTester tester) async {
    await tester.pumpWidget(const HoopAnalyticsApp(environmentLabel: 'dev'));

    expect(find.text('HoopAnalytics — dev'), findsOneWidget);
  });
}
