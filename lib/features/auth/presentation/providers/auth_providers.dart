import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/sync_providers.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete [AuthRepository], wired to the shared Dio client and secure token
/// storage (reused from the core providers so login-saved tokens are the same
/// ones the Dio auth interceptor reads).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(dio),
    local: AuthLocalDataSource(tokenStorage: tokenStorage),
  );
});

/// Lifecycle of the authentication flow surfaced to the UI.
enum AuthStatus { idle, loading, authenticated, error }

/// Immutable state exposed by [AuthNotifier].
@immutable
class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.idle() : this(status: AuthStatus.idle);

  final AuthStatus status;

  /// The authenticated user, when [status] is [AuthStatus.authenticated].
  final User? user;

  /// User-facing error message, when [status] is [AuthStatus.error].
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.status == status &&
          other.user == user &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, user, errorMessage);
}

/// Drives login/logout and holds the current session state.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.idle();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Attempts to authenticate; sets [AuthStatus.loading] while in flight and
  /// resolves to [AuthStatus.authenticated] or [AuthStatus.error].
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error) {
      state =
          AuthState(status: AuthStatus.error, errorMessage: _messageFor(error));
    }
  }

  /// Restores a previously cached session, if any (used on app start).
  ///
  /// Best-effort: any storage error leaves the state untouched (logged out)
  /// rather than blocking app startup.
  Future<void> restoreSession() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    } catch (_) {
      // Ignore: an unreadable cache simply means no session to restore.
    }
  }

  /// Clears the session and returns to the idle (logged-out) state.
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.idle();
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return ErrorMapper.mapException(error).message;
    }
    return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
  }
}

/// Authentication state notifier.
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// The currently authenticated user, or `null` when logged out.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});
