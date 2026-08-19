import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../providers/live_match_provider.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/live_badge.dart';
import '../widgets/play_by_play_feed.dart';
import '../widgets/score_header_widget.dart';

/// Display metadata for the live-match screen that is not carried by the
/// [MatchScore]/[MatchEvent] stream (team names, competition label). Passed via
/// GoRouter `extra` from the match-selection flow; sensible fallbacks are used
/// when absent.
class LiveMatchArgs {
  const LiveMatchArgs({
    this.homeTeamId = '',
    this.awayTeamId = '',
    this.homeTeamName = 'Local',
    this.homeClubName = '',
    this.awayTeamName = 'Visitante',
    this.awayClubName = '',
    this.competitionLabel,
    this.totalPeriods = 4,
  });

  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String homeClubName;
  final String awayTeamName;
  final String awayClubName;
  final String? competitionLabel;

  /// Number of regular quarters configured for the match (no overtime).
  final int totalPeriods;

  String get matchTitle => '$homeTeamName vs $awayTeamName';
}

/// The live-match spectator screen (Plan.md T-017,
/// design: `docs/images/sala_restransmision_partido.png`).
///
/// Subscribes to the realtime read channel on entry (via
/// [liveMatchControllerProvider]) and renders the scoreboard header, the
/// play-by-play feed and a "load earlier" action. The connection indicator and
/// "EN DIRECTO" badge live in the AppBar.
class MatchLivePage extends ConsumerWidget {
  const MatchLivePage({required this.matchId, this.args, super.key});

  final String matchId;
  final LiveMatchArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = args ?? const LiveMatchArgs();
    final state = ref.watch(liveMatchControllerProvider(matchId));
    final controller = ref.read(liveMatchControllerProvider(matchId).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.matchTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (info.competitionLabel != null)
              Text(
                info.competitionLabel!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: kSpacingS),
            child: Row(
              children: [
                ConnectionIndicator(state: state.connection),
                const SizedBox(width: kSpacingS),
                const LiveBadge(),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ScoreHeaderWidget(
            homeTeamName: info.homeTeamName,
            homeClubName: info.homeClubName,
            awayTeamName: info.awayTeamName,
            awayClubName: info.awayClubName,
            score: state.score,
            matchId: matchId,
            periodCount: info.totalPeriods + 1,
          ),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: _FeedArea(
              state: state,
              info: info,
              onLoadMore: controller.loadEarlier,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedArea extends StatefulWidget {
  const _FeedArea({
    required this.state,
    required this.info,
    required this.onLoadMore,
  });

  final LiveMatchState state;
  final LiveMatchArgs info;
  final VoidCallback onLoadMore;

  @override
  State<_FeedArea> createState() => _FeedAreaState();
}

class _FeedAreaState extends State<_FeedArea> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200 &&
        widget.state.hasMoreEarlier &&
        !widget.state.isLoadingEarlier) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.state.errorMessage != null && widget.state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpacingL),
          child: Text(
            widget.state.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return PlayByPlayFeed(
      events: widget.state.events,
      homeTeamId: widget.info.homeTeamId,
      awayTeamId: widget.info.awayTeamId,
      homeTeamName: widget.info.homeTeamName,
      awayTeamName: widget.info.awayTeamName,
      controller: _scrollController,
    );
  }
}
