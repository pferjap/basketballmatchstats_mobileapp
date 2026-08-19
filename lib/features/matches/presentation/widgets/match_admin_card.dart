import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/match.dart';

/// Status badge colour and label for a match, mirroring the design's
/// blue/green/grey coding.
({Color color, String label}) _statusBadge(MatchStatus status) {
  return switch (status) {
    MatchStatus.scheduled => (color: AppColors.info, label: 'Programado'),
    MatchStatus.inProgress => (color: AppColors.success, label: 'En curso'),
    MatchStatus.finished => (
      color: AppColors.textSecondary,
      label: 'Finalizado',
    ),
    MatchStatus.cancelled => (color: AppColors.error, label: 'Cancelado'),
    MatchStatus.postponed => (color: AppColors.warning, label: 'Pospuesto'),
    MatchStatus.suspended => (color: AppColors.warning, label: 'Suspendido'),
  };
}

/// List row for a match inside the admin panel (Plan.md T-030).
class MatchAdminCard extends StatelessWidget {
  const MatchAdminCard({
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.onEdit,
    required this.onDelete,
    this.onFinish,
    this.onCancel,
    this.onPostpone,
    super.key,
  });

  final Match match;

  /// Resolved home team name, falling back to its id when unknown.
  final String homeTeamName;

  /// Resolved away team name, falling back to its id when unknown.
  final String awayTeamName;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Superadmin lifecycle actions; when null the entry is hidden.
  final VoidCallback? onFinish;
  final VoidCallback? onCancel;
  final VoidCallback? onPostpone;

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(match.status);
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingS),
      padding: const EdgeInsets.all(kSpacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badge.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      color: badge.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: kSpacingS),
                Text(
                  '$homeTeamName vs $awayTeamName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSpacingXS),
                _IconLine(
                  icon: Icons.schedule,
                  text: _formatDateTime(match.scheduledAt),
                ),
                if (match.venue != null) ...<Widget>[
                  const SizedBox(height: kSpacingXS),
                  _IconLine(icon: Icons.place_outlined, text: match.venue!),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            tooltip: 'Más acciones',
            color: AppColors.surface,
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'finish':
                  onFinish?.call();
                case 'cancel':
                  onCancel?.call();
                case 'postpone':
                  onPostpone?.call();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text(
                  'Editar',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              if (onFinish != null)
                const PopupMenuItem<String>(
                  value: 'finish',
                  child: Text(
                    'Finalizar',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              if (onPostpone != null)
                const PopupMenuItem<String>(
                  value: 'postpone',
                  child: Text(
                    'Posponer',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              if (onCancel != null)
                const PopupMenuItem<String>(
                  value: 'cancel',
                  child: Text(
                    'Cancelar partido',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
            tooltip: 'Eliminar partido',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: kSpacingXS),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
