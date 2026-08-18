import '../../../../core/models/paginated.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/user_repository.dart';

/// Parameters for [GetUsersUseCase].
class GetUsersParams {
  const GetUsersParams({this.page, this.limit, this.search});

  final int? page;
  final int? limit;

  /// Free-text filter applied by the backend (name/email).
  final String? search;
}

/// Fetches a paginated list of registered users (newest first).
class GetUsersUseCase implements UseCase<Paginated<AppUser>, GetUsersParams> {
  const GetUsersUseCase(this.repository);

  final UserRepository repository;

  @override
  Future<Paginated<AppUser>> call(GetUsersParams params) =>
      repository.getUsers(
        page: params.page,
        limit: params.limit,
        search: params.search,
      );
}
