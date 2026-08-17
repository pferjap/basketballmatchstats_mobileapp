import '../../../../core/usecases/usecase.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

/// Parameters for [UpdatePlayerUseCase].
class UpdatePlayerArgs {
  const UpdatePlayerArgs({required this.playerId, required this.params});

  final String playerId;
  final UpdatePlayerParams params;
}

/// Updates an existing player.
class UpdatePlayerUseCase implements UseCase<Player, UpdatePlayerArgs> {
  const UpdatePlayerUseCase(this.repository);

  final PlayerRepository repository;

  @override
  Future<Player> call(UpdatePlayerArgs args) =>
      repository.updatePlayer(args.playerId, args.params);
}
