import '../../../../core/usecases/usecase.dart';
import '../entities/match_event.dart';
import '../repositories/event_repository.dart';

/// Parameters for [RecordEventUseCase].
class RecordEventParams {
  const RecordEventParams({required this.matchId, required this.event});

  final String matchId;
  final EventParams event;
}

/// Records a new event for a match (offline-first).
class RecordEventUseCase implements UseCase<MatchEvent, RecordEventParams> {
  const RecordEventUseCase(this.repository);

  final EventRepository repository;

  @override
  Future<MatchEvent> call(RecordEventParams params) =>
      repository.recordEvent(params.matchId, params.event);
}
