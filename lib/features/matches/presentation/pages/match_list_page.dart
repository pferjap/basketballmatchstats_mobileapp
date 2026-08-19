import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../players/presentation/providers/players_providers.dart';
import '../../domain/entities/match.dart';
import '../models/court_view_args.dart';
import '../pages/match_live_page.dart';
import '../providers/match_list_provider.dart';
import '../providers/match_providers.dart';
import '../widgets/match_card.dart';

/// Intermediate screen between the home menu and the Court View / Live screens
/// that lists the matches the user can enter (Plan.md T-022).
///
/// The [mode] decides both which matches are shown (annotate → scheduled or
/// in-progress; spectate → in-progress) and where a tap navigates.
class MatchListPage extends ConsumerStatefulWidget {
  const MatchListPage({required this.mode, super.key});

  final MatchListMode mode;

  @override
  ConsumerState<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends ConsumerState<MatchListPage> {
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
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(matchListControllerProvider(widget.mode).notifier).loadMore();
    }
  }

  String get _title => switch (widget.mode) {
    MatchListMode.annotate => 'Tomar anotaciones',
    MatchListMode.spectate => 'Asistir a un partido',
  };

  Future<void> _openMatch(Match match) async {
    final homeName = await ref.read(teamNameProvider(match.homeTeamId).future);
    final awayName = await ref.read(teamNameProvider(match.awayTeamId).future);
    if (!mounted) return;

    switch (widget.mode) {
      case MatchListMode.annotate:
        // Auto-start the match if it's still scheduled.
        if (match.status == MatchStatus.scheduled) {
          try {
            await ref.read(startMatchUseCaseProvider).call(match.id);
          } catch (_) {
            // Best-effort; the API may already have started it.
          }
        }

        // Load real rosters from the API.
        final playerRepo = ref.read(playerRepositoryProvider);
        List<RosterPlayer> homeRoster;
        List<RosterPlayer> awayRoster;
        try {
          final homePlayers = await playerRepo.getPlayers(
            teamId: match.homeTeamId,
            limit: 50,
          );
          homeRoster = homePlayers.items
              .map(
                (p) => RosterPlayer(
                  id: p.id,
                  number: p.jerseyNumber ?? 0,
                  name: '${p.firstName} ${p.lastName}',
                ),
              )
              .toList(growable: false);
        } catch (_) {
          homeRoster = CourtViewArgs.demo().home.roster;
        }
        try {
          final awayPlayers = await playerRepo.getPlayers(
            teamId: match.awayTeamId,
            limit: 50,
          );
          awayRoster = awayPlayers.items
              .map(
                (p) => RosterPlayer(
                  id: p.id,
                  number: p.jerseyNumber ?? 0,
                  name: '${p.firstName} ${p.lastName}',
                ),
              )
              .toList(growable: false);
        } catch (_) {
          awayRoster = CourtViewArgs.demo().away.roster;
        }

        // Determine the resume clock from existing events.
        int? resumeClock;
        try {
          final matchRepo = ref.read(matchRepositoryProvider);
          final eventsPage = await matchRepo.getMatchEvents(match.id, limit: 1);
          if (eventsPage.items.isNotEmpty) {
            final clock = eventsPage.items.first.gameClock;
            final parts = clock.split(':');
            if (parts.length == 2) {
              resumeClock = (int.tryParse(parts[0]) ?? 0) * 60 +
                  (int.tryParse(parts[1]) ?? 0);
            }
          }
        } catch (_) {
          // Best-effort.
        }

        if (!mounted) return;
        context.push(
          '/matches/${match.id}/annotate',
          extra: CourtViewArgs(
            home: CourtTeam(
              id: match.homeTeamId,
              name: homeName,
              roster: homeRoster,
            ),
            away: CourtTeam(
              id: match.awayTeamId,
              name: awayName,
              roster: awayRoster,
            ),
            competitionLabel: match.competitionId,
            initialClockSeconds: resumeClock,
            periodDurationSeconds: match.periodDurationMinutes * 60,
            totalPeriods: match.totalPeriods,
          ),
        );
      case MatchListMode.spectate:
        context.push(
          '/matches/${match.id}/live',
          extra: LiveMatchArgs(
            homeTeamId: match.homeTeamId,
            awayTeamId: match.awayTeamId,
            homeTeamName: homeName,
            awayTeamName: awayName,
            competitionLabel: match.competitionId,
            totalPeriods: match.totalPeriods,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchListControllerProvider(widget.mode));
    final controller = ref.read(
      matchListControllerProvider(widget.mode).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        // The home menu navigates here with `go`, which replaces the location
        // instead of stacking it, so there is no route to pop — send the user
        // back to the main menu explicitly.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al menú principal',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _Body(
          state: state,
          scrollController: _scrollController,
          mode: widget.mode,
          onTapMatch: _openMatch,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.scrollController,
    required this.mode,
    required this.onTapMatch,
  });

  final MatchListState state;
  final ScrollController scrollController;
  final MatchListMode mode;
  final void Function(Match match) onTapMatch;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.matches.isEmpty) {
      return _MessageView(
        icon: Icons.wifi_off,
        message: state.errorMessage!,
        scrollController: scrollController,
      );
    }

    if (state.matches.isEmpty) {
      return _MessageView(
        icon: Icons.event_busy,
        message: switch (mode) {
          MatchListMode.annotate =>
            'No tienes partidos para anotar en este momento.',
          MatchListMode.spectate => 'No hay partidos en directo ahora mismo.',
        },
        scrollController: scrollController,
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        kSpacingM,
        kSpacingM,
        kSpacingM,
        kSpacingXL,
      ),
      itemCount: state.matches.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.matches.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: kSpacingM),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final match = state.matches[index];
        return _MatchCardWithNames(match: match, onTap: () => onTapMatch(match));
      },
    );
  }
}

/// Wraps [MatchCard] with team-name resolution via [teamNameProvider].
class _MatchCardWithNames extends ConsumerWidget {
  const _MatchCardWithNames({required this.match, required this.onTap});

  final Match match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeName = ref.watch(teamNameProvider(match.homeTeamId));
    final awayName = ref.watch(teamNameProvider(match.awayTeamId));

    return MatchCard(
      match: match,
      onTap: onTap,
      homeLabel: homeName.valueOrNull,
      awayLabel: awayName.valueOrNull,
    );
  }
}

/// Full-screen, scrollable placeholder so pull-to-refresh still works when the
/// list is empty or errored.
class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.message,
    required this.scrollController,
  });

  final IconData icon;
  final String message;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(kSpacingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: kSpacingM),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
