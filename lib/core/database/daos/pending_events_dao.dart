import 'package:drift/drift.dart';

import '../app_database.dart';

part 'pending_events_dao.g.dart';

/// Sync lifecycle status of a queued event (Agent_Mobile.md §10.1).
enum PendingEventStatus { pending, syncing, synced, failed }

/// Data-access object for the offline event queue (Agent_Mobile.md §10.2).
@DriftAccessor(tables: <Type>[PendingEvents])
class PendingEventsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingEventsDaoMixin {
  PendingEventsDao(super.db);

  /// Queues a new event as `pending`.
  Future<void> insertEvent({
    required String id,
    required String matchId,
    required String eventPayload,
    DateTime? createdAt,
  }) {
    return into(pendingEvents).insert(
      PendingEventsCompanion.insert(
        id: id,
        matchId: matchId,
        eventPayload: eventPayload,
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
  }

  /// Marks an event as `syncing` while a network call is in flight.
  Future<void> markSyncing(String id) => _setStatus(id, PendingEventStatus.syncing);

  /// Marks an event as `synced` and stores the confirmation timestamp.
  Future<void> markSynced(String id, {DateTime? syncedAt}) {
    return (update(pendingEvents)..where((PendingEvents t) => t.id.equals(id)))
        .write(
      PendingEventsCompanion(
        status: Value<String>(PendingEventStatus.synced.name),
        syncedAt: Value<DateTime>(syncedAt ?? DateTime.now()),
      ),
    );
  }

  /// Marks an event as `failed` and atomically increments its retry count.
  Future<void> markFailed(String id) async {
    await customUpdate(
      'UPDATE pending_events SET status = ?, retry_count = retry_count + 1 '
      'WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(PendingEventStatus.failed.name),
        Variable<String>(id),
      ],
      updates: <TableInfo<Table, Object>>{pendingEvents},
      updateKind: UpdateKind.update,
    );
  }

  /// Returns pending events in FIFO order (oldest first).
  Future<List<PendingEvent>> getPendingEvents() {
    return (select(pendingEvents)
          ..where((PendingEvents t) =>
              t.status.equals(PendingEventStatus.pending.name))
          ..orderBy(<OrderClauseGenerator<PendingEvents>>[
            (PendingEvents t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  /// Returns failed events in FIFO order for review/correction.
  Future<List<PendingEvent>> getFailedEvents() {
    return (select(pendingEvents)
          ..where((PendingEvents t) =>
              t.status.equals(PendingEventStatus.failed.name))
          ..orderBy(<OrderClauseGenerator<PendingEvents>>[
            (PendingEvents t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  /// Counts events still awaiting sync.
  Future<int> getPendingCount() async {
    final Expression<int> count = pendingEvents.id.count();
    final query = selectOnly(pendingEvents)
      ..addColumns(<Expression<Object>>[count])
      ..where(pendingEvents.status.equals(PendingEventStatus.pending.name));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> _setStatus(String id, PendingEventStatus status) {
    return (update(pendingEvents)..where((PendingEvents t) => t.id.equals(id)))
        .write(PendingEventsCompanion(status: Value<String>(status.name)));
  }
}
