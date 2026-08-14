import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/native_open.dart';
import 'connectivity_monitor.dart';
import 'dio_client.dart';
import 'sync_service.dart';
import 'token_storage.dart';

/// JWT secure storage.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

/// Configured Dio client (auth + retry interceptors).
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(tokenStorage: ref.watch(tokenStorageProvider));
});

/// Local Drift database backing the offline queue.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openHoopDatabase());
  ref.onDispose(db.close);
  return db;
});

/// Network reachability monitor.
final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  return ConnectivityMonitor();
});

/// Uploads queued events through the shared Dio client.
final eventUploaderProvider = Provider<EventUploader>((ref) {
  return DioEventUploader(ref.watch(dioClientProvider).dio);
});

/// Offline sync service, started with the app so the queue drains whenever
/// connectivity returns.
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    dao: ref.watch(appDatabaseProvider).pendingEventsDao,
    connectivity: ref.watch(connectivityMonitorProvider),
    uploader: ref.watch(eventUploaderProvider),
  );
  unawaited(service.start());
  ref.onDispose(service.dispose);
  return service;
});

/// Pending-event count for the sync badge.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncServiceProvider).pendingCount;
});

/// Events that failed with a business error and need user review.
final failedSyncEventsProvider = StreamProvider<List<PendingEvent>>((ref) {
  return ref.watch(syncServiceProvider).failedEvents;
});
