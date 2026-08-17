import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sync_providers.dart';
import '../../data/datasources/team_remote_datasource.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../domain/repositories/team_repository.dart';
import '../../domain/usecases/create_team_usecase.dart';
import '../../domain/usecases/delete_team_usecase.dart';
import '../../domain/usecases/get_team_usecase.dart';
import '../../domain/usecases/get_teams_usecase.dart';
import '../../domain/usecases/update_team_usecase.dart';

/// REST datasource for teams.
final teamRemoteDataSourceProvider = Provider<TeamRemoteDataSource>((ref) {
  return TeamRemoteDataSource(ref.watch(dioClientProvider).dio);
});

/// Team CRUD repository.
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepositoryImpl(remote: ref.watch(teamRemoteDataSourceProvider));
});

/// Use case: list teams (paginated).
final getTeamsUseCaseProvider = Provider<GetTeamsUseCase>((ref) {
  return GetTeamsUseCase(ref.watch(teamRepositoryProvider));
});

/// Use case: read a single team.
final getTeamUseCaseProvider = Provider<GetTeamUseCase>((ref) {
  return GetTeamUseCase(ref.watch(teamRepositoryProvider));
});

/// Use case: create a team.
final createTeamUseCaseProvider = Provider<CreateTeamUseCase>((ref) {
  return CreateTeamUseCase(ref.watch(teamRepositoryProvider));
});

/// Use case: update a team.
final updateTeamUseCaseProvider = Provider<UpdateTeamUseCase>((ref) {
  return UpdateTeamUseCase(ref.watch(teamRepositoryProvider));
});

/// Use case: delete a team.
final deleteTeamUseCaseProvider = Provider<DeleteTeamUseCase>((ref) {
  return DeleteTeamUseCase(ref.watch(teamRepositoryProvider));
});
