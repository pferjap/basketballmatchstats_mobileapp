import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/database/app_database.dart';
import 'package:hoop_analytics/core/database/daos/pending_events_dao.dart';
import 'package:hoop_analytics/core/network/connectivity_monitor.dart';
import 'package:hoop_analytics/core/network/sync_service.dart';

/// Uploader whose outcome per event id is scripted by the test.
class _ScriptedUploader implements EventUploader {
  _ScriptedUploader(this.outcomes);

  final Map<String, SyncOutcome> outcomes;
  final List<String> uploaded = <String>[];

  @override
  Future<SyncOutcome> upload(PendingEvent event) async {
    uploaded.add(event.id);
    return outcomes[event.id] ?? SyncOutcome.synced;
  }
}

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

  Future<void> seed(String id, {required DateTime createdAt}) {
    return dao.insertEvent(
      id: id,
      matchId: 'match-1',
      eventPayload: '{"id":"$id"}',
      createdAt: createdAt,
    );
  }

  SyncService buildService(_ScriptedUploader uploader) {
    return SyncService(
      dao: dao,
      connectivity: ConnectivityMonitor(),
      uploader: uploader,
    );
  }

  group('classifyStatus', () {
    test('classifies status ranges', () {
      expect(classifyStatus(200), SyncOutcome.synced);
      expect(classifyStatus(201), SyncOutcome.synced);
      expect(classifyStatus(404), SyncOutcome.businessFailed);
      expect(classifyStatus(422), SyncOutcome.businessFailed);
      expect(classifyStatus(500), SyncOutcome.retryLater);
      expect(classifyStatus(503), SyncOutcome.retryLater);
      expect(classifyStatus(null), SyncOutcome.retryLater);
    });
  });

  test('uploads pending events FIFO and marks them synced', () async {
    final base = DateTime(2026, 1, 1, 12);
    await seed('older', createdAt: base);
    await seed('newer', createdAt: base.add(const Duration(seconds: 5)));

    final uploader = _ScriptedUploader(<String, SyncOutcome>{});
    final service = buildService(uploader);
    addTearDown(service.dispose);

    await service.syncPending();

    expect(uploader.uploaded, <String>['older', 'newer']);
    expect(await dao.getPendingCount(), 0);
  });

  test('marks 4xx responses as failed and continues the queue', () async {
    final base = DateTime(2026, 1, 1, 12);
    await seed('bad', createdAt: base);
    await seed('good', createdAt: base.add(const Duration(seconds: 1)));

    final uploader = _ScriptedUploader(<String, SyncOutcome>{
      'bad': SyncOutcome.businessFailed,
    });
    final service = buildService(uploader);
    addTearDown(service.dispose);

    await service.syncPending();

    final failed = await dao.getFailedEvents();
    expect(failed.map((PendingEvent e) => e.id), <String>['bad']);
    expect(failed.single.retryCount, 1);
    expect(await dao.getPendingCount(), 0);
    expect(uploader.uploaded, <String>['bad', 'good']);
  });

  test('keeps events pending and stops on a transient failure', () async {
    final base = DateTime(2026, 1, 1, 12);
    await seed('first', createdAt: base);
    await seed('second', createdAt: base.add(const Duration(seconds: 1)));

    final uploader = _ScriptedUploader(<String, SyncOutcome>{
      'first': SyncOutcome.retryLater,
    });
    final service = buildService(uploader);
    addTearDown(service.dispose);

    await service.syncPending();

    // The run stops after the transient failure so order is preserved.
    expect(uploader.uploaded, <String>['first']);
    expect(await dao.getPendingCount(), 2);

    final pending = await dao.getPendingEvents();
    final PendingEvent first =
        pending.firstWhere((PendingEvent e) => e.id == 'first');
    expect(first.status, PendingEventStatus.pending.name);
    expect(first.retryCount, 1);
  });

  test('pendingCount stream emits the queue size as it drains', () async {
    final base = DateTime(2026, 1, 1, 12);
    await seed('e1', createdAt: base);
    await seed('e2', createdAt: base.add(const Duration(seconds: 1)));

    final uploader = _ScriptedUploader(<String, SyncOutcome>{});
    final service = buildService(uploader);
    addTearDown(service.dispose);

    final List<int> counts = <int>[];
    final sub = service.pendingCount.listen(counts.add);

    await service.syncPending();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(counts.last, 0);
    expect(counts, contains(1));
  });

  test('concurrent syncPending calls do not double-process', () async {
    final base = DateTime(2026, 1, 1, 12);
    await seed('e1', createdAt: base);

    final uploader = _ScriptedUploader(<String, SyncOutcome>{});
    final service = buildService(uploader);
    addTearDown(service.dispose);

    await Future.wait<void>(<Future<void>>[
      service.syncPending(),
      service.syncPending(),
    ]);

    expect(uploader.uploaded, <String>['e1']);
  });
}
