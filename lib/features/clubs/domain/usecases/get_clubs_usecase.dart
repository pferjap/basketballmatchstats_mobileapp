import '../../../../core/models/paginated.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/club.dart';
import '../repositories/club_repository.dart';

/// Parameters for [GetClubsUseCase].
class GetClubsParams {
  const GetClubsParams({this.page, this.limit, this.search});

  final int? page;
  final int? limit;

  /// Free-text name filter applied by the backend.
  final String? search;
}

/// Fetches a paginated list of clubs.
class GetClubsUseCase implements UseCase<Paginated<Club>, GetClubsParams> {
  const GetClubsUseCase(this.repository);

  final ClubRepository repository;

  @override
  Future<Paginated<Club>> call(GetClubsParams params) => repository.getClubs(
    page: params.page,
    limit: params.limit,
    search: params.search,
  );
}
