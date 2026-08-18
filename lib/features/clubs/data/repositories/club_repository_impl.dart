import '../../../../core/models/paginated.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';
import '../datasources/club_remote_datasource.dart';
import '../models/club_model.dart';

/// REST-backed implementation of [ClubRepository] (Plan.md T-023).
class ClubRepositoryImpl implements ClubRepository {
  const ClubRepositoryImpl({required this.remote});

  final ClubRemoteDataSource remote;

  @override
  Future<Paginated<Club>> getClubs({
    int? page,
    int? limit,
    String? search,
  }) async {
    final result = await remote.getClubs(
      page: page,
      limit: limit,
      search: search,
    );
    return Paginated<Club>(
      items: result.items
          .map((ClubModel c) => c.toEntity())
          .toList(growable: false),
      page: result.meta?.page,
      limit: result.meta?.limit,
      total: result.meta?.total,
    );
  }

  @override
  Future<Club> getClub(String clubId) async {
    final model = await remote.getClub(clubId);
    return model.toEntity();
  }

  @override
  Future<Club> createClub(CreateClubParams params) async {
    final model = await remote.createClub(<String, dynamic>{
      'name': params.name,
      'city': ?params.city,
      'country': ?params.country,
      'foundedYear': ?params.foundedYear,
      'logoUrl': ?params.logoUrl,
    });
    return model.toEntity();
  }

  @override
  Future<Club> updateClub(String clubId, UpdateClubParams params) async {
    // Only non-null fields travel, so an omitted field leaves the stored value
    // untouched rather than being cleared.
    final model = await remote.updateClub(clubId, <String, dynamic>{
      'name': ?params.name,
      'city': ?params.city,
      'country': ?params.country,
      'foundedYear': ?params.foundedYear,
      'logoUrl': ?params.logoUrl,
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteClub(String clubId) => remote.deleteClub(clubId);

  @override
  Future<Club> uploadClubLogo(
    String clubId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final model = await remote.uploadLogo(
      clubId,
      bytes: bytes,
      filename: filename,
    );
    return model.toEntity();
  }
}
