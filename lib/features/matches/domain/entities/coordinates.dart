/// Normalized court coordinates for an event, each in the range 0–100.
///
/// `x` runs baseline-to-baseline and `y` sideline-to-sideline, independent of
/// the physical court dimensions so shots can be plotted consistently.
class Coordinates {
  const Coordinates({required this.x, required this.y});

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinates &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Coordinates(x: $x, y: $y)';
}
