import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/ws_manager.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_event.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_score.dart';
import 'package:hoop_analytics/features/matches/presentation/pages/match_live_page.dart';
import 'package:hoop_analytics/features/matches/presentation/providers/live_match_provider.dart';

class _FakeController extends LiveMatchController {
  _FakeController(this._state);

  final LiveMatchState _state;

  @override
  LiveMatchState build(String arg) => _state;

  @override
  Future<void> loadEarlier() async {}
}

void main() {
  final fixture = LiveMatchState(
    isLoading: false,
    connection: WsConnectionState.connected,
    score: const MatchScore(
      matchId: 'm1',
      homeTeamScore: 72,
      awayTeamScore: 68,
      currentPeriod: 3,
      gameClock: '05:47',
    ),
    events: <MatchEvent>[
      MatchEvent(
        id: 'e1',
        matchId: 'm1',
        teamId: 'home',
        eventType: EventType.pointsMade,
        period: 3,
        gameClock: '05:47',
        metadata: const <String, dynamic>{
          'points': 2,
          'playerNumber': 7,
          'playerName': 'Carlos Martínez',
          'homeScore': 72,
          'awayScore': 68,
        },
        createdAt: DateTime.utc(2024, 1, 1, 20),
      ),
    ],
  );

  testWidgets('renders header, feed and load-earlier action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          liveMatchControllerProvider
              .overrideWith(() => _FakeController(fixture)),
        ],
        child: const MaterialApp(
          home: MatchLivePage(
            matchId: 'm1',
            args: LiveMatchArgs(
              homeTeamId: 'home',
              awayTeamId: 'away',
              homeTeamName: 'Tigres',
              homeClubName: 'Tigres Basket',
              awayTeamName: 'Águilas',
              awayClubName: 'Águilas BC',
              competitionLabel: 'Liga Nacional · Jornada 12',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tigres vs Águilas'), findsOneWidget);
    expect(find.text('Liga Nacional · Jornada 12'), findsOneWidget);
    expect(find.text('EN DIRECTO'), findsOneWidget);
    expect(find.text('72'), findsWidgets);
    expect(find.text('Canasta de 2 puntos'), findsOneWidget);
    expect(find.text('#7 Carlos Martínez'), findsOneWidget);
    expect(find.text('Cargar acciones anteriores'), findsOneWidget);
  });

  testWidgets('shows a spinner while the initial load is in flight',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          liveMatchControllerProvider.overrideWith(
            () => _FakeController(const LiveMatchState()),
          ),
        ],
        child: const MaterialApp(
          home: MatchLivePage(matchId: 'm1'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
