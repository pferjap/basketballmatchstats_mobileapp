import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/data/models/match_model.dart';
import 'package:hoop_analytics/features/matches/data/models/match_statistics_model.dart';
import 'package:hoop_analytics/features/matches/domain/entities/match.dart';

void main() {
  group('MatchStatusConverter', () {
    const converter = MatchStatusConverter();

    test('maps every status round-trip', () {
      for (final status in MatchStatus.values) {
        expect(converter.fromJson(converter.toJson(status)), status);
      }
    });

    test('throws on an unknown status', () {
      expect(() => converter.fromJson('PAUSED'), throwsFormatException);
    });
  });

  group('MatchModel', () {
    test('fromJson parses required and optional fields', () {
      final model = MatchModel.fromJson(<String, dynamic>{
        'id': 'm1',
        'homeTeamId': 'home',
        'awayTeamId': 'away',
        'status': 'IN_PROGRESS',
        'scheduledAt': '2024-02-01T18:00:00.000Z',
        'competitionId': 'comp1',
        'startedAt': '2024-02-01T18:05:00.000Z',
      });

      expect(model.id, 'm1');
      expect(model.status, MatchStatus.inProgress);
      expect(model.competitionId, 'comp1');
      expect(model.seasonId, isNull);
      expect(model.startedAt, isNotNull);
      expect(model.finishedAt, isNull);
    });

    test('toEntity maps to the domain match', () {
      final entity = MatchModel.fromJson(<String, dynamic>{
        'id': 'm2',
        'homeTeamId': 'home',
        'awayTeamId': 'away',
        'status': 'SCHEDULED',
        'scheduledAt': '2024-02-01T18:00:00.000Z',
      }).toEntity();

      expect(entity, isA<Match>());
      expect(entity.status, MatchStatus.scheduled);
      expect(entity.startedAt, isNull);
    });
  });

  group('MatchStatisticsModel', () {
    test('parses nested matchScore + playerStats', () {
      final model = MatchStatisticsModel.fromJson(<String, dynamic>{
        'matchScore': <String, dynamic>{
          'matchId': 'm1',
          'homeTeamScore': 42,
          'awayTeamScore': 39,
          'currentPeriod': 3,
          'gameClock': '05:11',
        },
        'playerStats': <dynamic>[
          <String, dynamic>{
            'playerId': 'p1',
            'points': 12,
            'rebounds': 5,
            'assists': 3,
            'steals': 1,
            'blocks': 0,
            'turnovers': 2,
            'fouls': 1,
            'minutes': 18,
          },
        ],
      });

      final entity = model.toEntity();
      expect(entity.score.homeTeamScore, 42);
      expect(entity.score.awayTeamScore, 39);
      expect(entity.playerStats, hasLength(1));
      expect(entity.playerStats.first.points, 12);
    });
  });
}
