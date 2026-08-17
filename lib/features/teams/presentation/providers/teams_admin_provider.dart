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
class TeamsAdminController extends AutoDisposeNotifier<TeamsAdminState> {
  TeamRepository get _repository => ref.read(teamRepositoryProvider);

  bool _disposed = false;

  @override
  TeamsAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(() => loadTeams());
    return const TeamsAdminState();
  }

  /// Loads [page] applying the current (or newly supplied) [search] filter.
  Future<void> loadTeams({int page = 1, String? search}) async {
    final query = search ?? state.search;
    _setState(state.copyWith(isLoading: true, page: page, search: query));
    try {
      final result = await _repository.getTeams(
        page: page,
        limit: kTeamsPageSize,
        search: query.isEmpty ? null : query,
      );
      _setState(
        TeamsAdminState(
          teams: result.items,
          page: result.page ?? page,
          total: result.total ?? result.items.length,
          search: query,
          isLoading: false,
        ),
      );
    } on AppException catch (error) {
      _setState(
        TeamsAdminState(
          page: page,
          search: query,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Applies a new search term, returning to the first page.
  Future<void> setSearch(String query) => loadTeams(search: query);

  /// Jumps to [page] keeping the active filter.
  Future<void> goToPage(int page) => loadTeams(page: page);

  /// Reloads the current page.
  Future<void> refresh() => loadTeams(page: state.page);

  /// Deletes [teamId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deleteTeam(String teamId) async {
    try {
      await _repository.deleteTeam(teamId);
    } on AppException catch (error) {
      return error.message;
    }
    // Stepping back a page avoids landing on an empty tail page after the
    // last item of the current page is removed.
    final isLastItemOnPage = state.teams.length == 1 && state.page > 1;
    await loadTeams(page: isLastItemOnPage ? state.page - 1 : state.page);
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
