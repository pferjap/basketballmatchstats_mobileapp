import '../../../../core/usecases/usecase.dart';
import '../entities/match_score.dart';
import '../repositories/match_repository.dart';

/// Fetches the live score for a match. Parameter is the match id.
class GetLiveScoreUseCase implements UseCase<MatchScore, String> {
  const GetLiveScoreUseCase(this.repository);

  final MatchRepository repository;

  @override
  Future<MatchScore> call(String matchId) async {
    final statistics = await repository.getMatchStatistics(matchId);
    return statistics.score;
  }
}
