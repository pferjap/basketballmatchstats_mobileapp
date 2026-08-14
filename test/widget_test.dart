// Basic smoke test for the HoopAnalytics application shell.

import 'package:flutter_test/flutter_test.dart';

import 'package:hoop_analytics/app.dart';
import 'package:hoop_analytics/core/config/env_config.dart';
import 'package:hoop_analytics/core/config/environment.dart';

void main() {
  setUp(() {
    EnvConfig.init(Environment.dev);
  });

  testWidgets('App shell renders active environment', (WidgetTester tester) async {
    await tester.pumpWidget(const HoopAnalyticsApp());

    expect(find.text('HoopAnalytics — dev'), findsOneWidget);
    expect(find.text(EnvConfig.instance.baseUrl), findsOneWidget);
  });
}
