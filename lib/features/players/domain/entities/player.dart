/// On-court position of a player, mirroring the backend enum.
///
/// The API string representation lives in the data layer
/// (`data/models/player_model.dart` — `PlayerPositionConverter`).
enum PlayerPosition {
  /// Point guard — base.
  pointGuard,

  /// Shooting guard — escolta.
  shootingGuard,

  /// Small forward — alero.
  smallForward,

  /// Power forward — ala-pívot.
  powerForward,

  /// Center — pívot.
  center,
}

/// A player belonging to a team, in the domain layer.
///
/// Plain, dependency-free value object; the data-layer model maps into this via
/// its `toEntity()` method. See Plan.md T-025.
class Player {
  const Player({
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

  final String id;
  final String firstName;
  final String lastName;
  final String teamId;

  /// Squad number shown on the jersey.
  final int? jerseyNumber;
  final PlayerPosition? position;

  /// Denormalised team name, when the backend embeds it for list rendering.
  final String? teamName;
  final String? photoUrl;
  final DateTime? birthDate;

  /// Height in centimetres.
  final int? height;

  /// Weight in kilograms.
  final int? weight;
  final DateTime? createdAt;

  /// Convenience display name, e.g. "Álvaro Ruiz".
  String get fullName => '$firstName $lastName'.trim();

  Player copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? teamId,
    int? jerseyNumber,
    PlayerPosition? position,
    String? teamName,
    String? photoUrl,
    DateTime? birthDate,
    int? height,
    int? weight,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      teamId: teamId ?? this.teamId,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      position: position ?? this.position,
      teamName: teamName ?? this.teamName,
      photoUrl: photoUrl ?? this.photoUrl,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          other.id == id &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.teamId == teamId &&
          other.jerseyNumber == jerseyNumber &&
          other.position == position &&
          other.teamName == teamName &&
          other.photoUrl == photoUrl &&
          other.birthDate == birthDate &&
          other.height == height &&
          other.weight == weight &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    lastName,
    teamId,
    jerseyNumber,
    position,
    teamName,
    photoUrl,
    birthDate,
    height,
    weight,
    createdAt,
  );
}
