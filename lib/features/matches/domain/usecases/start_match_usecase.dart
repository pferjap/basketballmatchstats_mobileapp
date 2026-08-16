import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

/// Starts a scheduled match. Parameter is the match id.
class StartMatchUseCase implements UseCase<Match, String> {
  const StartMatchUseCase(this.repository);

  final MatchRepository repository;

  @override
  Future<Match> call(String matchId) => repository.startMatch(matchId);
}
