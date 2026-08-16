import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../providers/annotation_state_provider.dart';
import 'event_feed_item.dart';

/// The HISTORIAL tab of the Court View (Plan.md T-021): the events recorded this
/// session, newest first, each showing its sync status. The most recent event
/// (within 30s) can be swipe-undone with confirmation, and failed events can be
/// retried. Reuses [EventFeedItem] from the broadcast screen.
class AnnotationHistoryTab extends StatelessWidget {
  const AnnotationHistoryTab({
    required this.events,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.canUndo,
    required this.onUndo,
    required this.onRetry,
    super.key,
  });

  final List<RecordedEvent> events;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final bool Function(RecordedEvent) canUndo;
  final ValueChanged<RecordedEvent> onUndo;
  final ValueChanged<RecordedEvent> onRetry;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(kSpacingXL),
          child: Text(
            'Aún no hay acciones registradas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
      itemCount: events.length,
      separatorBuilder: (_, _) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final recorded = events[index];
        final isFirst = index == 0;
        final row = _HistoryRow(
          recorded: recorded,
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          isFirst: isFirst,
          isLast: index == events.length - 1,
          onRetry: onRetry,
        );

        if (!canUndo(recorded)) return row;

        return Dismissible(
          key: ValueKey<String>('undo-${recorded.event.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: AppColors.error.withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(horizontal: kSpacingL),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Icon(Icons.undo, color: AppColors.error),
                SizedBox(width: kSpacingS),
                Text(
                  'Deshacer',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) => _confirmUndo(context),
          onDismissed: (_) => onUndo(recorded),
          child: row,
        );
      },
    );
  }

  Future<bool> _confirmUndo(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Deshacer acción',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Seguro que quieres deshacer la última acción registrada?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Deshacer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.recorded,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.isFirst,
    required this.isLast,
    required this.onRetry,
  });

  final RecordedEvent recorded;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<RecordedEvent> onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: EventFeedItem(
              event: recorded.event,
              homeTeamId: homeTeamId,
              awayTeamId: awayTeamId,
              homeTeamName: homeTeamName,
              awayTeamName: awayTeamName,
              isFirst: isFirst,
              isLast: isLast,
            ),
          ),
          _StatusIndicator(recorded: recorded, onRetry: onRetry),
          const SizedBox(width: kSpacingS),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.recorded, required this.onRetry});

  final RecordedEvent recorded;
  final ValueChanged<RecordedEvent> onRetry;

  @override
  Widget build(BuildContext context) {
    switch (recorded.status) {
      case EventSyncStatus.pending:
        return const Tooltip(
          message: 'Pendiente de sincronizar',
          child: Icon(Icons.cloud_upload_outlined,
              color: AppColors.textSecondary, size: 18),
        );
      case EventSyncStatus.synced:
        return const Icon(Icons.check_circle_outline,
            color: AppColors.success, size: 18);
      case EventSyncStatus.failed:
        return IconButton(
          onPressed: () => onRetry(recorded),
          iconSize: 18,
          tooltip: 'Reintentar',
          icon: const Icon(Icons.error_outline, color: AppColors.error),
        );
    }
  }
}
