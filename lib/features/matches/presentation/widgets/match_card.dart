import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/match.dart';

/// A single match row in the selection list (Plan.md T-022).
///
/// Shows the two teams, the scheduled date/time, a status badge and the
/// competition label. Team and competition identifiers are shown as-is until
/// the Teams/Competitions features (later phases) provide display names.
class MatchCard extends StatelessWidget {
  const MatchCard({
    required this.match,
    required this.onTap,
    this.homeLabel,
    this.awayLabel,
    this.competitionLabel,
    super.key,
  });

  final Match match;
  final VoidCallback onTap;

  /// Optional display names; fall back to the team ids when absent.
  final String? homeLabel;
  final String? awayLabel;

  /// Optional competition display name; falls back to the competition id.
  final String? competitionLabel;

  @override
  Widget build(BuildContext context) {
    final home = homeLabel ?? match.homeTeamId;
    final away = awayLabel ?? match.awayTeamId;
    final competition = competitionLabel ?? match.competitionId;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: kSpacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(kSpacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$home  vs  $away',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: kSpacingS),
                  _StatusBadge(status: match.status),
                ],
              ),
              const SizedBox(height: kSpacingS),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: kSpacingXS),
                  Text(
                    formatMatchDateTime(match.scheduledAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (competition != null && competition.isNotEmpty) ...[
                const SizedBox(height: kSpacingXS),
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: kSpacingXS),
                    Expanded(
                      child: Text(
                        competition,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Colored pill showing the match status in Spanish.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.scheduled => ('PROGRAMADO', AppColors.info),
      MatchStatus.inProgress => ('EN DIRECTO', AppColors.success),
      MatchStatus.finished => ('FINALIZADO', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingS,
        vertical: kSpacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

const List<String> _kMonthsEs = <String>[
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Formats a match date/time in Spanish, e.g. `12 mar 2025 · 20:30`.
String formatMatchDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = _kMonthsEs[local.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} $month ${local.year} · $hour:$minute';
}
