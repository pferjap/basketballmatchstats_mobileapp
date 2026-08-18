import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sync_providers.dart';
import '../../../../core/network/ws_manager.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../data/datasources/match_local_datasource.dart';
import '../../data/datasources/match_remote_datasource.dart';
import '../../data/datasources/match_ws_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../data/repositories/match_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/match_repository.dart';
import '../../domain/usecases/get_live_score_usecase.dart';
import '../../domain/usecases/get_match_events_usecase.dart';
import '../../domain/usecases/record_event_usecase.dart';
import '../../domain/usecases/start_match_usecase.dart';

/// Shared realtime WebSocket manager for match read channels.
final wsManagerProvider = Provider<WsManager>((ref) {
  final manager = WsManager(tokenStorage: ref.watch(tokenStorageProvider));
  ref.onDispose(manager.dispose);
  return manager;
});

/// REST datasource for matches/events.
final matchRemoteDataSourceProvider = Provider<MatchRemoteDataSource>((ref) {
  return MatchRemoteDataSource(ref.watch(dioClientProvider).dio);
});

/// WebSocket read-channel datasource for live matches.
final matchWsDataSourceProvider = Provider<MatchWsDataSource>((ref) {
  return MatchWsDataSource(ref.watch(wsManagerProvider));
});

/// Local persistence (offline queue + match cache).
final matchLocalDataSourceProvider = Provider<MatchLocalDataSource>((ref) {
  return MatchLocalDataSource(ref.watch(appDatabaseProvider));
});

/// Match read/lifecycle repository.
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl(
    remote: ref.watch(matchRemoteDataSourceProvider),
    ws: ref.watch(matchWsDataSourceProvider),
    local: ref.watch(matchLocalDataSourceProvider),
  );
});

/// Event write repository (offline-first recording).
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(
    remote: ref.watch(matchRemoteDataSourceProvider),
    local: ref.watch(matchLocalDataSourceProvider),
  );
});

/// Use case: start a scheduled match.
final startMatchUseCaseProvider = Provider<StartMatchUseCase>((ref) {
  return StartMatchUseCase(ref.watch(matchRepositoryProvider));
});

/// Use case: record a new event.
final recordEventUseCaseProvider = Provider<RecordEventUseCase>((ref) {
  return RecordEventUseCase(ref.watch(eventRepositoryProvider));
});

/// Use case: read the live score.
final getLiveScoreUseCaseProvider = Provider<GetLiveScoreUseCase>((ref) {
  return GetLiveScoreUseCase(ref.watch(matchRepositoryProvider));
});

/// Use case: read a match's events (paginated).
final getMatchEventsUseCaseProvider = Provider<GetMatchEventsUseCase>((ref) {
  return GetMatchEventsUseCase(ref.watch(matchRepositoryProvider));
});

/// Resolves a team name by its ID, caching the result for the session.
final teamNameProvider = FutureProvider.family<String, String>((ref, teamId) async {
  try {
    final team = await ref.watch(teamRepositoryProvider).getTeam(teamId);
    return team.name;
  } catch (_) {
    return teamId;
  }
});
