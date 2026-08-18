import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_search_bar.dart';
import '../../../../core/widgets/admin/admin_section_header.dart';
import '../../../../core/widgets/admin/confirm_delete_dialog.dart';
import '../../../../core/widgets/admin/pagination_footer.dart';
import '../../domain/entities/club.dart';
import '../providers/clubs_admin_provider.dart';
import '../widgets/club_card.dart';
import 'club_form_page.dart';

/// Clubs tab of the admin panel: search, paginated list, create/edit/delete
/// (Plan.md T-026).
class ClubsTab extends ConsumerWidget {
  const ClubsTab({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Club? club,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ClubFormPage(club: club),
      ),
    );
    if (saved ?? false) {
      await ref.read(clubsAdminControllerProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Club club,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar club',
      message:
          '¿Seguro que quieres eliminar "${club.name}"? '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmed) {
      return;
    }
    final error = await ref
        .read(clubsAdminControllerProvider.notifier)
        .deleteClub(club.id);
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
    final state = ref.watch(clubsAdminControllerProvider);
    final controller = ref.read(clubsAdminControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(kSpacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AdminSectionHeader(
            title: 'Clubs',
            createLabel: 'Crear club',
            onCreate: () => _openForm(context, ref),
          ),
          const SizedBox(height: kSpacingM),
          AdminSearchBar(
            hintText: 'Buscar club...',
            onSearchChanged: controller.setSearch,
          ),
          const SizedBox(height: kSpacingM),
          Expanded(
            child: _ClubsList(
              state: state,
              onEdit: (Club club) => _openForm(context, ref, club: club),
              onDelete: (Club club) => _confirmDelete(context, ref, club),
            ),
          ),
          PaginationFooter(
            page: state.page,
            limit: kClubsPageSize,
            total: state.total,
            itemNoun: 'clubes',
            onPageSelected: controller.goToPage,
          ),
        ],
      ),
    );
  }
}

class _ClubsList extends StatelessWidget {
  const _ClubsList({
    required this.state,
    required this.onEdit,
    required this.onDelete,
  });

  final ClubsAdminState state;
  final ValueChanged<Club> onEdit;
  final ValueChanged<Club> onDelete;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = state.errorMessage;
    if (error != null) {
      return _Message(icon: Icons.wifi_off, text: error);
    }

    if (state.clubs.isEmpty) {
      return const _Message(
        icon: Icons.shield_outlined,
        text: 'No hay clubes que mostrar.',
      );
    }

    return ListView.builder(
      itemCount: state.clubs.length,
      itemBuilder: (BuildContext context, int index) {
        final club = state.clubs[index];
        return ClubCard(
          club: club,
          onEdit: () => onEdit(club),
          onDelete: () => onDelete(club),
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
