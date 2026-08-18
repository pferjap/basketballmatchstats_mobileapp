import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/event_type.dart';
import '../../domain/entities/match_event.dart';

/// Icon + color + human title describing how an event renders in the feed.
class EventVisual {
  const EventVisual({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;
}

/// Resolves the visual treatment (icon, color, Spanish title) for [event],
/// honouring point values in metadata (2 vs 3 vs free throw).
EventVisual eventVisualFor(MatchEvent event) {
  switch (event.eventType) {
    case EventType.pointsMade:
      final points = _asInt(event.metadata?['points']);
      final title = switch (points) {
        3 => 'Triple',
        1 => 'Tiro libre anotado',
        _ => 'Canasta de 2 puntos',
      };
      return EventVisual(
        icon: Icons.sports_basketball,
        color: AppColors.success,
        title: title,
      );
    case EventType.pointsMissed:
      return const EventVisual(
        icon: Icons.block,
        color: AppColors.textSecondary,
        title: 'Fallo',
      );
    case EventType.reboundOffensive:
      return const EventVisual(
        icon: Icons.sports_basketball,
        color: AppColors.primary,
        title: 'Rebote ofensivo',
      );
    case EventType.reboundDefensive:
      return const EventVisual(
        icon: Icons.sports_basketball,
        color: AppColors.primary,
        title: 'Rebote defensivo',
      );
    case EventType.assist:
      return const EventVisual(
        icon: Icons.handshake,
        color: AppColors.primary,
        title: 'Asistencia',
      );
    case EventType.turnover:
      return const EventVisual(
        icon: Icons.auto_awesome,
        color: AppColors.info,
        title: 'Pérdida',
      );
    case EventType.steal:
      return const EventVisual(
        icon: Icons.pan_tool_alt,
        color: AppColors.info,
        title: 'Robo',
      );
    case EventType.block:
      return const EventVisual(
        icon: Icons.front_hand,
        color: AppColors.info,
        title: 'Tapón',
      );
    case EventType.foulPersonal:
      return const EventVisual(
        icon: Icons.front_hand,
        color: AppColors.error,
        title: 'Falta personal',
      );
    case EventType.foulTechnical:
      return const EventVisual(
        icon: Icons.front_hand,
        color: AppColors.error,
        title: 'Falta técnica',
      );
    case EventType.foulUnsportsmanlike:
      return const EventVisual(
        icon: Icons.front_hand,
        color: AppColors.error,
        title: 'Falta antideportiva',
      );
    case EventType.foulDisqualifying:
      return const EventVisual(
        icon: Icons.front_hand,
        color: AppColors.error,
        title: 'Falta descalificante',
      );
    case EventType.freeThrowAwarded:
      return const EventVisual(
        icon: Icons.sports,
        color: AppColors.error,
        title: 'Tiro libre concedido',
      );
    case EventType.substitution:
      return const EventVisual(
        icon: Icons.swap_horiz,
        color: AppColors.info,
        title: 'Sustitución',
      );
    case EventType.timeout:
      return const EventVisual(
        icon: Icons.pause_circle_outline,
        color: AppColors.warning,
        title: 'Tiempo muerto',
      );
    case EventType.quarterStart:
      return const EventVisual(
        icon: Icons.play_circle_outline,
        color: AppColors.textSecondary,
        title: 'Inicio de cuarto',
      );
    case EventType.quarterEnd:
      return const EventVisual(
        icon: Icons.stop_circle_outlined,
        color: AppColors.textSecondary,
        title: 'Fin de cuarto',
      );
    case EventType.matchStart:
      return const EventVisual(
        icon: Icons.flag_outlined,
        color: AppColors.success,
        title: 'Inicio del partido',
      );
    case EventType.matchFinish:
      return const EventVisual(
        icon: Icons.emoji_events_outlined,
        color: AppColors.success,
        title: 'Fin del partido',
      );
  }
}

/// A single play-by-play row: game clock, a tinted event icon on the timeline,
/// the event title + detail, and (when available) the running partial score
/// with the scoring team's label (Plan.md T-017).
class EventFeedItem extends StatelessWidget {
  const EventFeedItem({
    required this.event,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final MatchEvent event;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final visual = eventVisualFor(event);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                event.gameClock,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _TimelineIcon(visual: visual, isFirst: isFirst, isLast: isLast),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: _EventBody(event: event, title: visual.title),
          ),
          const SizedBox(width: kSpacingS),
          _PartialScore(
            event: event,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            homeTeamName: homeTeamName,
            awayTeamName: awayTeamName,
          ),
        ],
      ),
    );
  }
}

class _TimelineIcon extends StatelessWidget {
  const _TimelineIcon({
    required this.visual,
    required this.isFirst,
    required this.isLast,
  });

  final EventVisual visual;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 6,
          child: isFirst
              ? const SizedBox.shrink()
              : const VerticalDivider(
                  color: AppColors.divider,
                  width: 2,
                  thickness: 2,
                ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: visual.color.withValues(alpha: 0.15),
            border: Border.all(color: visual.color, width: 2),
          ),
          child: Icon(visual.icon, size: 20, color: visual.color),
        ),
        Expanded(
          child: isLast
              ? const SizedBox.shrink()
              : const VerticalDivider(
                  color: AppColors.divider,
                  width: 2,
                  thickness: 2,
                ),
        ),
      ],
    );
  }
}

class _EventBody extends StatelessWidget {
  const _EventBody({required this.event, required this.title});

  final MatchEvent event;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          if (event.eventType == EventType.substitution)
            _SubstitutionDetail(metadata: event.metadata)
          else
            Text(
              _playerLabel(event),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _SubstitutionDetail extends StatelessWidget {
  const _SubstitutionDetail({required this.metadata});

  final Map<String, dynamic>? metadata;

  @override
  Widget build(BuildContext context) {
    final inNumber = _asInt(metadata?['playerInNumber']);
    final inName = _asString(metadata?['playerInName']);
    final outNumber = _asInt(metadata?['playerOutNumber']);
    final outName = _asString(metadata?['playerOutName']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sideText('Entra', inNumber, inName),
          style: const TextStyle(color: AppColors.success, fontSize: 14),
        ),
        Text(
          _sideText('Sale', outNumber, outName),
          style: const TextStyle(color: AppColors.error, fontSize: 14),
        ),
      ],
    );
  }

  String _sideText(String verb, int? number, String? name) {
    final parts = <String>[verb, if (number != null) '#$number', ?name];
    return parts.join(' ');
  }
}

class _PartialScore extends StatelessWidget {
  const _PartialScore({
    required this.event,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final MatchEvent event;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    final home = _asInt(event.metadata?['homeScore']);
    final away = _asInt(event.metadata?['awayScore']);
    if (home == null || away == null) {
      return const SizedBox.shrink();
    }

    final homeScored = event.teamId == homeTeamId;
    final awayScored = event.teamId == awayTeamId;
    final teamLabel = home == away
        ? 'Empate'
        : homeScored
        ? homeTeamName.toUpperCase()
        : awayScored
        ? awayTeamName.toUpperCase()
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: '$home',
                style: TextStyle(
                  color: homeScored && home != away
                      ? AppColors.success
                      : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: ' - ',
                style: TextStyle(color: AppColors.primary, fontSize: 16),
              ),
              TextSpan(
                text: '$away',
                style: TextStyle(
                  color: awayScored && home != away
                      ? AppColors.success
                      : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          teamLabel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

String _playerLabel(MatchEvent event) {
  final number = _asInt(event.metadata?['playerNumber']);
  final name = _asString(event.metadata?['playerName']);
  if (name != null) {
    return number != null ? '#$number $name' : name;
  }
  if (event.playerId != null) {
    return 'Jugador ${event.playerId}';
  }
  return '';
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}
