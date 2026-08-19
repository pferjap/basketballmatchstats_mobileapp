import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import 'match_form_provider.dart';
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
///
/// The `GET /matches` endpoint exposes no text-search parameter, so the whole
/// list is fetched once and both filtering and pagination are performed
/// client-side. Matches are matched by venue and by their home/away team
/// names, resolved from [matchFormTeamsProvider].
class MatchesAdminController extends AutoDisposeNotifier<MatchesAdminState> {
  MatchRepository get _repository => ref.read(matchRepositoryProvider);

  bool _disposed = false;

  /// Every match fetched from the API, before the client-side search filter.
  List<Match> _all = const <Match>[];

  @override
  MatchesAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(loadMatches);
    return const MatchesAdminState();
  }

  /// Fetches every match and shows the first page of the current filter.
  Future<void> loadMatches() async {
    _setState(state.copyWith(isLoading: true));
    try {
      _all = await _fetchAll();
      _apply(page: 1);
    } on AppException catch (error) {
      _setState(
        MatchesAdminState(
          search: state.search,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Pulls all matches by walking the paginated endpoint at the maximum limit.
  Future<List<Match>> _fetchAll() async {
    final matches = <Match>[];
    var page = 1;
    while (true) {
      final result = await _repository.getMatches(page: page, limit: 100);
      matches.addAll(result.items);
      final total = result.total ?? matches.length;
      if (result.items.isEmpty || matches.length >= total) {
        break;
      }
      page++;
    }
    return matches;
  }

  /// Recomputes the visible page from [_all] for [page] and [search].
  void _apply({required int page, String? search}) {
    final query = search ?? state.search;
    final filtered = _filter(query);
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length / kMatchesPageSize).ceil();
    final safePage = page.clamp(1, pageCount);
    final start = (safePage - 1) * kMatchesPageSize;
    _setState(
      MatchesAdminState(
        matches: filtered
            .skip(start)
            .take(kMatchesPageSize)
            .toList(growable: false),
        page: safePage,
        total: filtered.length,
        search: query,
        isLoading: false,
      ),
    );
  }

  List<Match> _filter(String query) {
    if (query.isEmpty) {
      return _all;
    }
    final needle = query.toLowerCase();
    final teamNames = <String, String>{
      for (final Team team
          in ref.read(matchFormTeamsProvider).valueOrNull ?? const <Team>[])
        team.id: team.name.toLowerCase(),
    };
    return _all
        .where(
          (Match match) =>
              (teamNames[match.homeTeamId]?.contains(needle) ?? false) ||
              (teamNames[match.awayTeamId]?.contains(needle) ?? false) ||
              (match.venue?.toLowerCase().contains(needle) ?? false),
        )
        .toList(growable: false);
  }

  /// Applies a new search term, returning to the first page. No network call.
  Future<void> setSearch(String query) async => _apply(page: 1, search: query);

  /// Jumps to [page] over the filtered list. No network call.
  Future<void> goToPage(int page) async => _apply(page: page);

  /// Reloads the full list from the API.
  Future<void> refresh() => loadMatches();

  /// Deletes [matchId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deleteMatch(String matchId) async {
    try {
      await _repository.deleteMatch(matchId);
      _all = await _fetchAll();
    } on AppException catch (error) {
      return error.message;
    }
    // _apply clamps the page, so removing the last item of the tail page lands
    // on the new last page instead of an empty one.
    _apply(page: state.page);
    return null;
  }

  /// Finishes an ongoing [matchId] and reloads. Returns `null` on success or
  /// the backend's message.
  Future<String?> finishMatch(String matchId) =>
      _runLifecycle(() => _repository.finishMatch(matchId));

  /// Cancels [matchId] (superadmin) and reloads.
  Future<String?> cancelMatch(String matchId) =>
      _runLifecycle(() => _repository.cancelMatch(matchId));

  /// Postpones [matchId] (superadmin) and reloads.
  Future<String?> postponeMatch(String matchId, {DateTime? scheduledAt}) =>
      _runLifecycle(
        () => _repository.postponeMatch(matchId, scheduledAt: scheduledAt),
      );

  Future<String?> _runLifecycle(Future<Match> Function() action) async {
    try {
      await action();
      _all = await _fetchAll();
    } on AppException catch (error) {
      return error.message;
    }
    _apply(page: state.page);
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
