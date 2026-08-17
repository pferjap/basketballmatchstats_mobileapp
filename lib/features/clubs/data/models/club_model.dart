import '../../domain/entities/club.dart';

/// Data-layer DTO for a club, aligned with the backend JSON.
///
/// Hand-written (no Freezed) to stay compatible with the installed Dart SDK,
/// matching the convention used by the matches feature.
class ClubModel {
  const ClubModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.city,
    this.country,
    this.foundedYear,
    this.createdAt,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String?;
    return ClubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      foundedYear: (json['foundedYear'] as num?)?.toInt(),
      createdAt: createdAt == null ? null : DateTime.parse(createdAt),
    );
  }

  final String id;
  final String name;
  final String? logoUrl;
  final String? city;
  final String? country;
  final int? foundedYear;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'city': city,
    'country': country,
    'foundedYear': foundedYear,
    'createdAt': createdAt?.toUtc().toIso8601String(),
  };

  Club toEntity() => Club(
    id: id,
    name: name,
    logoUrl: logoUrl,
    city: city,
    country: country,
    foundedYear: foundedYear,
    createdAt: createdAt,
  );
}
