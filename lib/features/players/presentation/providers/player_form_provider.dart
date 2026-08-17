import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import 'players_providers.dart';

/// Teams offered by the player form's team dropdown.
///
/// A player belongs to a team, so the form reads the teams feature's repository
/// directly rather than duplicating the datasource.
final playerFormTeamsProvider = FutureProvider.autoDispose<List<Team>>((
  ref,
) async {
  final page = await ref
      .watch(teamRepositoryProvider)
      .getTeams(page: 1, limit: 100);
  return page.items;
});

/// Human-readable Spanish labels for the on-court positions.
const Map<PlayerPosition, String> kPlayerPositionLabels =
    <PlayerPosition, String>{
      PlayerPosition.pointGuard: 'Base',
      PlayerPosition.shootingGuard: 'Escolta',
      PlayerPosition.smallForward: 'Alero',
      PlayerPosition.powerForward: 'Ala-pívot',
      PlayerPosition.center: 'Pívot',
    };

/// Submission state of the player create/edit form (Plan.md T-029).
@immutable
class PlayerFormState {
  const PlayerFormState({this.isSubmitting = false, this.errorMessage});

  /// Whether a create/update request is in flight.
  final bool isSubmitting;

  /// Backend error from the last failed submit, if any.
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerFormState &&
          other.isSubmitting == isSubmitting &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(isSubmitting, errorMessage);
}

/// Drives create and update submissions for the player form.
class PlayerFormController extends AutoDisposeNotifier<PlayerFormState> {
  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  @override
  PlayerFormState build() => const PlayerFormState();

  /// Creates a player. Returns `true` on success.
  Future<bool> create(CreatePlayerParams params) =>
      _submit(() => _repository.createPlayer(params));

  /// Updates [playerId]. Returns `true` on success.
  Future<bool> update(String playerId, UpdatePlayerParams params) =>
      _submit(() => _repository.updatePlayer(playerId, params));

  Future<bool> _submit(Future<void> Function() action) async {
    state = const PlayerFormState(isSubmitting: true);
    try {
      await action();
    } on AppException catch (error) {
      state = PlayerFormState(errorMessage: error.message);
      return false;
    }
    state = const PlayerFormState();
    return true;
  }
}

/// Player create/edit form controller.
final playerFormControllerProvider =
    AutoDisposeNotifierProvider<PlayerFormController, PlayerFormState>(
      PlayerFormController.new,
    );
