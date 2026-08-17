import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_search_bar.dart';
import '../../../../core/widgets/admin/admin_section_header.dart';
import '../../../../core/widgets/admin/confirm_delete_dialog.dart';
import '../../../../core/widgets/admin/pagination_footer.dart';
import '../../domain/entities/team.dart';
import '../providers/teams_admin_provider.dart';
import '../widgets/team_card.dart';
import 'team_form_page.dart';

/// Equipos tab of the admin panel: search, paginated list, create/edit/delete
/// (Plan.md T-028).
class TeamsTab extends ConsumerWidget {
  const TeamsTab({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Team? team,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => TeamFormPage(team: team),
      ),
    );
    if (saved ?? false) {
      await ref.read(teamsAdminControllerProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar equipo',
      message:
          '¿Seguro que quieres eliminar "${team.name}"? '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmed) {
      return;
    }
    final error = await ref
        .read(teamsAdminControllerProvider.notifier)
        .deleteTeam(team.id);
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
    final state = ref.watch(teamsAdminControllerProvider);
    final controller = ref.read(teamsAdminControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(kSpacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminSectionHeader(
            title: 'Equipos',
            createLabel: 'Crear equipo',
            onCreate: () => _openForm(context, ref),
          ),
          const SizedBox(height: kSpacingM),
          AdminSearchBar(
            hintText: 'Buscar equipo...',
            onSearchChanged: controller.setSearch,
            onFiltersPressed: () {},
          ),
          const SizedBox(height: kSpacingM),
          Expanded(
            child: _TeamsList(
              state: state,
              onEdit: (Team team) => _openForm(context, ref, team: team),
              onDelete: (Team team) => _confirmDelete(context, ref, team),
            ),
          ),
          PaginationFooter(
            page: state.page,
            limit: kTeamsPageSize,
            total: state.total,
            itemNoun: 'equipos',
            onPageSelected: controller.goToPage,
          ),
        ],
      ),
    );
  }
}

class _TeamsList extends StatelessWidget {
  const _TeamsList({
    required this.state,
    required this.onEdit,
    required this.onDelete,
  });

  final TeamsAdminState state;
  final ValueChanged<Team> onEdit;
  final ValueChanged<Team> onDelete;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = state.errorMessage;
    if (error != null) {
      return _Message(icon: Icons.wifi_off, text: error);
    }

    if (state.teams.isEmpty) {
      return const _Message(
        icon: Icons.groups_outlined,
        text: 'No hay equipos que mostrar.',
      );
    }

    return ListView.builder(
      itemCount: state.teams.length,
      itemBuilder: (BuildContext context, int index) {
        final team = state.teams[index];
        return TeamCard(
          team: team,
          onEdit: () => onEdit(team),
          onDelete: () => onDelete(team),
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
