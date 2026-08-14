import 'package:drift/drift.dart';

import 'daos/pending_events_dao.dart';

part 'app_database.g.dart';

/// Offline event queue (Agent_Mobile.md §10.1).
///
/// Every scored event is persisted here as `pending` before any network call,
/// so the queue always survives app restarts and is drained FIFO by the
/// [PendingEventsDao].
class PendingEvents extends Table {
  /// Locally generated UUID.
  TextColumn get id => text()();

  /// UUID of the owning match.
  TextColumn get matchId => text()();

  /// Full JSON payload of the event.
  TextColumn get eventPayload => text()();

  /// Sync lifecycle: pending | syncing | synced | failed.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// Number of sync attempts made so far.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Local creation timestamp (drives FIFO ordering).
  DateTimeColumn get createdAt => dateTime()();

  /// Server confirmation timestamp, set when marked `synced`.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Cache of in-progress match state for restoration (Agent_Mobile.md §10.1, §13).
class MatchCache extends Table {
  /// UUID of the cached match.
  TextColumn get matchId => text()();

  /// Serialized match state (JSON).
  TextColumn get data => text()();

  /// Timestamp of the last cache write.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{matchId};
}

/// Local SQLite database backed by Drift.
///
/// The database is constructed from an injected [QueryExecutor] so it stays free
/// of Flutter/platform imports (see `native_open.dart` for the production
/// connection and tests for an in-memory one).
@DriftDatabase(
  tables: <Type>[PendingEvents, MatchCache],
  daos: <Type>[PendingEventsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
