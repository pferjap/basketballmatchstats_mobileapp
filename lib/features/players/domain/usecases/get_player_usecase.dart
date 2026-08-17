import '../../../../core/usecases/usecase.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

/// Fetches a single player by id.
class GetPlayerUseCase implements UseCase<Player, String> {
  const GetPlayerUseCase(this.repository);

  final PlayerRepository repository;

  @override
  Future<Player> call(String playerId) => repository.getPlayer(playerId);
}
