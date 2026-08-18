import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Submission state of the registration form (Plan.md T-033).
@immutable
class RegisterState {
  const RegisterState({this.isSubmitting = false, this.errorMessage});

  /// Whether a sign-up request is in flight.
  final bool isSubmitting;

  /// User-facing error from the last failed submit, if any.
  final String? errorMessage;

  RegisterState copyWith({bool? isSubmitting, String? errorMessage}) {
    return RegisterState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterState &&
          other.isSubmitting == isSubmitting &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(isSubmitting, errorMessage);
}

/// Drives the registration form submission (Plan.md T-033).
///
/// On success it updates [authStateProvider] so the router's global guard lets
/// the freshly-registered user into the app; on failure it exposes the
/// backend's message for a red SnackBar.
class RegisterController extends AutoDisposeNotifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  /// Submits the sign-up. Returns `true` on success.
  Future<bool> submit(RegisterParams params) async {
    state = const RegisterState(isSubmitting: true);
    try {
      final user = await ref.read(registerUseCaseProvider).call(params);
      ref.read(authStateProvider.notifier).completeRegistration(user);
    } on AppException catch (error) {
      state = RegisterState(errorMessage: ErrorMapper.mapException(error).message);
      return false;
    }
    state = const RegisterState();
    return true;
  }
}

/// Registration form controller.
final registerControllerProvider =
    AutoDisposeNotifierProvider<RegisterController, RegisterState>(
      RegisterController.new,
    );
