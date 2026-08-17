import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../models/court_view_args.dart';
import '../providers/annotation_state_provider.dart';
import '../widgets/action_grid.dart';
import '../widgets/annotation_bottom_bar.dart';
import '../widgets/annotation_history_tab.dart';
import '../widgets/annotation_score_header.dart';
import '../widgets/annotation_stepper.dart';
import '../widgets/period_selector.dart';
import '../widgets/player_carousel.dart';

/// The Court View annotation screen (Plan.md T-018–T-021,
/// design: `docs/images/anotation_screen.png`).
///
/// Top bar with the period selector, a compact score header with the game
/// clock, and two tabs: "ANOTAR ACCIÓN" (the action grid + player selector
/// driving the ≤3-tap flow) and "HISTORIAL" (the recorded events). A fixed
/// bottom bar switches the annotated team and undoes the last action.
class CourtViewPage extends ConsumerStatefulWidget {
  const CourtViewPage({required this.matchId, this.args, super.key});

  final String matchId;
  final CourtViewArgs? args;

  @override
  ConsumerState<CourtViewPage> createState() => _CourtViewPageState();
}

class _CourtViewPageState extends ConsumerState<CourtViewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );
  late final CourtViewArgs _args = widget.args ?? CourtViewArgs.demo();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(annotationControllerProvider(widget.matchId).notifier)
          .configure(_args);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CourtTeam get _annotatingTeam {
    final id = ref
        .read(annotationControllerProvider(widget.matchId))
        .annotatingTeamId;
    return id == _args.away.id ? _args.away : _args.home;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(
      annotationControllerProvider(widget.matchId).notifier,
    );
    final state = ref.watch(annotationControllerProvider(widget.matchId));

    ref.listen<String?>(
      annotationControllerProvider(widget.matchId)
          .select((s) => s.errorMessage),
      (previous, next) {
        if (next != null && next != previous) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(next)));
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          tooltip: 'Menú',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: PeriodSelector(
          period: state.currentPeriod,
          onChanged: controller.setPeriod,
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            tooltip: 'Ajustes',
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          AnnotationScoreHeader(
            homeTeamName: _args.home.name,
            awayTeamName: _args.away.name,
            homeScore: state.homeScore,
            awayScore: state.awayScore,
            homeFouls: state.homeFouls,
            awayFouls: state.awayFouls,
            clockSeconds: _args.periodDurationSeconds,
            clockKey: ValueKey<int>(state.currentPeriod),
            onClockTick: controller.setGameClock,
          ),
          _TabHeader(controller: _tabController),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _AnnotateTab(
                  matchId: widget.matchId,
                  annotatingTeam: _annotatingTeam,
                ),
                AnnotationHistoryTab(
                  events: state.events,
                  homeTeamId: state.homeTeamId,
                  awayTeamId: state.awayTeamId,
                  homeTeamName: _args.home.name,
                  awayTeamName: _args.away.name,
                  canUndo: controller.canUndo,
                  onUndo: (_) => controller.undoLast(),
                  onRetry: controller.retry,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnnotationBottomBar(
        home: _args.home,
        away: _args.away,
        annotatingTeamId: state.annotatingTeamId,
        onTeamChanged: controller.setAnnotatingTeam,
        onUndo: controller.undoLast,
        undoEnabled: state.events.isNotEmpty,
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        tabs: const <Widget>[
          Tab(
            icon: Icon(Icons.bolt),
            iconMargin: EdgeInsets.zero,
            child: Text('ANOTAR ACCIÓN'),
          ),
          Tab(
            icon: Icon(Icons.list),
            iconMargin: EdgeInsets.zero,
            child: Text('HISTORIAL'),
          ),
        ],
      ),
    );
  }
}

class _AnnotateTab extends ConsumerWidget {
  const _AnnotateTab({required this.matchId, required this.annotatingTeam});

  final String matchId;
  final CourtTeam annotatingTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(annotationControllerProvider(matchId).notifier);
    final state = ref.watch(annotationControllerProvider(matchId));

    return Column(
      children: <Widget>[
        Expanded(
          child: ActionGrid(
            selectedAction: state.selectedAction?.id,
            onActionSelected: controller.selectAction,
          ),
        ),
        AnnotationStepper(currentStep: state.currentStep),
        if (state.currentStep == 3) _DetailsPanel(matchId: matchId),
        const Divider(color: AppColors.divider, height: 1),
        _PlayerSection(
          team: annotatingTeam,
          selectedPlayerId: state.selectedPlayer?.id,
          onPlayerSelected: controller.selectPlayer,
        ),
      ],
    );
  }
}

class _DetailsPanel extends ConsumerWidget {
  const _DetailsPanel({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(annotationControllerProvider(matchId).notifier);
    final state = ref.watch(annotationControllerProvider(matchId));
    final action = state.selectedAction;
    final player = state.selectedPlayer;
    if (action == null || player == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingM,
        vertical: kSpacingS,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${action.label.replaceAll('\n', ' ')} · #${player.number} '
              '${player.name}',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: controller.cancelSelection,
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: kSpacingS),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: controller.confirmDetails,
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({
    required this.team,
    required this.selectedPlayerId,
    required this.onPlayerSelected,
  });

  final CourtTeam team;
  final String? selectedPlayerId;
  final ValueChanged<RosterPlayer> onPlayerSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: kSpacingS, bottom: kSpacingS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'JUGADOR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: kSpacingXS),
          PlayerCarousel(
            players: team.roster,
            selectedPlayerId: selectedPlayerId,
            onPlayerSelected: onPlayerSelected,
          ),
        ],
      ),
    );
  }
}
