import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../providers/auth_providers.dart';
import '../providers/register_provider.dart';
import '../widgets/login_header.dart';
import '../widgets/register_form.dart';

/// Registration screen (Plan.md T-033).
///
/// A new account is always created as `VIEWER` with no club, and the backend
/// returns tokens, so a successful sign-up leaves the user authenticated. This
/// page surfaces backend failures as a red SnackBar and, once the session flips
/// to authenticated, a green welcome SnackBar — the router's global guard then
/// forwards the user to the main menu.
class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<RegisterState>(registerControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                next.errorMessage!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
      }
    });

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      final justAuthenticated =
          previous?.isAuthenticated != true && next.isAuthenticated;
      if (justAuthenticated) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                '¡Bienvenido! Tu cuenta se ha creado.',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const LoginHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kSpacingL,
                  kSpacingL,
                  kSpacingL,
                  kSpacingXL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Crea tu cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: kSpacingS),
                    Text(
                      'Tu cuenta se creará como espectador, con acceso a '
                      'seguir partidos en directo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: kSpacingXL),
                    const RegisterForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
