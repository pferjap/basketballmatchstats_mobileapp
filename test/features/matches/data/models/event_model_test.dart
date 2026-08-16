import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/matches/data/models/event_model.dart';
import 'package:hoop_analytics/features/matches/data/models/event_type.dart';
import 'package:hoop_analytics/features/matches/domain/entities/event_type.dart';

void main() {
  group('EventTypeConverter', () {
    const converter = EventTypeConverter();

    test('maps every enum value round-trip', () {
      for (final type in EventType.values) {
        final api = converter.toJson(type);
        expect(converter.fromJson(api), type);
      }
    });

    test('maps known API strings', () {
      expect(converter.fromJson('POINTS_MADE'), EventType.pointsMade);
      expect(converter.fromJson('MATCH_FINISH'), EventType.matchFinish);
      expect(converter.toJson(EventType.reboundOffensive),
          'REBOUND_OFFENSIVE');
    });

    test('throws on an unknown API string', () {
      expect(() => converter.fromJson('NOPE'), throwsFormatException);
    });
  });

  group('EventModel', () {
    final json = <String, dynamic>{
      'id': 'e1',
      'matchId': 'm1',
      'teamId': 't1',
      'playerId': 'p1',
      'eventType': 'POINTS_MADE',
      'period': 2,
      'gameClock': '07:32',
      'coordinates': <String, dynamic>{'x': 12.5, 'y': 88.0},
      'metadata': <String, dynamic>{'points': 3},
      'createdAt': '2024-01-15T20:30:00.000Z',
    };

    test('fromJson parses all fields', () {
      final model = EventModel.fromJson(json);
      expect(model.id, 'e1');
      expect(model.matchId, 'm1');
      expect(model.teamId, 't1');
      expect(model.playerId, 'p1');
      expect(model.eventType, EventType.pointsMade);
      expect(model.period, 2);
      expect(model.gameClock, '07:32');
      expect(model.coordinates?.x, 12.5);
      expect(model.coordinates?.y, 88.0);
      expect(model.metadata?['points'], 3);
      expect(model.createdAt.toUtc().hour, 20);
    });

    test('toJson round-trips', () {
      final model = EventModel.fromJson(json);
      final out = model.toJson();
      expect(out['eventType'], 'POINTS_MADE');
      expect(out['coordinates'], <String, dynamic>{'x': 12.5, 'y': 88.0});
      expect(out['metadata'], <String, dynamic>{'points': 3});
      expect(out['createdAt'], '2024-01-15T20:30:00.000Z');
    });

    test('toEntity maps to the domain event', () {
      final entity = EventModel.fromJson(json).toEntity();
      expect(entity.eventType, EventType.pointsMade);
      expect(entity.coordinates?.x, 12.5);
      expect(entity.playerId, 'p1');
    });

    test('handles null playerId, coordinates and metadata', () {
      final model = EventModel.fromJson(<String, dynamic>{
        'id': 'e2',
        'matchId': 'm1',
        'teamId': 't1',
        'eventType': 'TIMEOUT',
        'period': 1,
        'gameClock': '10:00',
        'createdAt': '2024-01-15T20:00:00.000Z',
      });
      expect(model.playerId, isNull);
      expect(model.coordinates, isNull);
      expect(model.metadata, isNull);
      expect(model.toJson()['coordinates'], isNull);
    });
  });
}
