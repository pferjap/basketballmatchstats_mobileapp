/// A club (tenant/organisation) in the domain layer.
///
/// Plain, dependency-free value object; the data-layer model maps into this via
/// its `toEntity()` method. See Plan.md T-023.
class Club {
  const Club({
    required this.id,
    required this.name,
    this.logoUrl,
    this.city,
    this.country,
    this.foundedYear,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Remote URL of the club crest, when one has been uploaded.
  final String? logoUrl;
  final String? city;
  final String? country;

  /// Four-digit founding year, when known.
  final int? foundedYear;
  final DateTime? createdAt;

  Club copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? city,
    String? country,
    int? foundedYear,
    DateTime? createdAt,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      city: city ?? this.city,
      country: country ?? this.country,
      foundedYear: foundedYear ?? this.foundedYear,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Club &&
          other.id == id &&
          other.name == name &&
          other.logoUrl == logoUrl &&
          other.city == city &&
          other.country == country &&
          other.foundedYear == foundedYear &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, name, logoUrl, city, country, foundedYear, createdAt);
}
