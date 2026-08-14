import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/database/app_database.dart';
import 'package:hoop_analytics/core/database/daos/pending_events_dao.dart';

void main() {
  late AppDatabase db;
  late PendingEventsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.pendingEventsDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed(String id, {DateTime? createdAt}) {
    return dao.insertEvent(
      id: id,
      matchId: 'match-1',
      eventPayload: '{"type":"FG2_MADE","player":"$id"}',
      createdAt: createdAt,
    );
  }

  test('inserted events start as pending and are counted', () async {
    await seed('e1');
    await seed('e2');

    expect(await dao.getPendingCount(), 2);
    final pending = await dao.getPendingEvents();
    expect(pending.map((PendingEvent e) => e.status), everyElement('pending'));
    expect(pending.every((PendingEvent e) => e.retryCount == 0), isTrue);
  });

  test('getPendingEvents returns FIFO order by createdAt', () async {
    final base = DateTime(2026, 1, 1, 12);
    await seed('newer', createdAt: base.add(const Duration(seconds: 5)));
    await seed('older', createdAt: base);

    final pending = await dao.getPendingEvents();
    expect(pending.map((PendingEvent e) => e.id), <String>['older', 'newer']);
  });

  test('markSyncing moves an event out of the pending set', () async {
    await seed('e1');
    await dao.markSyncing('e1');

    expect(await dao.getPendingCount(), 0);
    expect(await dao.getPendingEvents(), isEmpty);
  });

  test('markSynced sets status and syncedAt', () async {
    await seed('e1');
    final at = DateTime(2026, 2, 2, 9, 30);
    await dao.markSynced('e1', syncedAt: at);

    final row = await (db.select(db.pendingEvents)
          ..where((PendingEvents t) => t.id.equals('e1')))
        .getSingle();
    expect(row.status, PendingEventStatus.synced.name);
    expect(row.syncedAt, at);
    expect(await dao.getPendingCount(), 0);
  });

  test('markFailed increments retryCount and lists failed events', () async {
    await seed('e1');
    await dao.markFailed('e1');
    await dao.markFailed('e1');

    final failed = await dao.getFailedEvents();
    expect(failed, hasLength(1));
    expect(failed.single.id, 'e1');
    expect(failed.single.retryCount, 2);
    expect(await dao.getPendingCount(), 0);
  });
}
