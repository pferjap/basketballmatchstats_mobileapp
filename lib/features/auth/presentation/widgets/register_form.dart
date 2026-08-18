import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/register_provider.dart';

/// Sign-up form with inline validation and the primary "Crear cuenta" action
/// (Plan.md T-033).
///
/// The fields map one-to-one to the backend `RegisterDto` (first name, last
/// name, email, password) plus a client-only password confirmation and a terms
/// checkbox that gates submission. No role or club selector: the backend fixes
/// `VIEWER` / `clubId = null`.
class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String message) {
    if ((value?.trim() ?? '').isEmpty) {
      return message;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Introduce tu correo electrónico';
    }
    if (!_emailRegExp.hasMatch(email)) {
      return 'Introduce un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Introduce una contraseña';
    }
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Repite la contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_acceptedTerms) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref.read(registerControllerProvider.notifier).submit(
          RegisterParams(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
      registerControllerProvider.select((state) => state.isSubmitting),
    );
    final canSubmit = _acceptedTerms && !isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Nombre'),
          const SizedBox(height: kSpacingS),
          TextFormField(
            controller: _firstNameController,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => _validateRequired(value, 'Introduce tu nombre'),
            decoration: const InputDecoration(
              hintText: 'Tu nombre',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: kSpacingL),
          const _FieldLabel('Apellidos'),
          const SizedBox(height: kSpacingS),
          TextFormField(
            controller: _lastNameController,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                _validateRequired(value, 'Introduce tus apellidos'),
            decoration: const InputDecoration(
              hintText: 'Tus apellidos',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: kSpacingL),
          const _FieldLabel('Correo electrónico'),
          const SizedBox(height: kSpacingS),
          TextFormField(
            controller: _emailController,
            enabled: !isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateEmail,
            decoration: const InputDecoration(
              hintText: 'tu@email.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: kSpacingL),
          const _FieldLabel('Contraseña'),
          const SizedBox(height: kSpacingS),
          TextFormField(
            controller: _passwordController,
            enabled: !isSubmitting,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validatePassword,
            decoration: InputDecoration(
              hintText: 'Mínimo 8 caracteres',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: isSubmitting
                    ? null
                    : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
              ),
            ),
          ),
          const SizedBox(height: kSpacingL),
          const _FieldLabel('Repite la contraseña'),
          const SizedBox(height: kSpacingS),
          TextFormField(
            controller: _confirmController,
            enabled: !isSubmitting,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateConfirm,
            onFieldSubmitted: (_) => canSubmit ? _submit() : null,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: isSubmitting
                    ? null
                    : () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _obscureConfirm
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
              ),
            ),
          ),
          const SizedBox(height: kSpacingM),
          InkWell(
            onTap: isSubmitting
                ? null
                : () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: isSubmitting
                        ? null
                        : (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Acepto los términos y condiciones del servicio.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: kSpacingM),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    )
                  : const Text('Crear cuenta'),
            ),
          ),
          const SizedBox(height: kSpacingL),
          Center(
            child: TextButton(
              onPressed: isSubmitting ? null : () => context.go(AppRoutes.login),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(0, kMinTouchTarget),
              ),
              child: const Text.rich(
                TextSpan(
                  text: '¿Ya tienes cuenta? ',
                  children: [
                    TextSpan(
                      text: 'Inicia sesión',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
