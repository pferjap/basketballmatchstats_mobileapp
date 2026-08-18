import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/repositories/match_repository.dart';
import 'match_providers.dart';

/// Teams offered by the match form's home/away dropdowns.
///
/// A match is played between two teams, so the form reads the teams feature's
/// repository directly rather than duplicating the datasource.
final matchFormTeamsProvider = FutureProvider.autoDispose<List<Team>>((
  ref,
) async {
  final page = await ref
      .watch(teamRepositoryProvider)
      .getTeams(page: 1, limit: 100);
  return page.items;
});

/// Submission state of the match create/edit form (Plan.md T-030).
@immutable
class MatchFormState {
  const MatchFormState({this.isSubmitting = false, this.errorMessage});

  /// Whether a create/update request is in flight.
  final bool isSubmitting;

  /// Backend error from the last failed submit, if any.
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchFormState &&
          other.isSubmitting == isSubmitting &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(isSubmitting, errorMessage);
}

/// Drives create and update submissions for the match form.
class MatchFormController extends AutoDisposeNotifier<MatchFormState> {
  MatchRepository get _repository => ref.read(matchRepositoryProvider);

  @override
  MatchFormState build() => const MatchFormState();

  /// Schedules a match. Returns `true` on success.
  Future<bool> create(CreateMatchParams params) =>
      _submit(() => _repository.createMatch(params));

  /// Updates [matchId]. Returns `true` on success.
  Future<bool> update(String matchId, UpdateMatchParams params) =>
      _submit(() => _repository.updateMatch(matchId, params));

  Future<bool> _submit(Future<void> Function() action) async {
    state = const MatchFormState(isSubmitting: true);
    try {
      await action();
    } on AppException catch (error) {
      state = MatchFormState(errorMessage: error.message);
      return false;
    }
    state = const MatchFormState();
    return true;
  }
}

/// Match create/edit form controller.
final matchFormControllerProvider =
    AutoDisposeNotifierProvider<MatchFormController, MatchFormState>(
      MatchFormController.new,
    );
