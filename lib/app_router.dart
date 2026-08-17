import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/placeholder_page.dart';
import 'features/auth/domain/entities/user.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/main_menu_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/matches/presentation/models/court_view_args.dart';
import 'features/matches/presentation/pages/court_view_page.dart';
import 'features/matches/presentation/pages/match_list_page.dart';
import 'features/matches/presentation/pages/match_live_page.dart';
import 'features/matches/presentation/providers/match_list_provider.dart';

/// Route paths used across the app. Centralized so navigation calls and guards
/// never rely on stringly-typed literals scattered through the codebase.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String matchLive = '/matches/:id/live';
  static const String matchAnnotate = '/matches/:id/annotate';

  /// Home-menu entry points (match selection screens land here until the
  /// Matches feature — Phase 4+ — provides the real flows).
  static const String annotateEntry = '/matches/annotate';
  static const String spectateEntry = '/matches/spectate';
  static const String statistics = '/statistics';
  static const String myTeam = '/team';
  static const String adminPanel = '/admin';

  static const String teams = '/teams';
  static const String players = '/players';
  static const String settings = '/settings';
}

/// Roles allowed to open the live-annotation (Court View) screen (§13).
const Set<UserRole> _annotationRoles = <UserRole>{
  UserRole.statistician,
  UserRole.clubAdmin,
};

/// Bridges Riverpod [authStateProvider] changes to go_router's
/// `refreshListenable`, so the global redirect re-runs whenever the session
/// status changes (login, logout, expiry).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        if (previous?.status != next.status) {
          notifyListeners();
        }
      },
    );
  }
}

/// The app's [GoRouter], with global auth and role guards (Plan.md T-012,
/// Agent_Mobile.md §9.3/§13).
///
/// * Unauthenticated users are redirected to `/login` for any protected route.
/// * Authenticated users on `/login` are sent to `/`.
/// * `/matches/:id/annotate` additionally requires a STATISTICIAN or CLUB_ADMIN
///   role; other roles are bounced back to `/`.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loggedIn = auth.isAuthenticated;
      final loggingIn = state.matchedLocation == AppRoutes.login;

      if (!loggedIn) {
        return loggingIn ? null : AppRoutes.login;
      }

      if (loggingIn) {
        return AppRoutes.home;
      }

      if (state.fullPath == AppRoutes.matchAnnotate) {
        final role = ref.read(currentUserProvider)?.role;
        if (role == null || !_annotationRoles.contains(role)) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainMenuPage(),
      ),
      GoRoute(
        path: AppRoutes.annotateEntry,
        name: 'annotateEntry',
        builder: (context, state) =>
            const MatchListPage(mode: MatchListMode.annotate),
      ),
      GoRoute(
        path: AppRoutes.spectateEntry,
        name: 'spectateEntry',
        builder: (context, state) =>
            const MatchListPage(mode: MatchListMode.spectate),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        builder: (context, state) =>
            const PlaceholderPage(title: 'Estadísticas y resultados'),
      ),
      GoRoute(
        path: AppRoutes.myTeam,
        name: 'myTeam',
        builder: (context, state) =>
            const PlaceholderPage(title: 'Administrar mi equipo'),
      ),
      GoRoute(
        path: AppRoutes.adminPanel,
        name: 'adminPanel',
        builder: (context, state) =>
            const PlaceholderPage(title: 'Panel de administración'),
      ),
      GoRoute(
        path: AppRoutes.matchLive,
        name: 'matchLive',
        builder: (context, state) {
          final args = state.extra;
          return MatchLivePage(
            matchId: state.pathParameters['id']!,
            args: args is LiveMatchArgs ? args : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.matchAnnotate,
        name: 'matchAnnotate',
        builder: (context, state) {
          final args = state.extra;
          return CourtViewPage(
            matchId: state.pathParameters['id']!,
            args: args is CourtViewArgs ? args : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.teams,
        name: 'teams',
        builder: (context, state) => const PlaceholderPage(title: 'Equipos'),
      ),
      GoRoute(
        path: AppRoutes.players,
        name: 'players',
        builder: (context, state) => const PlaceholderPage(title: 'Jugadores'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const PlaceholderPage(title: 'Ajustes'),
      ),
    ],
    errorBuilder: (context, state) => PlaceholderPage(
      title: 'Ruta no encontrada',
      subtitle: state.uri.toString(),
    ),
  );
});

/// Exposed for diagnostics/logging in debug builds.
@visibleForTesting
Set<UserRole> get annotationRoles => _annotationRoles;
