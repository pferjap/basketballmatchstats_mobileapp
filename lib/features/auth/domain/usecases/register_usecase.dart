import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Registers a new account and returns the signed-in [User] (Plan.md T-032).
///
/// The backend responds with the same token pair as login, so the repository
/// persists the session; the caller only needs to reflect it in the auth state.
class RegisterUseCase implements UseCase<User, RegisterParams> {
  const RegisterUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<User> call(RegisterParams params) => repository.register(params);
}
