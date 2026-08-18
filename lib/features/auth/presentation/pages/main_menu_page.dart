import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_providers.dart';
import '../widgets/menu_card.dart';
import '../widgets/user_header.dart';

/// Home / main menu (Plan.md T-013, design: `docs/images/main_menu_screen.png`).
///
/// Shows the branded header, the "¿Qué quieres hacer?" section and the action
/// cards grouped into "Partido en directo" and "Administración". Each card is
/// only rendered when the current user's role is allowed to use it, so the menu
/// adapts to VIEWER / STATISTICIAN / COACH / CLUB_ADMIN / SUPER_ADMIN sessions.
class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider)?.role;
    if (role == null) {
      // The route is auth-guarded, so this only happens transiently on logout.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final liveCards = _menuItems
        .where((i) => i.group == _MenuGroup.liveMatch && i.isVisibleTo(role))
        .toList();
    final adminCards = _menuItems
        .where(
          (i) => i.group == _MenuGroup.administration && i.isVisibleTo(role),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            kSpacingL,
            kSpacingL,
            kSpacingL,
            kSpacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(child: UserHeader()),
                  _LogoutButton(),
                ],
              ),
              const SizedBox(height: kSpacingL),
              const Center(child: _BrandLogo()),
              const SizedBox(height: kSpacingXL),
              const Text(
                '¿Qué quieres hacer?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: kSpacingL),
              if (liveCards.isNotEmpty)
                _MenuSection(label: 'PARTIDO EN DIRECTO', items: liveCards),
              if (liveCards.isNotEmpty && adminCards.isNotEmpty) ...[
                const SizedBox(height: kSpacingL),
                const Divider(color: AppColors.divider),
                const SizedBox(height: kSpacingL),
              ],
              if (adminCards.isNotEmpty)
                _MenuSection(label: 'ADMINISTRACIÓN', items: adminCards),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-only sign-out action in the header's top-right corner.
///
/// Clearing the session makes the router's redirect send the user to `/login`;
/// navigating explicitly avoids leaving the menu on screen while the refresh
/// listenable propagates.
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      color: AppColors.textSecondary,
      iconSize: 26,
      tooltip: 'Cerrar sesión',
      onPressed: () async {
        await ref.read(authStateProvider.notifier).logout();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      },
    );
  }
}

/// The two visual groupings on the menu.
enum _MenuGroup { liveMatch, administration }

/// Declarative description of one action card and the roles allowed to see it.
class _MenuItem {
  const _MenuItem({
    required this.group,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.route,
    required this.allowedRoles,
  });

  final _MenuGroup group;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String route;
  final Set<UserRole> allowedRoles;

  bool isVisibleTo(UserRole role) => allowedRoles.contains(role);
}

/// Every role can see these two "spectator/base" actions.
const Set<UserRole> _allRoles = <UserRole>{
  UserRole.viewer,
  UserRole.statistician,
  UserRole.coach,
  UserRole.clubAdmin,
  UserRole.superAdmin,
};

/// The menu's cards, in display order (Plan.md T-013 role matrix).
const List<_MenuItem> _menuItems = <_MenuItem>[
  _MenuItem(
    group: _MenuGroup.liveMatch,
    icon: Icons.assignment,
    title: 'Tomar anotaciones',
    subtitle: 'Registra las acciones en directo de un partido',
    accent: AppColors.primary,
    route: AppRoutes.annotateEntry,
    allowedRoles: <UserRole>{
      UserRole.statistician,
      UserRole.clubAdmin,
      UserRole.superAdmin,
    },
  ),
  _MenuItem(
    group: _MenuGroup.liveMatch,
    icon: Icons.sensors,
    title: 'Asistir a un partido',
    subtitle: 'Sigue el partido en directo como espectador',
    accent: AppColors.info,
    route: AppRoutes.spectateEntry,
    allowedRoles: _allRoles,
  ),
  _MenuItem(
    group: _MenuGroup.administration,
    icon: Icons.settings,
    title: 'Panel de administración',
    subtitle: 'Administra la plataforma, usuarios, equipos y competiciones',
    accent: AppColors.accentGold,
    route: AppRoutes.adminPanel,
    allowedRoles: <UserRole>{UserRole.superAdmin},
  ),
  _MenuItem(
    group: _MenuGroup.administration,
    icon: Icons.manage_accounts,
    title: 'Usuarios registrados',
    subtitle: 'Consulta las altas recientes y ajusta sus permisos',
    accent: AppColors.info,
    route: AppRoutes.adminUsers,
    allowedRoles: <UserRole>{UserRole.superAdmin},
  ),
];

/// A labelled group of menu cards.
class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.label, required this.items});

  final String label;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: kSpacingM),
        for (final item in items) ...[
          MenuCard(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            accent: item.accent,
            onTap: () => context.go(item.route),
          ),
          if (item != items.last) const SizedBox(height: kSpacingM),
        ],
      ],
    );
  }
}

/// Central BasketStats wordmark + tagline shown under the header.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sports_basketball, size: 76, color: AppColors.primary),
        const SizedBox(height: kSpacingS),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'BASKET',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'STATS',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: kSpacingXS),
        const Text(
          'ANOTA · SINCRONIZA · COMPITE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
