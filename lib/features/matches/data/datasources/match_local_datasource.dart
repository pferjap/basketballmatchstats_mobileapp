import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/pending_events_dao.dart';
import '../../../../core/error/exceptions.dart';

/// Local persistence for the matches feature: the offline event queue
/// (via [PendingEventsDao]) and cached in-progress match state
/// (Agent_Mobile §10.1).
class MatchLocalDataSource {
  MatchLocalDataSource(this._db);

  final AppDatabase _db;

  PendingEventsDao get _pendingEvents => _db.pendingEventsDao;

  /// Queues an event as `pending` before any network call, so it survives
  /// app restarts and is drained FIFO by the sync service.
  Future<void> enqueueEvent({
    required String id,
    required String matchId,
    required String eventPayload,
    DateTime? createdAt,
  }) async {
    try {
      await _pendingEvents.insertEvent(
        id: id,
        matchId: matchId,
        eventPayload: eventPayload,
        createdAt: createdAt,
      );
    } catch (error) {
      throw CacheException('Failed to queue event: $error');
    }
  }

  /// Marks a queued event as successfully synced.
  Future<void> markEventSynced(String id) => _pendingEvents.markSynced(id);

  /// Marks a queued event as failed after a business rejection (4xx).
  Future<void> markEventFailed(String id) => _pendingEvents.markFailed(id);

  /// Returns a queued event to `pending` after a transient failure.
  Future<void> markEventRetryable(String id) =>
      _pendingEvents.markRetryable(id);

  /// Upserts the serialized state of an in-progress match.
  Future<void> cacheMatch({
    required String matchId,
    required String data,
    DateTime? updatedAt,
  }) async {
    try {
      await _db
          .into(_db.matchCache)
          .insertOnConflictUpdate(
            MatchCacheCompanion.insert(
              matchId: matchId,
              data: data,
              updatedAt: updatedAt ?? DateTime.now(),
            ),
          );
    } catch (error) {
      throw CacheException('Failed to cache match: $error');
    }
  }

  /// Returns the cached serialized state for [matchId], or `null` if absent.
  Future<String?> getCachedMatch(String matchId) async {
    try {
      final row = await (_db.select(
        _db.matchCache,
      )..where((MatchCache t) => t.matchId.equals(matchId))).getSingleOrNull();
      return row?.data;
    } catch (error) {
      throw CacheException('Failed to read cached match: $error');
    }
  }
}
