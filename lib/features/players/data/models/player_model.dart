import '../../domain/entities/player.dart';

/// Maps the backend position strings (`POINT_GUARD`, `SHOOTING_GUARD`, …) to
/// the domain [PlayerPosition] enum.
class PlayerPositionConverter {
  const PlayerPositionConverter();

  static const Map<String, PlayerPosition> _fromApi = <String, PlayerPosition>{
    'POINT_GUARD': PlayerPosition.pointGuard,
    'SHOOTING_GUARD': PlayerPosition.shootingGuard,
    'SMALL_FORWARD': PlayerPosition.smallForward,
    'POWER_FORWARD': PlayerPosition.powerForward,
    'CENTER': PlayerPosition.center,
  };

  static const Map<PlayerPosition, String> _toApi = <PlayerPosition, String>{
    PlayerPosition.pointGuard: 'POINT_GUARD',
    PlayerPosition.shootingGuard: 'SHOOTING_GUARD',
    PlayerPosition.smallForward: 'SMALL_FORWARD',
    PlayerPosition.powerForward: 'POWER_FORWARD',
    PlayerPosition.center: 'CENTER',
  };

  /// Returns `null` for an absent value; throws on an unrecognised one so a
  /// backend enum change surfaces loudly instead of silently dropping data.
  PlayerPosition? fromJson(String? json) {
    if (json == null) {
      return null;
    }
    final position = _fromApi[json];
    if (position == null) {
      throw FormatException('Unknown player position: $json');
    }
    return position;
  }

  String toJson(PlayerPosition object) => _toApi[object]!;
}

/// Data-layer DTO for a player, aligned with the backend JSON.
///
/// Hand-written (no Freezed) to stay compatible with the installed Dart SDK,
/// matching the convention used by the matches feature.
class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.teamId,
    this.jerseyNumber,
    this.position,
    this.teamName,
    this.photoUrl,
    this.birthDate,
    this.height,
    this.weight,
    this.createdAt,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final birthDate = json['birthDate'] as String?;
    final createdAt = json['createdAt'] as String?;
    // The backend may embed the parent team instead of a flat `teamName`.
    final team = json['team'];
    final embeddedTeamName = team is Map ? team['name'] as String? : null;
    return PlayerModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      teamId: json['teamId'] as String,
      jerseyNumber: (json['jerseyNumber'] as num?)?.toInt(),
      position: const PlayerPositionConverter().fromJson(
        json['position'] as String?,
      ),
      teamName: json['teamName'] as String? ?? embeddedTeamName,
      photoUrl: json['photoUrl'] as String?,
      birthDate: birthDate == null ? null : DateTime.parse(birthDate),
      height: (json['height'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toInt(),
      createdAt: createdAt == null ? null : DateTime.parse(createdAt),
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String teamId;
  final int? jerseyNumber;
  final PlayerPosition? position;
  final String? teamName;
  final String? photoUrl;
  final DateTime? birthDate;
  final int? height;
  final int? weight;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    final position = this.position;
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'teamId': teamId,
      'jerseyNumber': jerseyNumber,
      'position': position == null
          ? null
          : const PlayerPositionConverter().toJson(position),
      'teamName': teamName,
      'photoUrl': photoUrl,
      'birthDate': birthDate?.toUtc().toIso8601String(),
      'height': height,
      'weight': weight,
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  Player toEntity() => Player(
    id: id,
    firstName: firstName,
    lastName: lastName,
    teamId: teamId,
    jerseyNumber: jerseyNumber,
    position: position,
    teamName: teamName,
    photoUrl: photoUrl,
    birthDate: birthDate,
    height: height,
    weight: weight,
    createdAt: createdAt,
  );
}
