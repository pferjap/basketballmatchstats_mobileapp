import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/match_score.dart';
import '../providers/match_clock_store.dart';

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
    this.matchId,
    this.periodCount = 5,
    super.key,
  });

  final String homeTeamName;
  final String homeClubName;
  final String awayTeamName;
  final String awayClubName;

  /// Latest scoreboard, or `null` before the initial load resolves.
  final MatchScore? score;

  /// Match id used to show the live game clock persisted by the annotator.
  final String? matchId;

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
          _PeriodClock(score: score, matchId: matchId),
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
  const _PeriodClock({required this.score, this.matchId});

  final MatchScore? score;
  final String? matchId;

  @override
  Widget build(BuildContext context) {
    final period = score?.currentPeriod;
    final periodLabel = period == null
        ? '--'
        : period <= 4
        ? 'Q$period'
        : 'OT${period - 4}';
    const labelStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          periodLabel,
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          ' · ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
        ),
        _SpectatorClock(
          matchId: matchId,
          fallback: score?.gameClock ?? '--:--',
          style: labelStyle,
        ),
      ],
    );
  }
}

/// A read-only game clock for spectators. It restores the clock the annotator
/// persisted for this match (same device) and keeps ticking while running;
/// otherwise it shows the last-known [fallback] value from the score feed.
class _SpectatorClock extends StatefulWidget {
  const _SpectatorClock({
    required this.matchId,
    required this.fallback,
    required this.style,
  });

  final String? matchId;
  final String fallback;
  final TextStyle style;

  @override
  State<_SpectatorClock> createState() => _SpectatorClockState();
}

class _SpectatorClockState extends State<_SpectatorClock> {
  Timer? _timer;
  int? _remaining;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void didUpdateWidget(_SpectatorClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.matchId != oldWidget.matchId) {
      _restore();
    }
  }

  Future<void> _restore() async {
    final id = widget.matchId;
    if (id == null) return;
    final snapshot = await MatchClockStore.read(id);
    if (!mounted || snapshot == null) return;
    setState(() => _remaining = snapshot.remainingSeconds);
    _timer?.cancel();
    if (snapshot.running && snapshot.remainingSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          final next = (_remaining ?? 0) - 1;
          _remaining = next < 0 ? 0 : next;
          if (_remaining! <= 0) {
            _timer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final text = remaining != null ? _format(remaining) : widget.fallback;
    return Text(text, style: widget.style);
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
