import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../clubs/domain/entities/club.dart';
import '../../../clubs/presentation/providers/clubs_providers.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import 'teams_providers.dart';

/// Clubs offered by the team form's club dropdown.
///
/// A team belongs to a club, so the form reads the clubs feature's repository
/// directly rather than duplicating the datasource.
final teamFormClubsProvider = FutureProvider.autoDispose<List<Club>>((
  ref,
) async {
  final page = await ref
      .watch(clubRepositoryProvider)
      .getClubs(page: 1, limit: 100);
  return page.items;
});

/// Submission state of the team create/edit form (Plan.md T-028).
@immutable
class TeamFormState {
  const TeamFormState({this.isSubmitting = false, this.errorMessage});

  /// Whether a create/update request is in flight.
  final bool isSubmitting;

  /// Backend error from the last failed submit, if any.
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamFormState &&
          other.isSubmitting == isSubmitting &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(isSubmitting, errorMessage);
}

/// Drives create and update submissions for the team form.
class TeamFormController extends AutoDisposeNotifier<TeamFormState> {
  TeamRepository get _repository => ref.read(teamRepositoryProvider);

  @override
  TeamFormState build() => const TeamFormState();

  /// Creates a team. Returns the persisted team, or `null` on failure.
  Future<Team?> create(CreateTeamParams params) =>
      _submit(() => _repository.createTeam(params));

  /// Updates [teamId]. Returns the persisted team, or `null` on failure.
  Future<Team?> update(String teamId, UpdateTeamParams params) =>
      _submit(() => _repository.updateTeam(teamId, params));

  Future<Team?> _submit(Future<Team> Function() action) async {
    state = const TeamFormState(isSubmitting: true);
    try {
      final team = await action();
      state = const TeamFormState();
      return team;
    } on AppException catch (error) {
      state = TeamFormState(errorMessage: error.message);
      return null;
    }
  }
}

/// Team create/edit form controller.
final teamFormControllerProvider =
    AutoDisposeNotifierProvider<TeamFormController, TeamFormState>(
      TeamFormController.new,
    );
