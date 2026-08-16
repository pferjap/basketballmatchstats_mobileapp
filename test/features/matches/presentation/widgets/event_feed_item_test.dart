import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_event.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/event_feed_item.dart';

MatchEvent buildEvent({
  String id = 'e1',
  String teamId = 'home',
  String? playerId,
  EventType eventType = EventType.pointsMade,
  String gameClock = '05:47',
  Map<String, dynamic>? metadata,
}) {
  return MatchEvent(
    id: id,
    matchId: 'm1',
    teamId: teamId,
    playerId: playerId,
    eventType: eventType,
    period: 3,
    gameClock: gameClock,
    metadata: metadata,
    createdAt: DateTime.utc(2024, 1, 1, 20),
  );
}

void main() {
  group('eventVisualFor', () {
    test('distinguishes 2-point, 3-point and free-throw makes', () {
      expect(buildEvent(metadata: {'points': 2}).let(eventVisualFor).title,
          'Canasta de 2 puntos');
      expect(buildEvent(metadata: {'points': 3}).let(eventVisualFor).title,
          'Triple');
      expect(buildEvent(metadata: {'points': 1}).let(eventVisualFor).title,
          'Tiro libre anotado');
    });

    test('maps other event types to Spanish titles', () {
      expect(
        eventVisualFor(buildEvent(eventType: EventType.reboundDefensive)).title,
        'Rebote defensivo',
      );
      expect(
        eventVisualFor(buildEvent(eventType: EventType.turnover)).title,
        'Pérdida',
      );
      expect(
        eventVisualFor(buildEvent(eventType: EventType.substitution)).title,
        'Sustitución',
      );
    });
  });

  Future<void> pump(WidgetTester tester, MatchEvent event) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventFeedItem(
            event: event,
            homeTeamId: 'home',
            awayTeamId: 'away',
            homeTeamName: 'Tigres',
            awayTeamName: 'Águilas',
          ),
        ),
      ),
    );
  }

  group('EventFeedItem', () {
    testWidgets('shows title, clock and player label', (tester) async {
      await pump(
        tester,
        buildEvent(
          playerId: 'p7',
          metadata: {'points': 2, 'playerNumber': 7, 'playerName': 'Carlos'},
        ),
      );
      expect(find.text('Canasta de 2 puntos'), findsOneWidget);
      expect(find.text('05:47'), findsOneWidget);
      expect(find.text('#7 Carlos'), findsOneWidget);
    });

    testWidgets('renders substitution in/out detail', (tester) async {
      await pump(
        tester,
        buildEvent(
          eventType: EventType.substitution,
          metadata: {
            'playerInNumber': 9,
            'playerInName': 'Álvaro Ruiz',
            'playerOutNumber': 15,
            'playerOutName': 'Daniel Torres',
          },
        ),
      );
      expect(find.text('Entra #9 Álvaro Ruiz'), findsOneWidget);
      expect(find.text('Sale #15 Daniel Torres'), findsOneWidget);
    });

    testWidgets('shows the partial score and scoring team label',
        (tester) async {
      await pump(
        tester,
        buildEvent(
          teamId: 'home',
          metadata: {'points': 2, 'homeScore': 72, 'awayScore': 68},
        ),
      );
      expect(find.textContaining('72 - 68'), findsOneWidget);
      expect(find.text('TIGRES'), findsOneWidget);
    });
  });
}

extension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
