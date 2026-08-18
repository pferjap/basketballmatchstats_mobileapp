import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../models/court_view_args.dart';
import '../providers/annotation_state_provider.dart';
import '../widgets/action_grid.dart';
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Volver',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: PeriodSelector(
          period: state.currentPeriod,
          onChanged: controller.setPeriod,
        ),
        centerTitle: true,
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
            clockSeconds: state.resumeClockSeconds ??
                _args.periodDurationSeconds,
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
                  home: _args.home,
                  away: _args.away,
                  annotatingTeamId: state.annotatingTeamId,
                  onTeamChanged: controller.setAnnotatingTeam,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingM,
            vertical: kSpacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton.icon(
                onPressed: state.events.isNotEmpty ? controller.undoLast : null,
                icon: const Icon(Icons.undo, color: AppColors.primary),
                label: const Text(
                  'DESHACER ÚLTIMA ACCIÓN',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _TeamToggle extends StatelessWidget {
  const _TeamToggle({
    required this.home,
    required this.away,
    required this.annotatingTeamId,
    required this.onTeamChanged,
  });

  final CourtTeam home;
  final CourtTeam away;
  final String annotatingTeamId;
  final ValueChanged<String> onTeamChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingM, vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ToggleChip(
              label: home.name.toUpperCase(),
              selected: annotatingTeamId == home.id,
              onTap: () => onTeamChanged(home.id),
            ),
          ),
          const SizedBox(width: kSpacingS),
          Expanded(
            child: _ToggleChip(
              label: away.name.toUpperCase(),
              selected: annotatingTeamId == away.id,
              onTap: () => onTeamChanged(away.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AnnotateTab extends ConsumerWidget {
  const _AnnotateTab({
    required this.matchId,
    required this.annotatingTeam,
    required this.home,
    required this.away,
    required this.annotatingTeamId,
    required this.onTeamChanged,
  });

  final String matchId;
  final CourtTeam annotatingTeam;
  final CourtTeam home;
  final CourtTeam away;
  final String annotatingTeamId;
  final ValueChanged<String> onTeamChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(annotationControllerProvider(matchId).notifier);
    final state = ref.watch(annotationControllerProvider(matchId));

    return Column(
      children: <Widget>[
        _TeamToggle(
          home: home,
          away: away,
          annotatingTeamId: annotatingTeamId,
          onTeamChanged: onTeamChanged,
        ),
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
