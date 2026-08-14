import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../database/app_database.dart';
import '../database/daos/pending_events_dao.dart';
import 'connectivity_monitor.dart';

/// Result of attempting to upload a single queued event.
enum SyncOutcome {
  /// Server accepted the event (2xx) — mark `synced`.
  synced,

  /// Server rejected the event with a business error (4xx) — mark `failed`.
  businessFailed,

  /// Transient failure (5xx / timeout / no network) — keep `pending` and retry.
  retryLater,
}

/// Uploads a queued event to the backend (Agent_Mobile.md §10.2).
abstract interface class EventUploader {
  Future<SyncOutcome> upload(PendingEvent event);
}

/// [EventUploader] backed by the app's configured [Dio] client.
///
/// Posts to `/matches/{matchId}/events` and classifies the response into a
/// [SyncOutcome] so the [SyncService] stays transport-agnostic.
class DioEventUploader implements EventUploader {
  DioEventUploader(this._dio);

  final Dio _dio;

  @override
  Future<SyncOutcome> upload(PendingEvent event) async {
    try {
      final response = await _dio.post<dynamic>(
        '/matches/${event.matchId}/events',
        data: jsonDecode(event.eventPayload),
        options: Options(validateStatus: (_) => true),
      );
      return classifyStatus(response.statusCode);
    } on DioException catch (e) {
      // No response means a connection/timeout error → retry when back online.
      final status = e.response?.statusCode;
      return status == null ? SyncOutcome.retryLater : classifyStatus(status);
    }
  }
}

/// Maps an HTTP status code to a [SyncOutcome].
///
/// 2xx → synced, other 4xx → business failure, everything else (incl. 5xx and a
/// missing status) → transient retry.
SyncOutcome classifyStatus(int? statusCode) {
  if (statusCode == null) {
    return SyncOutcome.retryLater;
  }
  if (statusCode >= 200 && statusCode < 300) {
    return SyncOutcome.synced;
  }
  if (statusCode >= 400 && statusCode < 500) {
    return SyncOutcome.businessFailed;
  }
  return SyncOutcome.retryLater;
}

/// Drains the offline event queue whenever connectivity is available
/// (Agent_Mobile.md §10.2).
///
/// Events are processed strictly FIFO (by `createdAt`). Per event: mark
/// `syncing` → upload → mark `synced` (2xx) / `failed` (4xx) / return to
/// `pending` and stop the run (transient) so the remaining events keep their
/// chronological order until the next connectivity change.
class SyncService {
  SyncService({
    required this.dao,
    required this.connectivity,
    required this.uploader,
  });

  final PendingEventsDao dao;
  final ConnectivityMonitor connectivity;
  final EventUploader uploader;

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();
  final StreamController<List<PendingEvent>> _failedController =
      StreamController<List<PendingEvent>>.broadcast();

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  /// Number of events still awaiting sync (drives the pending badge).
  Stream<int> get pendingCount => _pendingCountController.stream;

  /// Events that failed with a business error and need user review.
  Stream<List<PendingEvent>> get failedEvents => _failedController.stream;

  /// Begins listening for connectivity and emits the current queue state.
  ///
  /// Draining is triggered immediately if the device is already online.
  Future<void> start() async {
    _connectivitySubscription ??=
        connectivity.isOnline.listen((bool online) {
      if (online) {
        unawaited(syncPending());
      }
    });
    await _emitState();
    if (await connectivity.checkOnce()) {
      await syncPending();
    }
  }

  /// Processes the pending queue once, in FIFO order.
  ///
  /// Re-entrant calls are ignored while a run is in progress.
  Future<void> syncPending() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    try {
      final pending = await dao.getPendingEvents();
      for (final PendingEvent event in pending) {
        await dao.markSyncing(event.id);
        final SyncOutcome outcome = await uploader.upload(event);
        switch (outcome) {
          case SyncOutcome.synced:
            await dao.markSynced(event.id);
          case SyncOutcome.businessFailed:
            await dao.markFailed(event.id);
          case SyncOutcome.retryLater:
            await dao.markRetryable(event.id);
            await _emitState();
            return;
        }
        await _emitState();
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Releases the connectivity subscription and stream resources.
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    await _pendingCountController.close();
    await _failedController.close();
  }

  Future<void> _emitState() async {
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(await dao.getPendingCount());
    }
    if (!_failedController.isClosed) {
      _failedController.add(await dao.getFailedEvents());
    }
  }
}
