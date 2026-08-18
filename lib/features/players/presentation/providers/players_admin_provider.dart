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
///
/// The `GET /players` endpoint exposes no text-search parameter, so the whole
/// list is fetched once and both filtering and pagination are performed
/// client-side.
class PlayersAdminController extends AutoDisposeNotifier<PlayersAdminState> {
  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  bool _disposed = false;

  /// Every player fetched from the API, before the client-side search filter.
  List<Player> _all = const <Player>[];

  @override
  PlayersAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(loadPlayers);
    return const PlayersAdminState();
  }

  /// Fetches every player and shows the first page of the current filter.
  Future<void> loadPlayers() async {
    _setState(state.copyWith(isLoading: true));
    try {
      _all = await _fetchAll();
      _apply(page: 1);
    } on AppException catch (error) {
      _setState(
        PlayersAdminState(
          search: state.search,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Pulls all players by walking the paginated endpoint at the maximum limit.
  Future<List<Player>> _fetchAll() async {
    final players = <Player>[];
    var page = 1;
    while (true) {
      final result = await _repository.getPlayers(page: page, limit: 100);
      players.addAll(result.items);
      final total = result.total ?? players.length;
      if (result.items.isEmpty || players.length >= total) {
        break;
      }
      page++;
    }
    return players;
  }

  /// Recomputes the visible page from [_all] for [page] and [search].
  void _apply({required int page, String? search}) {
    final query = search ?? state.search;
    final filtered = _filter(query);
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length / kPlayersPageSize).ceil();
    final safePage = page.clamp(1, pageCount);
    final start = (safePage - 1) * kPlayersPageSize;
    _setState(
      PlayersAdminState(
        players: filtered
            .skip(start)
            .take(kPlayersPageSize)
            .toList(growable: false),
        page: safePage,
        total: filtered.length,
        search: query,
        isLoading: false,
      ),
    );
  }

  List<Player> _filter(String query) {
    if (query.isEmpty) {
      return _all;
    }
    final needle = query.toLowerCase();
    return _all
        .where(
          (Player player) =>
              player.fullName.toLowerCase().contains(needle) ||
              (player.teamName?.toLowerCase().contains(needle) ?? false) ||
              (player.jerseyNumber?.toString().contains(needle) ?? false),
        )
        .toList(growable: false);
  }

  /// Applies a new search term, returning to the first page. No network call.
  Future<void> setSearch(String query) async => _apply(page: 1, search: query);

  /// Jumps to [page] over the filtered list. No network call.
  Future<void> goToPage(int page) async => _apply(page: page);

  /// Reloads the full list from the API.
  Future<void> refresh() => loadPlayers();

  /// Deletes [playerId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deletePlayer(String playerId) async {
    try {
      await _repository.deletePlayer(playerId);
      _all = await _fetchAll();
    } on AppException catch (error) {
      return error.message;
    }
    // _apply clamps the page, so removing the last item of the tail page lands
    // on the new last page instead of an empty one.
    _apply(page: state.page);
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
