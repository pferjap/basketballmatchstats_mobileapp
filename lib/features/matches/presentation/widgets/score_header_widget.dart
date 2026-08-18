import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/match_score.dart';

/// The dark scoreboard card at the top of the live-match screen: crests, team
/// names, the large score (winning side in green), and the period + clock with
/// the quarter navigation dots (Plan.md T-017).
class ScoreHeaderWidget extends StatelessWidget {
  const ScoreHeaderWidget({
    required this.homeTeamName,
    required this.homeClubName,
    required this.awayTeamName,
    required this.awayClubName,
    required this.score,
    this.periodCount = 5,
    super.key,
  });

  final String homeTeamName;
  final String homeClubName;
  final String awayTeamName;
  final String awayClubName;

  /// Latest scoreboard, or `null` before the initial load resolves.
  final MatchScore? score;

  /// Number of navigation dots (quarters + summary).
  final int periodCount;

  @override
  Widget build(BuildContext context) {
    final home = score?.homeTeamScore;
    final away = score?.awayTeamScore;
    final homeWinning = home != null && away != null && home > away;
    final awayWinning = home != null && away != null && away > home;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingL,
      ),
      color: AppColors.background,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TeamColumn(
                  icon: Icons.shield,
                  iconColor: AppColors.primary,
                  teamName: homeTeamName,
                  clubName: homeClubName,
                ),
              ),
              _ScoreValue(value: home, highlight: homeWinning),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: kSpacingS),
                child: Text(
                  '-',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ScoreValue(value: away, highlight: awayWinning),
              Expanded(
                child: _TeamColumn(
                  icon: Icons.shield,
                  iconColor: AppColors.info,
                  teamName: awayTeamName,
                  clubName: awayClubName,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingM),
          _PeriodClock(score: score),
          const SizedBox(height: kSpacingXS),
          const Text(
            'Tiempo de cuarto',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: kSpacingM),
          _PeriodDots(
            count: periodCount,
            currentPeriod: score?.currentPeriod ?? 1,
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.icon,
    required this.iconColor,
    required this.teamName,
    required this.clubName,
  });

  final IconData icon;
  final Color iconColor;
  final String teamName;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 56, color: iconColor),
        const SizedBox(height: kSpacingS),
        Text(
          teamName.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: kSpacingXS),
        Text(
          clubName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _ScoreValue extends StatelessWidget {
  const _ScoreValue({required this.value, required this.highlight});

  final int? value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Text(
      value?.toString() ?? '–',
      style: TextStyle(
        color: highlight ? AppColors.success : AppColors.textPrimary,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
  }
}

class _PeriodClock extends StatelessWidget {
  const _PeriodClock({required this.score});

  final MatchScore? score;

  @override
  Widget build(BuildContext context) {
    final period = score?.currentPeriod;
    final clock = score?.gameClock ?? '--:--';
    final periodLabel = period == null
        ? '--'
        : period <= 4
        ? 'Q$period'
        : 'OT${period - 4}';
    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: periodLabel,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(
            text: ' · ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          TextSpan(
            text: clock,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodDots extends StatelessWidget {
  const _PeriodDots({required this.count, required this.currentPeriod});

  final int count;
  final int currentPeriod;

  @override
  Widget build(BuildContext context) {
    final activeIndex = (currentPeriod - 1).clamp(0, count - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _Dot(
              color: i == activeIndex
                  ? AppColors.primary
                  : i < activeIndex
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.divider,
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
