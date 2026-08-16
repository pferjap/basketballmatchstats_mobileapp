import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/match_event.dart';
import 'event_feed_item.dart';

/// The scrollable play-by-play list of [events] (newest first), rendered as a
/// vertical timeline of [EventFeedItem]s (Plan.md T-017).
class PlayByPlayFeed extends StatelessWidget {
  const PlayByPlayFeed({
    required this.events,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.controller,
    super.key,
  });

  final List<MatchEvent> events;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final ScrollController? controller;

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
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
      itemCount: events.length,
      separatorBuilder: (_, _) =>
          const Divider(color: AppColors.divider, height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return EventFeedItem(
          key: ValueKey<String>(event.id),
          event: event,
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          isFirst: index == 0,
          isLast: index == events.length - 1,
        );
      },
    );
  }
}
