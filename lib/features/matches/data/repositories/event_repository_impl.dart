import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/sync_service.dart';
import '../../domain/entities/match_event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/match_local_datasource.dart';
import '../datasources/match_remote_datasource.dart';
import '../models/coordinates_model.dart';
import '../models/event_type.dart';

/// Offline-first implementation of [EventRepository] (Agent_Mobile §10).
///
/// Every event is persisted to the local queue *before* the network call, so a
/// dropped connection never loses data. The queued copy is then reconciled with
/// the server response.
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({
    required this.remote,
    required this.local,
    String Function()? idGenerator,
    DateTime Function()? clock,
  }) : _idGenerator = idGenerator ?? (() => const Uuid().v4()),
       _clock = clock ?? DateTime.now;

  final MatchRemoteDataSource remote;
  final MatchLocalDataSource local;
  final String Function() _idGenerator;
  final DateTime Function() _clock;

  @override
  Future<MatchEvent> recordEvent(String matchId, EventParams params) async {
    final id = _idGenerator();
    final createdAt = _clock();
    final payload = _payload(matchId, params, id: id, createdAt: createdAt);

    final optimisticEvent = MatchEvent(
      id: id,
      matchId: matchId,
      teamId: params.teamId,
      playerId: params.playerId,
      eventType: params.eventType,
      period: params.period,
      gameClock: params.gameClock,
      coordinates: params.coordinates,
      metadata: params.metadata,
      createdAt: createdAt,
    );

    // Persist first so the event survives connectivity loss / app restart.
    // If the local DB fails, proceed with the remote call anyway.
    try {
      await local.enqueueEvent(
        id: id,
        matchId: matchId,
        eventPayload: jsonEncode(payload),
        createdAt: createdAt,
      );
    } catch (_) {
      // Local queue failure is non-fatal; the remote call below is the
      // source of truth.
    }

    try {
      final serverEvent = await remote.recordEvent(matchId, payload);
      try {
        await local.markEventSynced(id);
      } catch (_) {
        // Best-effort local bookkeeping.
      }
      return serverEvent.toEntity();
    } on ServerException catch (error) {
      if (classifyStatus(error.statusCode) == SyncOutcome.businessFailed) {
        // 4xx business rejection: mark failed and let the UI roll back.
        try {
          await local.markEventFailed(id);
        } catch (_) {
          // Best-effort.
        }
        rethrow;
      }
      // 5xx / timeout: keep queued for the sync service to retry.
      try {
        await local.markEventRetryable(id);
      } catch (_) {
        // Best-effort.
      }
      return optimisticEvent;
    } on NetworkException {
      // Offline: keep queued; the event is safely stored.
      try {
        await local.markEventRetryable(id);
      } catch (_) {
        // Best-effort.
      }
      return optimisticEvent;
    }
  }

  @override
  Future<void> undoLastEvent(String matchId) => remote.undoLastEvent(matchId);

  Map<String, dynamic> _payload(
    String matchId,
    EventParams params, {
    required String id,
    required DateTime createdAt,
  }) {
    final coordinates = params.coordinates;
    return <String, dynamic>{
      'teamId': params.teamId,
      if (params.playerId != null) 'playerId': params.playerId,
      'eventType': const EventTypeConverter().toJson(params.eventType),
      'period': params.period,
      'gameClock': params.gameClock,
      if (coordinates != null)
        'coordinates': CoordinatesModel.fromEntity(coordinates).toJson(),
      if (params.metadata != null) 'metadata': params.metadata,
    };
  }
}
