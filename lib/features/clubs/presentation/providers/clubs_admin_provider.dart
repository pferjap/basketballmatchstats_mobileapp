import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';
import 'clubs_providers.dart';

/// Page size for the admin clubs list.
const int kClubsPageSize = 7;

/// Immutable state for the admin panel's Clubs tab (Plan.md T-026).
@immutable
class ClubsAdminState {
  const ClubsAdminState({
    this.clubs = const <Club>[],
    this.page = 1,
    this.total = 0,
    this.search = '',
    this.isLoading = true,
    this.errorMessage,
  });

  /// Clubs on the current page.
  final List<Club> clubs;

  /// Current 1-based page.
  final int page;

  /// Total clubs across all pages, as reported by the backend.
  final int total;

  /// Active free-text filter.
  final String search;

  /// Whether a page load is in flight.
  final bool isLoading;

  /// User-facing error from the last load, if any.
  final String? errorMessage;

  ClubsAdminState copyWith({
    List<Club>? clubs,
    int? page,
    int? total,
    String? search,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClubsAdminState(
      clubs: clubs ?? this.clubs,
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
      other is ClubsAdminState &&
          listEquals(other.clubs, clubs) &&
          other.page == page &&
          other.total == total &&
          other.search == search &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(clubs),
    page,
    total,
    search,
    isLoading,
    errorMessage,
  );
}

/// Loads, filters, paginates and deletes clubs for the admin panel.
///
/// The `GET /clubs` endpoint exposes no text-search parameter, so the whole
/// list is fetched once and both filtering and pagination are performed
/// client-side.
class ClubsAdminController extends AutoDisposeNotifier<ClubsAdminState> {
  ClubRepository get _repository => ref.read(clubRepositoryProvider);

  bool _disposed = false;

  /// Every club fetched from the API, before the client-side search filter.
  List<Club> _all = const <Club>[];

  @override
  ClubsAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(loadClubs);
    return const ClubsAdminState();
  }

  /// Fetches every club and shows the first page of the current filter.
  Future<void> loadClubs() async {
    _setState(state.copyWith(isLoading: true));
    try {
      _all = await _fetchAll();
      _apply(page: 1);
    } on AppException catch (error) {
      _setState(
        ClubsAdminState(
          search: state.search,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Pulls all clubs by walking the paginated endpoint at the maximum limit.
  Future<List<Club>> _fetchAll() async {
    final clubs = <Club>[];
    var page = 1;
    while (true) {
      final result = await _repository.getClubs(page: page, limit: 100);
      clubs.addAll(result.items);
      final total = result.total ?? clubs.length;
      if (result.items.isEmpty || clubs.length >= total) {
        break;
      }
      page++;
    }
    return clubs;
  }

  /// Recomputes the visible page from [_all] for [page] and [search].
  void _apply({required int page, String? search}) {
    final query = search ?? state.search;
    final filtered = _filter(query);
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length / kClubsPageSize).ceil();
    final safePage = page.clamp(1, pageCount);
    final start = (safePage - 1) * kClubsPageSize;
    _setState(
      ClubsAdminState(
        clubs: filtered
            .skip(start)
            .take(kClubsPageSize)
            .toList(growable: false),
        page: safePage,
        total: filtered.length,
        search: query,
        isLoading: false,
      ),
    );
  }

  List<Club> _filter(String query) {
    if (query.isEmpty) {
      return _all;
    }
    final needle = query.toLowerCase();
    return _all
        .where(
          (Club club) =>
              club.name.toLowerCase().contains(needle) ||
              (club.city?.toLowerCase().contains(needle) ?? false),
        )
        .toList(growable: false);
  }

  /// Applies a new search term, returning to the first page. No network call.
  Future<void> setSearch(String query) async => _apply(page: 1, search: query);

  /// Jumps to [page] over the filtered list. No network call.
  Future<void> goToPage(int page) async => _apply(page: page);

  /// Reloads the full list from the API.
  Future<void> refresh() => loadClubs();

  /// Deletes [clubId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deleteClub(String clubId) async {
    try {
      await _repository.deleteClub(clubId);
      _all = await _fetchAll();
    } on AppException catch (error) {
      return error.message;
    }
    // _apply clamps the page, so removing the last item of the tail page lands
    // on the new last page instead of an empty one.
    _apply(page: state.page);
    return null;
  }

  void _setState(ClubsAdminState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }
}

/// Admin panel Clubs tab controller.
final clubsAdminControllerProvider =
    AutoDisposeNotifierProvider<ClubsAdminController, ClubsAdminState>(
      ClubsAdminController.new,
    );
