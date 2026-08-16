import '../../domain/entities/event_type.dart';

/// Maps the backend event-type strings (`POINTS_MADE`, …) to the domain
/// [EventType] enum, keeping the domain layer free of serialization concerns
/// (Agent_Mobile §6).
class EventTypeConverter {
  const EventTypeConverter();

  static const Map<String, EventType> _fromApi = <String, EventType>{
    'POINTS_MADE': EventType.pointsMade,
    'POINTS_MISSED': EventType.pointsMissed,
    'REBOUND_OFFENSIVE': EventType.reboundOffensive,
    'REBOUND_DEFENSIVE': EventType.reboundDefensive,
    'ASSIST': EventType.assist,
    'TURNOVER': EventType.turnover,
    'STEAL': EventType.steal,
    'BLOCK': EventType.block,
    'FOUL_PERSONAL': EventType.foulPersonal,
    'FOUL_TECHNICAL': EventType.foulTechnical,
    'FOUL_UNSPORTSMANLIKE': EventType.foulUnsportsmanlike,
    'FOUL_DISQUALIFYING': EventType.foulDisqualifying,
    'FREE_THROW_AWARDED': EventType.freeThrowAwarded,
    'SUBSTITUTION': EventType.substitution,
    'TIMEOUT': EventType.timeout,
    'QUARTER_START': EventType.quarterStart,
    'QUARTER_END': EventType.quarterEnd,
    'MATCH_START': EventType.matchStart,
    'MATCH_FINISH': EventType.matchFinish,
  };

  static const Map<EventType, String> _toApi = <EventType, String>{
    EventType.pointsMade: 'POINTS_MADE',
    EventType.pointsMissed: 'POINTS_MISSED',
    EventType.reboundOffensive: 'REBOUND_OFFENSIVE',
    EventType.reboundDefensive: 'REBOUND_DEFENSIVE',
    EventType.assist: 'ASSIST',
    EventType.turnover: 'TURNOVER',
    EventType.steal: 'STEAL',
    EventType.block: 'BLOCK',
    EventType.foulPersonal: 'FOUL_PERSONAL',
    EventType.foulTechnical: 'FOUL_TECHNICAL',
    EventType.foulUnsportsmanlike: 'FOUL_UNSPORTSMANLIKE',
    EventType.foulDisqualifying: 'FOUL_DISQUALIFYING',
    EventType.freeThrowAwarded: 'FREE_THROW_AWARDED',
    EventType.substitution: 'SUBSTITUTION',
    EventType.timeout: 'TIMEOUT',
    EventType.quarterStart: 'QUARTER_START',
    EventType.quarterEnd: 'QUARTER_END',
    EventType.matchStart: 'MATCH_START',
    EventType.matchFinish: 'MATCH_FINISH',
  };

  EventType fromJson(String json) {
    final type = _fromApi[json];
    if (type == null) {
      throw FormatException('Unknown event type: $json');
    }
    return type;
  }

  String toJson(EventType object) => _toApi[object]!;
}
