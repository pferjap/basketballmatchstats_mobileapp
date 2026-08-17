import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/event_type.dart';

/// Visual grouping of an annotation action, driving its accent color and the
/// section separator it sits under in the grid.
enum AnnotationCategory { shot, action, foul }

/// The nine annotation actions offered on the Court View grid
/// (design: `docs/images/anotation_screen.png`).
enum AnnotationActionId {
  twoPoints,
  threePoints,
  miss,
  assist,
  rebound,
  turnover,
  foulPersonal,
  foulOffensive,
  freeThrows,
}

/// Describes one action button: its label, icon, category and how it maps onto
/// a domain [EventType] + metadata when recorded.
@immutable
class AnnotationAction {
  const AnnotationAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    required this.eventType,
    this.points,
    this.metadata,
    this.requiresDetails = false,
  });

  final AnnotationActionId id;

  /// Button caption (may wrap over two lines, e.g. "2 PT\nCANASTA").
  final String label;
  final IconData icon;
  final AnnotationCategory category;
  final EventType eventType;

  /// Point value for made shots (2 or 3); `null` for non-scoring actions.
  final int? points;

  /// Extra event metadata merged into the recorded event.
  final Map<String, dynamic>? metadata;

  /// Whether selecting a player advances to the optional details step (3)
  /// instead of recording immediately. True for shots (court location).
  final bool requiresDetails;

  /// Accent color for the icon/label, derived from [category].
  Color get color => switch (category) {
    AnnotationCategory.shot =>
      points != null ? AppColors.success : AppColors.textPrimary,
    AnnotationCategory.action => AppColors.primary,
    AnnotationCategory.foul => AppColors.error,
  };

  /// Whether this action counts as a team foul (bumps the foul indicator).
  bool get isTeamFoul =>
      id == AnnotationActionId.foulPersonal ||
      id == AnnotationActionId.foulOffensive;

  /// Points contributed to the score when recorded (0 for non-scoring).
  int get scoringPoints =>
      eventType == EventType.pointsMade ? (points ?? 0) : 0;

  /// Metadata to persist with the event (points + any static metadata).
  Map<String, dynamic>? buildMetadata() {
    final result = <String, dynamic>{};
    if (points != null) result['points'] = points;
    if (metadata != null) result.addAll(metadata!);
    return result.isEmpty ? null : result;
  }
}

/// The action catalog rendered by the grid, in display order and grouped by
/// [AnnotationCategory] (TIRO / ACCIONES / FALTAS).
const List<AnnotationAction> kAnnotationActions = <AnnotationAction>[
  AnnotationAction(
    id: AnnotationActionId.twoPoints,
    label: '2 PT\nCANASTA',
    icon: Icons.sports_basketball,
    category: AnnotationCategory.shot,
    eventType: EventType.pointsMade,
    points: 2,
    requiresDetails: true,
  ),
  AnnotationAction(
    id: AnnotationActionId.threePoints,
    label: '3 PT\nCANASTA',
    icon: Icons.sports_basketball,
    category: AnnotationCategory.shot,
    eventType: EventType.pointsMade,
    points: 3,
    requiresDetails: true,
  ),
  AnnotationAction(
    id: AnnotationActionId.miss,
    label: 'FALLO',
    icon: Icons.block,
    category: AnnotationCategory.shot,
    eventType: EventType.pointsMissed,
    requiresDetails: true,
  ),
  AnnotationAction(
    id: AnnotationActionId.assist,
    label: 'ASISTENCIA',
    icon: Icons.handshake,
    category: AnnotationCategory.action,
    eventType: EventType.assist,
  ),
  AnnotationAction(
    id: AnnotationActionId.rebound,
    label: 'REBOTE',
    icon: Icons.back_hand,
    category: AnnotationCategory.action,
    eventType: EventType.reboundDefensive,
  ),
  AnnotationAction(
    id: AnnotationActionId.turnover,
    label: 'PÉRDIDA',
    icon: Icons.autorenew,
    category: AnnotationCategory.action,
    eventType: EventType.turnover,
  ),
  AnnotationAction(
    id: AnnotationActionId.foulPersonal,
    label: 'FALTA\nPERSONAL',
    icon: Icons.front_hand,
    category: AnnotationCategory.foul,
    eventType: EventType.foulPersonal,
  ),
  AnnotationAction(
    id: AnnotationActionId.foulOffensive,
    label: 'FALTA\nEN ATAQUE',
    icon: Icons.sign_language,
    category: AnnotationCategory.foul,
    eventType: EventType.foulPersonal,
    metadata: <String, dynamic>{'offensive': true},
  ),
  AnnotationAction(
    id: AnnotationActionId.freeThrows,
    label: 'TIROS\nLIBRES',
    icon: Icons.gps_fixed,
    category: AnnotationCategory.foul,
    eventType: EventType.freeThrowAwarded,
  ),
];
