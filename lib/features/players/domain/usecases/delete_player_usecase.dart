import '../../../../core/usecases/usecase.dart';
import '../repositories/player_repository.dart';

/// Permanently removes a player.
class DeletePlayerUseCase implements UseCase<void, String> {
  const DeletePlayerUseCase(this.repository);

  final PlayerRepository repository;

  @override
  Future<void> call(String playerId) => repository.deletePlayer(playerId);
}
