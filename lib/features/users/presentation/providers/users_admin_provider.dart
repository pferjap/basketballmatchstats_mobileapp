import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/update_user_club_usecase.dart';
import '../../domain/usecases/update_user_role_usecase.dart';
import 'users_providers.dart';

/// Page size for the registered-users list.
const int kUsersPageSize = 10;

/// Immutable state for the registered-users screen (Plan.md T-034).
@immutable
class UsersAdminState {
  const UsersAdminState({
    this.users = const <AppUser>[],
    this.page = 1,
    this.total = 0,
    this.search = '',
    this.isLoading = true,
    this.errorMessage,
  });

  /// Users on the current page (newest first).
  final List<AppUser> users;

  /// Current 1-based page.
  final int page;

  /// Total users across all pages, as reported by the backend.
  final int total;

  /// Active free-text filter.
  final String search;

  /// Whether a page load is in flight.
  final bool isLoading;

  /// User-facing error from the last load, if any.
  final String? errorMessage;

  UsersAdminState copyWith({
    List<AppUser>? users,
    int? page,
    int? total,
    String? search,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UsersAdminState(
      users: users ?? this.users,
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
      other is UsersAdminState &&
          listEquals(other.users, users) &&
          other.page == page &&
          other.total == total &&
          other.search == search &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(users),
        page,
        total,
        search,
        isLoading,
        errorMessage,
      );
}

/// Loads, filters, paginates and mutates registered users for the admin screen
/// (Plan.md T-034).
class UsersAdminController extends AutoDisposeNotifier<UsersAdminState> {
  GetUsersUseCase get _getUsers => ref.read(getUsersUseCaseProvider);
  UpdateUserRoleUseCase get _updateRole =>
      ref.read(updateUserRoleUseCaseProvider);
  UpdateUserClubUseCase get _updateClub =>
      ref.read(updateUserClubUseCaseProvider);

  bool _disposed = false;

  @override
  UsersAdminState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred past build() so a synchronous failure never mutates state while
    // the notifier is still being constructed.
    Future<void>.microtask(() => loadUsers());
    return const UsersAdminState();
  }

  /// Loads [page] applying the current (or newly supplied) [search] filter.
  Future<void> loadUsers({int page = 1, String? search}) async {
    final query = search ?? state.search;
    _setState(state.copyWith(isLoading: true, page: page, search: query));
    try {
      final result = await _getUsers(
        GetUsersParams(
          page: page,
          limit: kUsersPageSize,
          search: query.isEmpty ? null : query,
        ),
      );
      _setState(
        UsersAdminState(
          users: result.items,
          page: result.page ?? page,
          total: result.total ?? result.items.length,
          search: query,
          isLoading: false,
        ),
      );
    } on AppException catch (error) {
      _setState(
        UsersAdminState(
          page: page,
          search: query,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Applies a new search term, returning to the first page.
  Future<void> setSearch(String query) => loadUsers(search: query);

  /// Jumps to [page] keeping the active filter.
  Future<void> goToPage(int page) => loadUsers(page: page);

  /// Reloads the current page.
  Future<void> refresh() => loadUsers(page: state.page);

  /// Changes [userId]'s role and reloads the current page.
  ///
  /// Returns `null` on success, or the backend's message so the caller can show
  /// it in a SnackBar.
  Future<String?> changeRole(String userId, UserRole role) async {
    try {
      await _updateRole(UpdateUserRoleParams(userId: userId, role: role));
    } on AppException catch (error) {
      return error.message;
    }
    await loadUsers(page: state.page);
    return null;
  }

  /// Assigns (or clears when [clubId] is null) [userId]'s club and reloads.
  ///
  /// Returns `null` on success, or the backend's message on failure.
  Future<String?> assignClub(String userId, String? clubId) async {
    try {
      await _updateClub(UpdateUserClubParams(userId: userId, clubId: clubId));
    } on AppException catch (error) {
      return error.message;
    }
    await loadUsers(page: state.page);
    return null;
  }

  void _setState(UsersAdminState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }
}

/// Registered-users screen controller.
final usersAdminControllerProvider =
    AutoDisposeNotifierProvider<UsersAdminController, UsersAdminState>(
      UsersAdminController.new,
    );
