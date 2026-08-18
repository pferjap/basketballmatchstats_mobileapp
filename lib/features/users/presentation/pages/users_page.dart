import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/widgets/admin/admin_search_bar.dart';
import '../../../../core/widgets/admin/pagination_footer.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../clubs/domain/entities/club.dart';
import '../../../clubs/presentation/providers/clubs_providers.dart';
import '../../domain/entities/app_user.dart';
import '../providers/users_admin_provider.dart';
import '../widgets/role_display.dart';
import '../widgets/user_card.dart';

/// Registered-users screen (Plan.md T-034), reachable only by SUPER_ADMIN.
///
/// Lists the most recent sign-ups with search + pagination, and lets the admin
/// elevate a user's role (`PATCH /users/:id/role`) or assign a club
/// (`PATCH /users/:id/club`).
class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final role = await showDialog<UserRole>(
      context: context,
      builder: (context) => _ChangeRoleDialog(user: user),
    );
    if (role == null || role == user.role || !context.mounted) {
      return;
    }
    final error = await ref
        .read(usersAdminControllerProvider.notifier)
        .changeRole(user.id, role);
    if (!context.mounted) {
      return;
    }
    _showResult(
      context,
      error: error,
      success: 'Rol actualizado a ${RoleDisplay.labelOf(role)}.',
    );
  }

  Future<void> _assignClub(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final selection = await showDialog<ClubSelection>(
      context: context,
      builder: (context) => _AssignClubDialog(user: user),
    );
    if (selection == null || !context.mounted) {
      return;
    }
    final error = await ref
        .read(usersAdminControllerProvider.notifier)
        .assignClub(user.id, selection.clubId);
    if (!context.mounted) {
      return;
    }
    _showResult(
      context,
      error: error,
      success: selection.clubId == null
          ? 'Club retirado del usuario.'
          : 'Club asignado al usuario.',
    );
  }

  void _showResult(
    BuildContext context, {
    required String? error,
    required String success,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error != null ? AppColors.error : AppColors.success,
          content: Text(
            error ?? success,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersAdminControllerProvider);
    final controller = ref.read(usersAdminControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Usuarios registrados'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(kSpacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AdminSearchBar(
                hintText: 'Buscar usuario...',
                onSearchChanged: controller.setSearch,
              ),
              const SizedBox(height: kSpacingM),
              Expanded(
                child: _UsersList(
                  state: state,
                  onChangeRole: (user) => _changeRole(context, ref, user),
                  onAssignClub: (user) => _assignClub(context, ref, user),
                ),
              ),
              PaginationFooter(
                page: state.page,
                limit: kUsersPageSize,
                total: state.total,
                itemNoun: 'usuarios',
                onPageSelected: controller.goToPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.state,
    required this.onChangeRole,
    required this.onAssignClub,
  });

  final UsersAdminState state;
  final ValueChanged<AppUser> onChangeRole;
  final ValueChanged<AppUser> onAssignClub;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = state.errorMessage;
    if (error != null) {
      return _Message(icon: Icons.wifi_off, text: error);
    }

    if (state.users.isEmpty) {
      return const _Message(
        icon: Icons.people_outline,
        text: 'Todavía no hay usuarios registrados.',
      );
    }

    return ListView.builder(
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return UserCard(
          user: user,
          onChangeRole: () => onChangeRole(user),
          onAssignClub: () => onAssignClub(user),
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

/// Dialog to change a user's role, with an in-context warning about the scope
/// of the change before it is applied.
class _ChangeRoleDialog extends StatefulWidget {
  const _ChangeRoleDialog({required this.user});

  final AppUser user;

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  late UserRole? _selected =
      RoleDisplay.assignableRoles.contains(widget.user.role)
          ? widget.user.role
          : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Cambiar rol',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.user.fullName.isEmpty
                ? widget.user.email
                : widget.user.fullName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpacingM),
          DropdownButtonFormField<UserRole>(
            initialValue: _selected,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Nuevo rol'),
            items: <DropdownMenuItem<UserRole>>[
              for (final role in RoleDisplay.assignableRoles)
                DropdownMenuItem<UserRole>(
                  value: role,
                  child: Text(RoleDisplay.labelOf(role)),
                ),
            ],
            onChanged: (value) => setState(() => _selected = value),
          ),
          const SizedBox(height: kSpacingM),
          const Text(
            'Cambiar el rol modifica los permisos del usuario en toda la '
            'plataforma. Revisa la selección antes de confirmar.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Cambiar rol'),
        ),
      ],
    );
  }
}

/// Result of the assign-club dialog. A `null` [clubId] means "Sin club".
class ClubSelection {
  const ClubSelection(this.clubId);

  final String? clubId;
}

/// Dialog to assign (or clear) a user's club. Loads the club list on open.
class _AssignClubDialog extends ConsumerStatefulWidget {
  const _AssignClubDialog({required this.user});

  final AppUser user;

  @override
  ConsumerState<_AssignClubDialog> createState() => _AssignClubDialogState();
}

class _AssignClubDialogState extends ConsumerState<_AssignClubDialog> {
  late Future<List<Club>> _clubsFuture;
  String? _selectedClubId;

  @override
  void initState() {
    super.initState();
    _selectedClubId = widget.user.clubId;
    _clubsFuture = _loadClubs();
  }

  Future<List<Club>> _loadClubs() async {
    final result =
        await ref.read(clubRepositoryProvider).getClubs(page: 1, limit: 100);
    return result.items;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Asignar club',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: FutureBuilder<List<Club>>(
        future: _clubsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Text(
              'No se pudieron cargar los clubes.',
              style: TextStyle(color: AppColors.textSecondary),
            );
          }
          final clubs = snapshot.data ?? const <Club>[];
          final knownIds = clubs.map((c) => c.id).toSet();
          final value =
              knownIds.contains(_selectedClubId) ? _selectedClubId : null;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<String?>(
                initialValue: value,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Club'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    child: Text('Sin club'),
                  ),
                  for (final club in clubs)
                    DropdownMenuItem<String?>(
                      value: club.id,
                      child: Text(club.name),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedClubId = v),
              ),
            ],
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(ClubSelection(_selectedClubId)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
