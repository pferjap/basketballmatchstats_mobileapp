import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/ws_manager.dart';
import 'package:hoop_analytics/core/theme/app_colors.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/connection_indicator.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/live_badge.dart';

Container _dotOf(WidgetTester tester) => tester.widget<Container>(
      find.byType(Container).first,
    );

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  group('LiveBadge', () {
    testWidgets('renders the EN DIRECTO label and broadcast icon',
        (tester) async {
      await pump(tester, const LiveBadge());
      expect(find.text('EN DIRECTO'), findsOneWidget);
      expect(find.byIcon(Icons.podcasts), findsOneWidget);
    });
  });

  group('ConnectionIndicator', () {
    testWidgets('is green when connected', (tester) async {
      await pump(
        tester,
        const ConnectionIndicator(state: WsConnectionState.connected),
      );
      final decoration = _dotOf(tester).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.success);
    });

    testWidgets('is amber when reconnecting and shows label', (tester) async {
      await pump(
        tester,
        const ConnectionIndicator(
          state: WsConnectionState.reconnecting,
          showLabel: true,
        ),
      );
      final decoration = _dotOf(tester).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.warning);
      expect(find.text('Reconectando…'), findsOneWidget);
    });

    testWidgets('is red when disconnected', (tester) async {
      await pump(
        tester,
        const ConnectionIndicator(state: WsConnectionState.disconnected),
      );
      final decoration = _dotOf(tester).decoration! as BoxDecoration;
      expect(decoration.color, AppColors.error);
    });
  });
}
