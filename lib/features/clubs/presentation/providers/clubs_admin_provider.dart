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
class ClubsAdminController extends AutoDisposeNotifier<ClubsAdminState> {
  ClubRepository get _repository => ref.read(clubRepositoryProvider);

  bool _disposed = false;

  @override
  ClubsAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous repository failure never mutates
    // state while the notifier is still being constructed.
    Future<void>.microtask(() => loadClubs());
    return const ClubsAdminState();
  }

  /// Loads [page] applying the current (or newly supplied) [search] filter.
  Future<void> loadClubs({int page = 1, String? search}) async {
    final query = search ?? state.search;
    _setState(state.copyWith(isLoading: true, page: page, search: query));
    try {
      final result = await _repository.getClubs(
        page: page,
        limit: kClubsPageSize,
        search: query.isEmpty ? null : query,
      );
      _setState(
        ClubsAdminState(
          clubs: result.items,
          page: result.page ?? page,
          total: result.total ?? result.items.length,
          search: query,
          isLoading: false,
        ),
      );
    } on AppException catch (error) {
      _setState(
        ClubsAdminState(
          page: page,
          search: query,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Applies a new search term, returning to the first page.
  Future<void> setSearch(String query) => loadClubs(search: query);

  /// Jumps to [page] keeping the active filter.
  Future<void> goToPage(int page) => loadClubs(page: page);

  /// Reloads the current page.
  Future<void> refresh() => loadClubs(page: state.page);

  /// Deletes [clubId] and reloads the list.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> deleteClub(String clubId) async {
    try {
      await _repository.deleteClub(clubId);
    } on AppException catch (error) {
      return error.message;
    }
    // Stepping back a page avoids landing on an empty tail page after the
    // last item of the current page is removed.
    final isLastItemOnPage = state.clubs.length == 1 && state.page > 1;
    await loadClubs(page: isLastItemOnPage ? state.page - 1 : state.page);
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
