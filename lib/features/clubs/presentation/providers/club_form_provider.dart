import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';
import 'clubs_providers.dart';

/// Submission state of the club create/edit form (Plan.md T-027).
@immutable
class ClubFormState {
  const ClubFormState({this.isSubmitting = false, this.errorMessage});

  /// Whether a create/update request is in flight.
  final bool isSubmitting;

  /// Backend error from the last failed submit, if any.
  final String? errorMessage;

  ClubFormState copyWith({bool? isSubmitting, String? errorMessage}) {
    return ClubFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClubFormState &&
          other.isSubmitting == isSubmitting &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(isSubmitting, errorMessage);
}

/// Drives create and update submissions for the club form.
class ClubFormController extends AutoDisposeNotifier<ClubFormState> {
  ClubRepository get _repository => ref.read(clubRepositoryProvider);

  @override
  ClubFormState build() => const ClubFormState();

  /// Creates a club. Returns the persisted club, or `null` on failure.
  Future<Club?> create(CreateClubParams params) =>
      _submit(() => _repository.createClub(params));

  /// Updates [clubId]. Returns the persisted club, or `null` on failure.
  Future<Club?> update(String clubId, UpdateClubParams params) =>
      _submit(() => _repository.updateClub(clubId, params));

  Future<Club?> _submit(Future<Club> Function() action) async {
    state = const ClubFormState(isSubmitting: true);
    try {
      final club = await action();
      state = const ClubFormState();
      return club;
    } on AppException catch (error) {
      state = ClubFormState(errorMessage: error.message);
      return null;
    }
  }
}

/// Club create/edit form controller.
final clubFormControllerProvider =
    AutoDisposeNotifierProvider<ClubFormController, ClubFormState>(
      ClubFormController.new,
    );
