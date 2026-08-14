import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../providers/auth_providers.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

/// Login screen (Plan.md T-011).
///
/// Composes the branded [LoginHeader], the welcome copy and the [LoginForm],
/// and surfaces login failures as a red SnackBar by listening to
/// [authStateProvider].
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
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

    return Scaffold(
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
                    Text(
                      'Bienvenido de nuevo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: kSpacingS),
                    Text(
                      'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: kSpacingXL),
                    const LoginForm(),
                    const SizedBox(height: kSpacingXL),
                    Text(
                      '© 2024 BasketStats. Todos los derechos reservados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
