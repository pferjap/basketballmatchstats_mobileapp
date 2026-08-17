import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import 'match_providers.dart';

/// Why the match list is being shown, which decides both the status filter and
/// the destination screen when a card is tapped (Plan.md T-022).
enum MatchListMode {
  /// Pick a match to annotate — scheduled or in-progress matches.
  annotate,

  /// Pick a live match to spectate — in-progress matches only.
  spectate,
}

/// Page size requested from the backend for each match page.
const int _kMatchPageSize = 20;

/// Immutable state for the match-selection screen.
@immutable
class MatchListState {
  const MatchListState({
    this.matches = const <Match>[],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.errorMessage,
  });

  /// Matches matching the current mode's filter, newest first.
  final List<Match> matches;

  /// Whether the initial load is in flight.
  final bool isLoading;

  /// Whether the next page is being appended.
  final bool isLoadingMore;

  /// Whether a pull-to-refresh is in flight.
  final bool isRefreshing;

  /// Whether more pages may still be loaded from the backend.
  final bool hasMore;

  /// User-facing error message from the initial load, if any.
  final String? errorMessage;

  MatchListState copyWith({
    List<Match>? matches,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    String? errorMessage,
  }) {
    return MatchListState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchListState &&
          listEquals(other.matches, matches) &&
          other.isLoading == isLoading &&
          other.isLoadingMore == isLoadingMore &&
          other.isRefreshing == isRefreshing &&
          other.hasMore == hasMore &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(matches),
    isLoading,
    isLoadingMore,
    isRefreshing,
    hasMore,
    errorMessage,
  );
}

/// Loads and paginates the match list for a given [MatchListMode], applying the
/// per-mode status filter client-side (the backend list endpoint is not
/// filtered) — Plan.md T-022.
class MatchListController
    extends AutoDisposeFamilyNotifier<MatchListState, MatchListMode> {
  MatchRepository get _repository => ref.read(matchRepositoryProvider);

  bool _disposed = false;
  int _nextPage = 1;

  @override
  MatchListState build(MatchListMode mode) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _nextPage = 1;
    // Defer past build() so a synchronous repository failure never tries to
    // mutate state while the notifier is still being constructed.
    Future<void>.microtask(_loadFirstPage);
    return const MatchListState();
  }

  Future<void> _loadFirstPage() async {
    try {
      final page = await _repository.getMatches(
        page: _nextPage,
        limit: _kMatchPageSize,
      );
      _nextPage++;
      _setState(
        MatchListState(
          matches: _filter(page.items),
          isLoading: false,
          hasMore: page.hasMore,
        ),
      );
    } catch (_) {
      _setState(
        const MatchListState(
          isLoading: false,
          hasMore: false,
          errorMessage:
              'No se pudieron cargar los partidos. Comprueba tu conexión.',
        ),
      );
    }
  }

  /// Reloads from the first page (pull-to-refresh).
  Future<void> refresh() async {
    if (state.isRefreshing) {
      return;
    }
    _setState(state.copyWith(isRefreshing: true, errorMessage: null));
    _nextPage = 1;
    try {
      final page = await _repository.getMatches(
        page: _nextPage,
        limit: _kMatchPageSize,
      );
      _nextPage++;
      _setState(
        MatchListState(
          matches: _filter(page.items),
          isLoading: false,
          hasMore: page.hasMore,
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          isRefreshing: false,
          errorMessage:
              'No se pudieron actualizar los partidos. Comprueba tu conexión.',
        ),
      );
    }
  }

  /// Loads and appends the next page (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }
    _setState(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.getMatches(
        page: _nextPage,
        limit: _kMatchPageSize,
      );
      _nextPage++;
      final merged = _mergeById(state.matches, _filter(page.items));
      _setState(
        state.copyWith(
          matches: merged,
          isLoadingMore: false,
          hasMore: page.hasMore,
        ),
      );
    } catch (_) {
      _setState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Keeps only the matches relevant to the current mode.
  List<Match> _filter(List<Match> matches) {
    return matches
        .where((m) {
          switch (arg) {
            case MatchListMode.annotate:
              return m.status == MatchStatus.scheduled ||
                  m.status == MatchStatus.inProgress;
            case MatchListMode.spectate:
              return m.status == MatchStatus.inProgress;
          }
        })
        .toList(growable: false);
  }

  List<Match> _mergeById(List<Match> existing, List<Match> incoming) {
    final byId = <String, Match>{};
    for (final match in <Match>[...existing, ...incoming]) {
      byId[match.id] = match;
    }
    return byId.values.toList(growable: false);
  }

  void _setState(MatchListState next) {
    if (!_disposed) {
      state = next;
    }
  }
}

/// Match-list state for a given selection mode.
final matchListControllerProvider = NotifierProvider.autoDispose
    .family<MatchListController, MatchListState, MatchListMode>(
      MatchListController.new,
    );
