import '../../../../core/usecases/usecase.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

/// Creates a new player.
class CreatePlayerUseCase implements UseCase<Player, CreatePlayerParams> {
  const CreatePlayerUseCase(this.repository);

  final PlayerRepository repository;

  @override
  Future<Player> call(CreatePlayerParams params) =>
      repository.createPlayer(params);
}
