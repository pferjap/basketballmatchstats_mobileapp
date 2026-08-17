import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sync_providers.dart';
import '../../data/datasources/player_remote_datasource.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/usecases/create_player_usecase.dart';
import '../../domain/usecases/delete_player_usecase.dart';
import '../../domain/usecases/get_player_usecase.dart';
import '../../domain/usecases/get_players_usecase.dart';
import '../../domain/usecases/update_player_usecase.dart';

/// REST datasource for players.
final playerRemoteDataSourceProvider = Provider<PlayerRemoteDataSource>((ref) {
  return PlayerRemoteDataSource(ref.watch(dioClientProvider).dio);
});

/// Player CRUD repository.
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepositoryImpl(
    remote: ref.watch(playerRemoteDataSourceProvider),
  );
});

/// Use case: list players (paginated).
final getPlayersUseCaseProvider = Provider<GetPlayersUseCase>((ref) {
  return GetPlayersUseCase(ref.watch(playerRepositoryProvider));
});

/// Use case: read a single player.
final getPlayerUseCaseProvider = Provider<GetPlayerUseCase>((ref) {
  return GetPlayerUseCase(ref.watch(playerRepositoryProvider));
});

/// Use case: create a player.
final createPlayerUseCaseProvider = Provider<CreatePlayerUseCase>((ref) {
  return CreatePlayerUseCase(ref.watch(playerRepositoryProvider));
});

/// Use case: update a player.
final updatePlayerUseCaseProvider = Provider<UpdatePlayerUseCase>((ref) {
  return UpdatePlayerUseCase(ref.watch(playerRepositoryProvider));
});

/// Use case: delete a player.
final deletePlayerUseCaseProvider = Provider<DeletePlayerUseCase>((ref) {
  return DeletePlayerUseCase(ref.watch(playerRepositoryProvider));
});
