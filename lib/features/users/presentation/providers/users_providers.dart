import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sync_providers.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/update_user_club_usecase.dart';
import '../../domain/usecases/update_user_role_usecase.dart';

/// REST datasource for users.
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.watch(dioClientProvider).dio);
});

/// Users-management repository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(remote: ref.watch(userRemoteDataSourceProvider));
});

/// Use case: list users (paginated, newest first).
final getUsersUseCaseProvider = Provider<GetUsersUseCase>((ref) {
  return GetUsersUseCase(ref.watch(userRepositoryProvider));
});

/// Use case: change a user's role.
final updateUserRoleUseCaseProvider = Provider<UpdateUserRoleUseCase>((ref) {
  return UpdateUserRoleUseCase(ref.watch(userRepositoryProvider));
});

/// Use case: assign/unassign a user's club.
final updateUserClubUseCaseProvider = Provider<UpdateUserClubUseCase>((ref) {
  return UpdateUserClubUseCase(ref.watch(userRepositoryProvider));
});
