import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import 'teams_providers.dart';

/// Page size for the admin teams list.
const int kTeamsPageSize = 7;

/// Immutable state for the admin panel's Equipos tab (Plan.md T-028).
@immutable
class TeamsAdminState {
  const TeamsAdminState({
    this.teams = const <Team>[],
    this.page = 1,
    this.total = 0,
    this.search = '',
    this.isLoading = true,
    this.errorMessage,
  });

  /// Teams on the current page.
  final List<Team> teams;

  /// Current 1-based page.
  final int page;

  /// Total teams across all pages, as reported by the backend.
  final int total;

  /// Active free-text filter.
  final String search;

  /// Whether a page load is in flight.
  final bool isLoading;

  /// User-facing error from the last load, if any.
  final String? errorMessage;

  TeamsAdminState copyWith({
    List<Team>? teams,
    int? page,
    int? total,
    String? search,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TeamsAdminState(
      teams: teams ?? this.teams,
      page: page ?? this.page,
      total: total ?? this.total,
      search: search ?? this.search,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamsAdminState &&
          listEquals(other.teams, teams) &&
          other.page == page &&
          other.total == total &&
          other.search == search &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(teams),
    page,
    total,
    search,
    isLoading,
    errorMessage,
  );
}

/// Loads, filters, paginates and deletes teams for the admin panel.
///
/// The `GET /teams` endpoint exposes no text-search parameter, so the whole
/// list is fetched once and both filtering and pagination are performed
/// client-side.
class TeamsAdminController extends AutoDisposeNotifier<TeamsAdminState> {
  TeamRepository get _repository => ref.read(teamRepositoryProvider);

  bool _disposed = false;

  /// Every team fetched from the API, before the client-side search filter.
  List<Team> _all = const <Team>[];

  @override
  TeamsAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(loadTeams);
    return const TeamsAdminState();
  }

  /// Fetches every team and shows the first page of the current filter.
  Future<void> loadTeams() async {
    _setState(state.copyWith(isLoading: true));
    try {
      _all = await _fetchAll();
      _apply(page: 1);
    } on AppException catch (error) {
      _setState(
        TeamsAdminState(
          search: state.search,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Pulls all teams by walking the paginated endpoint at the maximum limit.
  Future<List<Team>> _fetchAll() async {
    final teams = <Team>[];
    var page = 1;
    while (true) {
      final result = await _repository.getTeams(page: page, limit: 100);
      teams.addAll(result.items);
      final total = result.total ?? teams.length;
      if (result.items.isEmpty || teams.length >= total) {
        break;
      }
      page++;
    }
    return teams;
  }

  /// Recomputes the visible page from [_all] for [page] and [search].
  void _apply({required int page, String? search}) {
    final query = search ?? state.search;
    final filtered = _filter(query);
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length / kTeamsPageSize).ceil();
    final safePage = page.clamp(1, pageCount);
    final start = (safePage - 1) * kTeamsPageSize;
    _setState(
      TeamsAdminState(
        teams: filtered
            .skip(start)
            .take(kTeamsPageSize)
            .toList(growable: false),
        page: safePage,
        total: filtered.length,
        search: query,
        isLoading: false,
      ),
    );
  }

  List<Team> _filter(String query) {
    if (query.isEmpty) {
      return _all;
    }
    final needle = query.toLowerCase();
    return _all
        .where(
          (Team team) =>
              team.name.toLowerCase().contains(needle) ||
              (team.clubName?.toLowerCase().contains(needle) ?? false) ||
              (team.category?.toLowerCase().contains(needle) ?? false),
        )
        .toList(growable: false);
  }

  /// Applies a new search term, returning to the first page. No network call.
  Future<void> setSearch(String query) async => _apply(page: 1, search: query);

  /// Jumps to [page] over the filtered list. No network call.
  Future<void> goToPage(int page) async => _apply(page: page);

  /// Reloads the full list from the API.
  Future<void> refresh() => loadTeams();

  /// Deletes [teamId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deleteTeam(String teamId) async {
    try {
      await _repository.deleteTeam(teamId);
      _all = await _fetchAll();
    } on AppException catch (error) {
      return error.message;
    }
    // _apply clamps the page, so removing the last item of the tail page lands
    // on the new last page instead of an empty one.
    _apply(page: state.page);
    return null;
  }

  void _setState(TeamsAdminState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }
}

/// Admin panel Equipos tab controller.
final teamsAdminControllerProvider =
    AutoDisposeNotifierProvider<TeamsAdminController, TeamsAdminState>(
      TeamsAdminController.new,
    );
