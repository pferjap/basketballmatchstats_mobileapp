import '../../../../core/models/paginated.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_event.dart';
import '../repositories/match_repository.dart';

/// Parameters for [GetMatchEventsUseCase].
class GetMatchEventsParams {
  const GetMatchEventsParams({
    required this.matchId,
    this.since,
    this.page,
    this.limit,
  });

  final String matchId;

  /// When set, only events created after this timestamp are returned.
  final DateTime? since;
  final int? page;
  final int? limit;
}

/// Fetches a paginated list of a match's events.
class GetMatchEventsUseCase
    implements UseCase<Paginated<MatchEvent>, GetMatchEventsParams> {
  const GetMatchEventsUseCase(this.repository);

  final MatchRepository repository;

  @override
  Future<Paginated<MatchEvent>> call(GetMatchEventsParams params) =>
      repository.getMatchEvents(
        params.matchId,
        since: params.since,
        page: params.page,
        limit: params.limit,
      );
}
