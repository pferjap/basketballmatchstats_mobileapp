import '../../domain/entities/coordinates.dart';

/// Data-layer DTO for normalized court [Coordinates] (`{ x, y }`, 0–100).
class CoordinatesModel {
  const CoordinatesModel({required this.x, required this.y});

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) =>
      CoordinatesModel(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  /// Builds a DTO from a domain [Coordinates] value.
  factory CoordinatesModel.fromEntity(Coordinates entity) =>
      CoordinatesModel(x: entity.x, y: entity.y);

  final double x;
  final double y;

  Map<String, dynamic> toJson() => <String, dynamic>{'x': x, 'y': y};

  Coordinates toEntity() => Coordinates(x: x, y: y);
}
