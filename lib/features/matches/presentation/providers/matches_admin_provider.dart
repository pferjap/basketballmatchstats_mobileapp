import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import 'match_providers.dart';

/// Page size for the admin matches list.
const int kMatchesPageSize = 7;

/// Immutable state for the admin panel's Partidos tab (Plan.md T-030).
@immutable
class MatchesAdminState {
  const MatchesAdminState({
    this.matches = const <Match>[],
    this.page = 1,
    this.total = 0,
    this.search = '',
    this.isLoading = true,
    this.errorMessage,
  });

  /// Matches on the current page, after the client-side search filter.
  final List<Match> matches;

  /// Current 1-based page.
  final int page;

  /// Total matches across all pages, as reported by the backend.
  final int total;

  /// Active free-text filter.
  final String search;

  /// Whether a page load is in flight.
  final bool isLoading;

  /// User-facing error from the last load, if any.
  final String? errorMessage;

  MatchesAdminState copyWith({
    List<Match>? matches,
    int? page,
    int? total,
    String? search,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MatchesAdminState(
      matches: matches ?? this.matches,
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
      other is MatchesAdminState &&
          listEquals(other.matches, matches) &&
          other.page == page &&
          other.total == total &&
          other.search == search &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(matches),
    page,
    total,
    search,
    isLoading,
    errorMessage,
  );
}

/// Loads, paginates and deletes matches for the admin panel.
class MatchesAdminController extends AutoDisposeNotifier<MatchesAdminState> {
  MatchRepository get _repository => ref.read(matchRepositoryProvider);

  bool _disposed = false;

  @override
  MatchesAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(() => loadMatches());
    return const MatchesAdminState();
  }

  /// Loads [page] applying the current (or newly supplied) [search] filter.
  ///
  /// The list endpoint takes no search parameter, so the filter is applied
  /// client-side over the loaded page.
  Future<void> loadMatches({int page = 1, String? search}) async {
    final query = search ?? state.search;
    _setState(state.copyWith(isLoading: true, page: page, search: query));
    try {
      final result = await _repository.getMatches(
        page: page,
        limit: kMatchesPageSize,
      );
      _setState(
        MatchesAdminState(
          matches: _filter(result.items, query),
          page: result.page ?? page,
          total: result.total ?? result.items.length,
          search: query,
          isLoading: false,
        ),
      );
    } on AppException catch (error) {
      _setState(
        MatchesAdminState(
          page: page,
          search: query,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  List<Match> _filter(List<Match> matches, String query) {
    if (query.isEmpty) {
      return matches;
    }
    final needle = query.toLowerCase();
    return matches
        .where(
          (Match m) =>
              m.homeTeamId.toLowerCase().contains(needle) ||
              m.awayTeamId.toLowerCase().contains(needle) ||
              (m.venue?.toLowerCase().contains(needle) ?? false),
        )
        .toList(growable: false);
  }

  /// Applies a new search term, returning to the first page.
  Future<void> setSearch(String query) => loadMatches(search: query);

  /// Jumps to [page] keeping the active filter.
  Future<void> goToPage(int page) => loadMatches(page: page);

  /// Reloads the current page.
  Future<void> refresh() => loadMatches(page: state.page);

  /// Deletes [matchId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deleteMatch(String matchId) async {
    try {
      await _repository.deleteMatch(matchId);
    } on AppException catch (error) {
      return error.message;
    }
    // Stepping back a page avoids landing on an empty tail page after the
    // last item of the current page is removed.
    final isLastItemOnPage = state.matches.length == 1 && state.page > 1;
    await loadMatches(page: isLastItemOnPage ? state.page - 1 : state.page);
    return null;
  }

  void _setState(MatchesAdminState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }
}

/// Admin panel Partidos tab controller.
final matchesAdminControllerProvider =
    AutoDisposeNotifierProvider<MatchesAdminController, MatchesAdminState>(
      MatchesAdminController.new,
    );
