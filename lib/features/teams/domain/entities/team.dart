/// A team belonging to a club, in the domain layer.
///
/// Plain, dependency-free value object; the data-layer model maps into this via
/// its `toEntity()` method. See Plan.md T-024.
class Team {
  const Team({
    required this.id,
    required this.name,
    required this.clubId,
    this.clubName,
    this.category,
    this.logoUrl,
    this.seasonId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String clubId;

  /// Denormalised club name, when the backend embeds it for list rendering.
  final String? clubName;

  /// Age/competition category (e.g. "Senior", "Cadete").
  final String? category;
  final String? logoUrl;
  final String? seasonId;
  final DateTime? createdAt;

  Team copyWith({
    String? id,
    String? name,
    String? clubId,
    String? clubName,
    String? category,
    String? logoUrl,
    String? seasonId,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      seasonId: seasonId ?? this.seasonId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          other.id == id &&
          other.name == name &&
          other.clubId == clubId &&
          other.clubName == clubName &&
          other.category == category &&
          other.logoUrl == logoUrl &&
          other.seasonId == seasonId &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    clubId,
    clubName,
    category,
    logoUrl,
    seasonId,
    createdAt,
  );
}
