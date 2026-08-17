import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sync_providers.dart';
import '../../data/datasources/club_remote_datasource.dart';
import '../../data/repositories/club_repository_impl.dart';
import '../../domain/repositories/club_repository.dart';
import '../../domain/usecases/create_club_usecase.dart';
import '../../domain/usecases/delete_club_usecase.dart';
import '../../domain/usecases/get_club_usecase.dart';
import '../../domain/usecases/get_clubs_usecase.dart';
import '../../domain/usecases/update_club_usecase.dart';

/// REST datasource for clubs.
final clubRemoteDataSourceProvider = Provider<ClubRemoteDataSource>((ref) {
  return ClubRemoteDataSource(ref.watch(dioClientProvider).dio);
});

/// Club CRUD repository.
final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepositoryImpl(remote: ref.watch(clubRemoteDataSourceProvider));
});

/// Use case: list clubs (paginated).
final getClubsUseCaseProvider = Provider<GetClubsUseCase>((ref) {
  return GetClubsUseCase(ref.watch(clubRepositoryProvider));
});

/// Use case: read a single club.
final getClubUseCaseProvider = Provider<GetClubUseCase>((ref) {
  return GetClubUseCase(ref.watch(clubRepositoryProvider));
});

/// Use case: create a club.
final createClubUseCaseProvider = Provider<CreateClubUseCase>((ref) {
  return CreateClubUseCase(ref.watch(clubRepositoryProvider));
});

/// Use case: update a club.
final updateClubUseCaseProvider = Provider<UpdateClubUseCase>((ref) {
  return UpdateClubUseCase(ref.watch(clubRepositoryProvider));
});

/// Use case: delete a club.
final deleteClubUseCaseProvider = Provider<DeleteClubUseCase>((ref) {
  return DeleteClubUseCase(ref.watch(clubRepositoryProvider));
});
