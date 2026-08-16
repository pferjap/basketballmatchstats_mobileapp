import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/theme/app_colors.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match_score.dart';
import 'package:hoop_analytics/features/matches/presentation/widgets/score_header_widget.dart';

void main() {
  Future<void> pump(WidgetTester tester, MatchScore? score) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScoreHeaderWidget(
            homeTeamName: 'Tigres',
            homeClubName: 'Tigres Basket',
            awayTeamName: 'Águilas',
            awayClubName: 'Águilas BC',
            score: score,
          ),
        ),
      ),
    );
  }

  testWidgets('renders team names, score and period', (tester) async {
    await pump(
      tester,
      const MatchScore(
        matchId: 'm1',
        homeTeamScore: 72,
        awayTeamScore: 68,
        currentPeriod: 3,
        gameClock: '05:47',
      ),
    );

    expect(find.text('TIGRES'), findsOneWidget);
    expect(find.text('ÁGUILAS'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('68'), findsOneWidget);
    expect(find.text('Tiempo de cuarto'), findsOneWidget);
    expect(find.textContaining('Q3'), findsOneWidget);
  });

  testWidgets('paints the leading team score in green', (tester) async {
    await pump(
      tester,
      const MatchScore(
        matchId: 'm1',
        homeTeamScore: 72,
        awayTeamScore: 68,
        currentPeriod: 3,
        gameClock: '05:47',
      ),
    );

    final homeScore = tester.widget<Text>(find.text('72'));
    expect(homeScore.style?.color, AppColors.success);
    final awayScore = tester.widget<Text>(find.text('68'));
    expect(awayScore.style?.color, AppColors.textPrimary);
  });

  testWidgets('shows placeholders before the first score arrives',
      (tester) async {
    await pump(tester, null);
    expect(find.text('–'), findsNWidgets(2));
    expect(find.textContaining('--:--'), findsOneWidget);
  });
}
