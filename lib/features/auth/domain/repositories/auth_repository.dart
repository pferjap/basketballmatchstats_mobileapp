import '../entities/auth_tokens.dart';
import '../entities/user.dart';

/// Coordinates authentication between the remote API and local secure storage
/// (Plan.md T-010, Agent_Mobile.md §9).
abstract interface class AuthRepository {
  /// Authenticates with [email]/[password], persists the tokens and returns the
  /// signed-in [User]. Throws an `AppException` on failure.
  Future<User> login({required String email, required String password});

  /// Exchanges the stored refresh token for a fresh [AuthTokens] pair.
  Future<AuthTokens> refresh();

  /// Clears the local session (tokens + cached user).
  Future<void> logout();

  /// Returns the cached signed-in user, or `null` if there is no session.
  Future<User?> getCurrentUser();
}
