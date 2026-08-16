import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import 'foul_indicator.dart';
import 'game_clock_widget.dart';

/// The compact score header of the Court View (Plan.md T-018): each team's
/// crest, name, large score and foul dots, with the central game clock between
/// them.
class AnnotationScoreHeader extends StatelessWidget {
  const AnnotationScoreHeader({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.homeFouls,
    required this.awayFouls,
    required this.clockSeconds,
    this.onClockTick,
    this.clockKey,
    super.key,
  });

  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final int homeFouls;
  final int awayFouls;
  final int clockSeconds;
  final ValueChanged<String>? onClockTick;

  /// Key for the clock widget; change it (e.g. per period) to reset the clock.
  final Key? clockKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingS,
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _TeamBlock(
                  name: homeTeamName,
                  score: homeScore,
                  crestColor: AppColors.accentPurple,
                  alignEnd: false,
                ),
              ),
              GameClockWidget(
                key: clockKey,
                initialSeconds: clockSeconds,
                onTick: onClockTick,
              ),
              Expanded(
                child: _TeamBlock(
                  name: awayTeamName,
                  score: awayScore,
                  crestColor: AppColors.primary,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingXS),
          Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FoulIndicator(fouls: homeFouls),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FoulIndicator(fouls: awayFouls),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({
    required this.name,
    required this.score,
    required this.crestColor,
    required this.alignEnd,
  });

  final String name;
  final int score;
  final Color crestColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final crest = Icon(Icons.shield, color: crestColor, size: 36);
    final label = Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '$score',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? <Widget>[Flexible(child: label), const SizedBox(width: 8), crest]
          : <Widget>[crest, const SizedBox(width: 8), Flexible(child: label)],
    );
  }
}
