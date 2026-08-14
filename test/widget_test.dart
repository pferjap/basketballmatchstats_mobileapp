// Basic smoke tests for the HoopAnalytics application shell and theme wiring.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hoop_analytics/app.dart';
import 'package:hoop_analytics/core/config/env_config.dart';
import 'package:hoop_analytics/core/config/environment.dart';
import 'package:hoop_analytics/core/theme/app_colors.dart';

void main() {
  setUp(() {
    EnvConfig.init(Environment.dev);
  });

  testWidgets('unauthenticated launch lands on the login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HoopAnalyticsApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('App applies the dark design-system theme',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HoopAnalyticsApp()));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = materialApp.theme!;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.primary);
  });
}
