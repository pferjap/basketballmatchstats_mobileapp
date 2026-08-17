import '../../domain/entities/team.dart';

/// Data-layer DTO for a team, aligned with the backend JSON.
///
/// Hand-written (no Freezed) to stay compatible with the installed Dart SDK,
/// matching the convention used by the matches feature.
class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    required this.clubId,
    this.clubName,
    this.category,
    this.logoUrl,
    this.seasonId,
    this.createdAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String?;
    // The backend may embed the parent club instead of a flat `clubName`.
    final club = json['club'];
    final embeddedClubName = club is Map ? club['name'] as String? : null;
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      clubId: json['clubId'] as String,
      clubName: json['clubName'] as String? ?? embeddedClubName,
      category: json['category'] as String?,
      logoUrl: json['logoUrl'] as String?,
      seasonId: json['seasonId'] as String?,
      createdAt: createdAt == null ? null : DateTime.parse(createdAt),
    );
  }

  final String id;
  final String name;
  final String clubId;
  final String? clubName;
  final String? category;
  final String? logoUrl;
  final String? seasonId;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'clubId': clubId,
    'clubName': clubName,
    'category': category,
    'logoUrl': logoUrl,
    'seasonId': seasonId,
    'createdAt': createdAt?.toUtc().toIso8601String(),
  };

  Team toEntity() => Team(
    id: id,
    name: name,
    clubId: clubId,
    clubName: clubName,
    category: category,
    logoUrl: logoUrl,
    seasonId: seasonId,
    createdAt: createdAt,
  );
}
