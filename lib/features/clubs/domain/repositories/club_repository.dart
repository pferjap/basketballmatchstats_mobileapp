import '../../../../core/models/paginated.dart';
import '../entities/club.dart';

/// Input for creating a club. Only [name] is required by the backend.
class CreateClubParams {
  const CreateClubParams({
    required this.name,
    this.city,
    this.country,
    this.foundedYear,
    this.logoUrl,
  });

  final String name;
  final String? city;
  final String? country;
  final int? foundedYear;
  final String? logoUrl;
}

/// Input for updating a club.
///
/// Every field is optional: only the ones that are non-null are sent, so an
/// omitted field leaves the stored value untouched.
class UpdateClubParams {
  const UpdateClubParams({
    this.name,
    this.city,
    this.country,
    this.foundedYear,
    this.logoUrl,
  });

  final String? name;
  final String? city;
  final String? country;
  final int? foundedYear;
  final String? logoUrl;
}

/// CRUD operations for clubs (Plan.md T-023).
///
/// Implementations talk to the REST API through the data layer; errors surface
/// as `AppException` subtypes.
abstract interface class ClubRepository {
  /// Lists the clubs visible to the current tenant, paginated.
  ///
  /// [search] filters by name server-side when provided.
  Future<Paginated<Club>> getClubs({int? page, int? limit, String? search});

  /// Fetches a single club by id.
  Future<Club> getClub(String clubId);

  /// Creates a club and returns the persisted entity.
  Future<Club> createClub(CreateClubParams params);

  /// Updates a club and returns the persisted entity.
  Future<Club> updateClub(String clubId, UpdateClubParams params);

  /// Permanently removes a club.
  Future<void> deleteClub(String clubId);

  /// Uploads a new logo for [clubId] and returns the updated club.
  Future<Club> uploadClubLogo(
    String clubId, {
    required List<int> bytes,
    required String filename,
  });
}
