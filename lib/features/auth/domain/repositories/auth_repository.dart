import '../entities/auth_tokens.dart';
import '../entities/user.dart';

/// Sign-up input, mirroring the backend `RegisterDto` exactly (Plan.md T-032).
///
/// The backend fixes `role = VIEWER` and `clubId = null` on registration, so
/// the client never sends those — the DTO does not even accept them.
class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;
}

/// Coordinates authentication between the remote API and local secure storage
/// (Plan.md T-010, Agent_Mobile.md §9).
abstract interface class AuthRepository {
  /// Authenticates with [email]/[password], persists the tokens and returns the
  /// signed-in [User]. Throws an `AppException` on failure.
  Future<User> login({required String email, required String password});

  /// Registers a new account (`POST /auth/register`). The response carries the
  /// same tokens as [login], so on success the tokens are persisted and the new
  /// [User] (always a `VIEWER` with no club) is returned already signed in.
  Future<User> register(RegisterParams params);

  /// Exchanges the stored refresh token for a fresh [AuthTokens] pair.
  Future<AuthTokens> refresh();

  /// Clears the local session (tokens + cached user).
  Future<void> logout();

  /// Returns the cached signed-in user, or `null` if there is no session.
  Future<User?> getCurrentUser();
}
