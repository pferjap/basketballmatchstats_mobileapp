import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import 'players_providers.dart';

/// Page size for the admin players list.
const int kPlayersPageSize = 7;

/// Immutable state for the admin panel's Jugadores tab (Plan.md T-029).
@immutable
class PlayersAdminState {
  const PlayersAdminState({
    this.players = const <Player>[],
    this.page = 1,
    this.total = 0,
    this.search = '',
    this.isLoading = true,
    this.errorMessage,
  });

  /// Players on the current page.
  final List<Player> players;

  /// Current 1-based page.
  final int page;

  /// Total players across all pages, as reported by the backend.
  final int total;

  /// Active free-text filter.
  final String search;

  /// Whether a page load is in flight.
  final bool isLoading;

  /// User-facing error from the last load, if any.
  final String? errorMessage;

  PlayersAdminState copyWith({
    List<Player>? players,
    int? page,
    int? total,
    String? search,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlayersAdminState(
      players: players ?? this.players,
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
      other is PlayersAdminState &&
          listEquals(other.players, players) &&
          other.page == page &&
          other.total == total &&
          other.search == search &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(players),
    page,
    total,
    search,
    isLoading,
    errorMessage,
  );
}

/// Loads, filters, paginates and deletes players for the admin panel.
class PlayersAdminController extends AutoDisposeNotifier<PlayersAdminState> {
  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  bool _disposed = false;

  @override
  PlayersAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(() => loadPlayers());
    return const PlayersAdminState();
  }

  /// Loads [page] applying the current (or newly supplied) [search] filter.
  Future<void> loadPlayers({int page = 1, String? search}) async {
    final query = search ?? state.search;
    _setState(state.copyWith(isLoading: true, page: page, search: query));
    try {
      final result = await _repository.getPlayers(
        page: page,
        limit: kPlayersPageSize,
        search: query.isEmpty ? null : query,
      );
      _setState(
        PlayersAdminState(
          players: result.items,
          page: result.page ?? page,
          total: result.total ?? result.items.length,
          search: query,
          isLoading: false,
        ),
      );
    } on AppException catch (error) {
      _setState(
        PlayersAdminState(
          page: page,
          search: query,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Applies a new search term, returning to the first page.
  Future<void> setSearch(String query) => loadPlayers(search: query);

  /// Jumps to [page] keeping the active filter.
  Future<void> goToPage(int page) => loadPlayers(page: page);

  /// Reloads the current page.
  Future<void> refresh() => loadPlayers(page: state.page);

  /// Deletes [playerId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deletePlayer(String playerId) async {
    try {
      await _repository.deletePlayer(playerId);
    } on AppException catch (error) {
      return error.message;
    }
    // Stepping back a page avoids landing on an empty tail page after the
    // last item of the current page is removed.
    final isLastItemOnPage = state.players.length == 1 && state.page > 1;
    await loadPlayers(page: isLastItemOnPage ? state.page - 1 : state.page);
    return null;
  }

  void _setState(PlayersAdminState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }
}

/// Admin panel Jugadores tab controller.
final playersAdminControllerProvider =
    AutoDisposeNotifierProvider<PlayersAdminController, PlayersAdminState>(
      PlayersAdminController.new,
    );
