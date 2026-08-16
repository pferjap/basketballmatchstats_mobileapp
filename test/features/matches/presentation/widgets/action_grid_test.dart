import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/presentation/models/annotation_action.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/action_button.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/action_grid.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/annotation_stepper.dart';

void main() {
  group('ActionButton', () {
    testWidgets('renders label/icon and fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ActionButton(
                label: '2 PT\nCANASTA',
                icon: Icons.sports_basketball,
                color: Colors.green,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('2 PT\nCANASTA'), findsOneWidget);
      expect(find.byIcon(Icons.sports_basketball), findsOneWidget);
      await tester.tap(find.byType(ActionButton));
      expect(taps, 1);
    });
  });

  group('ActionGrid', () {
    testWidgets('renders three sections and nine buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGrid(onActionSelected: (_) {}),
          ),
        ),
      );

      expect(find.text('TIRO'), findsOneWidget);
      expect(find.text('ACCIONES'), findsOneWidget);
      expect(find.text('FALTAS'), findsOneWidget);
      expect(find.byType(ActionButton), findsNWidgets(9));
    });

    testWidgets('reports the tapped action', (tester) async {
      AnnotationAction? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGrid(onActionSelected: (a) => selected = a),
          ),
        ),
      );

      await tester.tap(find.text('ASISTENCIA'));
      expect(selected?.id, AnnotationActionId.assist);
    });
  });

  group('AnnotationStepper', () {
    testWidgets('renders the three step labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AnnotationStepper(currentStep: 2)),
        ),
      );

      expect(find.text('TIPO DE ACCIÓN'), findsOneWidget);
      expect(find.text('JUGADOR'), findsOneWidget);
      expect(find.text('DETALLES (OPCIONAL)'), findsOneWidget);
    });
  });
}
