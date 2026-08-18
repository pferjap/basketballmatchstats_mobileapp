import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_search_bar.dart';
import '../../../../core/widgets/admin/admin_section_header.dart';
import '../../../../core/widgets/admin/confirm_delete_dialog.dart';
import '../../../../core/widgets/admin/pagination_footer.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../providers/match_form_provider.dart';
import '../providers/matches_admin_provider.dart';
import '../widgets/match_admin_card.dart';
import 'match_form_page.dart';

/// Partidos tab of the admin panel: search, paginated list,
/// create/edit/delete (Plan.md T-030).
class MatchesTab extends ConsumerWidget {
  const MatchesTab({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Match? match,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => MatchFormPage(match: match),
      ),
    );
    if (saved ?? false) {
      await ref.read(matchesAdminControllerProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Match match,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar partido',
      message:
          '¿Seguro que quieres eliminar este partido? '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmed) {
      return;
    }
    final error = await ref
        .read(matchesAdminControllerProvider.notifier)
        .deleteMatch(match.id);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesAdminControllerProvider);
    final controller = ref.read(matchesAdminControllerProvider.notifier);
    // Team names are resolved from the teams list so cards can show names
    // instead of the raw ids the match payload carries.
    final teamNames = ref
        .watch(matchFormTeamsProvider)
        .maybeWhen(
          data: (List<Team> teams) => <String, String>{
            for (final Team team in teams) team.id: team.name,
          },
          orElse: () => const <String, String>{},
        );

    return Padding(
      padding: const EdgeInsets.all(kSpacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminSectionHeader(
            title: 'Partidos',
            createLabel: 'Crear partido',
            onCreate: () => _openForm(context, ref),
          ),
          const SizedBox(height: kSpacingM),
          AdminSearchBar(
            hintText: 'Buscar partido...',
            onSearchChanged: controller.setSearch,
          ),
          const SizedBox(height: kSpacingM),
          Expanded(
            child: _MatchesList(
              state: state,
              teamNames: teamNames,
              onEdit: (Match match) => _openForm(context, ref, match: match),
              onDelete: (Match match) => _confirmDelete(context, ref, match),
            ),
          ),
          PaginationFooter(
            page: state.page,
            limit: kMatchesPageSize,
            total: state.total,
            itemNoun: 'partidos',
            onPageSelected: controller.goToPage,
          ),
        ],
      ),
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({
    required this.state,
    required this.teamNames,
    required this.onEdit,
    required this.onDelete,
  });

  final MatchesAdminState state;
  final Map<String, String> teamNames;
  final ValueChanged<Match> onEdit;
  final ValueChanged<Match> onDelete;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = state.errorMessage;
    if (error != null) {
      return _Message(icon: Icons.wifi_off, text: error);
    }

    if (state.matches.isEmpty) {
      return const _Message(
        icon: Icons.event_busy,
        text: 'No hay partidos que mostrar.',
      );
    }

    return ListView.builder(
      itemCount: state.matches.length,
      itemBuilder: (BuildContext context, int index) {
        final match = state.matches[index];
        return MatchAdminCard(
          match: match,
          homeTeamName: teamNames[match.homeTeamId] ?? match.homeTeamId,
          awayTeamName: teamNames[match.awayTeamId] ?? match.awayTeamId,
          onEdit: () => onEdit(match),
          onDelete: () => onDelete(match),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: kSpacingM),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
