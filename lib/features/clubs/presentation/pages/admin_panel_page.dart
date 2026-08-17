import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import 'clubs_tab.dart';

/// Admin panel shell: four tabs over the club's core entities (Plan.md T-026).
///
/// Reached from the home menu's "Panel de administración" card; the route guard
/// restricts it to SUPER_ADMIN and CLUB_ADMIN.
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver al menú principal',
            onPressed: () => context.go(AppRoutes.home),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              Text(
                'Panel de administración',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Gestiona clubes, equipos, jugadores y partidos',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.info,
            labelColor: AppColors.info,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: <Widget>[
              Tab(icon: Icon(Icons.shield_outlined), text: 'Clubs'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Equipos'),
              Tab(icon: Icon(Icons.person_outline), text: 'Jugadores'),
              Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Partidos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            ClubsTab(),
            _PendingTab(label: 'Equipos'),
            _PendingTab(label: 'Jugadores'),
            _PendingTab(label: 'Partidos'),
          ],
        ),
      ),
    );
  }
}

/// Stand-in for the tabs delivered by the following tasks (T-028 to T-030).
class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.construction_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: kSpacingM),
          Text(
            'La gestión de $label estará disponible en breve.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
