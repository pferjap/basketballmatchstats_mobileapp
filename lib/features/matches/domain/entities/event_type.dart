/// The 19 basketball event types tracked during a live match.
///
/// Order and identity mirror the backend contract (Agent_Mobile §6). The
/// API string representation lives in the data layer
/// (`data/models/event_type.dart` — `EventTypeConverter`) so the domain stays
/// free of transport concerns.
enum EventType {
  pointsMade,
  pointsMissed,
  reboundOffensive,
  reboundDefensive,
  assist,
  turnover,
  steal,
  block,
  foulPersonal,
  foulTechnical,
  foulUnsportsmanlike,
  foulDisqualifying,
  freeThrowAwarded,
  substitution,
  timeout,
  quarterStart,
  quarterEnd,
  matchStart,
  matchFinish,
}
