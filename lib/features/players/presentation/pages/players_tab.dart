import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_search_bar.dart';
import '../../../../core/widgets/admin/admin_section_header.dart';
import '../../../../core/widgets/admin/confirm_delete_dialog.dart';
import '../../../../core/widgets/admin/pagination_footer.dart';
import '../../domain/entities/player.dart';
import '../providers/players_admin_provider.dart';
import '../widgets/player_card.dart';
import 'player_form_page.dart';

/// Jugadores tab of the admin panel: search, paginated list,
/// create/edit/delete (Plan.md T-029).
class PlayersTab extends ConsumerWidget {
  const PlayersTab({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Player? player,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => PlayerFormPage(player: player),
      ),
    );
    if (saved ?? false) {
      await ref.read(playersAdminControllerProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar jugador',
      message:
          '¿Seguro que quieres eliminar a "${player.fullName}"? '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmed) {
      return;
    }
    final error = await ref
        .read(playersAdminControllerProvider.notifier)
        .deletePlayer(player.id);
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
    final state = ref.watch(playersAdminControllerProvider);
    final controller = ref.read(playersAdminControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(kSpacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminSectionHeader(
            title: 'Jugadores',
            createLabel: 'Crear jugador',
            onCreate: () => _openForm(context, ref),
          ),
          const SizedBox(height: kSpacingM),
          AdminSearchBar(
            hintText: 'Buscar jugador...',
            onSearchChanged: controller.setSearch,
            onFiltersPressed: () {},
          ),
          const SizedBox(height: kSpacingM),
          Expanded(
            child: _PlayersList(
              state: state,
              onEdit: (Player player) =>
                  _openForm(context, ref, player: player),
              onDelete: (Player player) => _confirmDelete(context, ref, player),
            ),
          ),
          PaginationFooter(
            page: state.page,
            limit: kPlayersPageSize,
            total: state.total,
            itemNoun: 'jugadores',
            onPageSelected: controller.goToPage,
          ),
        ],
      ),
    );
  }
}

class _PlayersList extends StatelessWidget {
  const _PlayersList({
    required this.state,
    required this.onEdit,
    required this.onDelete,
  });

  final PlayersAdminState state;
  final ValueChanged<Player> onEdit;
  final ValueChanged<Player> onDelete;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = state.errorMessage;
    if (error != null) {
      return _Message(icon: Icons.wifi_off, text: error);
    }

    if (state.players.isEmpty) {
      return const _Message(
        icon: Icons.person_outline,
        text: 'No hay jugadores que mostrar.',
      );
    }

    return ListView.builder(
      itemCount: state.players.length,
      itemBuilder: (BuildContext context, int index) {
        final player = state.players[index];
        return PlayerCard(
          player: player,
          onEdit: () => onEdit(player),
          onDelete: () => onDelete(player),
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
