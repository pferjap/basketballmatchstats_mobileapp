import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/settings_providers.dart';

/// Spanish labels for the system roles (Agent_Mobile.md §13).
const Map<UserRole, String> kUserRoleLabels = <UserRole, String>{
  UserRole.superAdmin: 'Administrador de la plataforma',
  UserRole.clubAdmin: 'Administrador del club',
  UserRole.coach: 'Entrenador',
  UserRole.statistician: 'Anotador',
  UserRole.viewer: 'Espectador',
};

/// Profile and preferences screen (Plan.md T-031).
///
/// Reached from the home menu's "Tu perfil" link.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authStateProvider.notifier).logout();
    // The router's redirect sends unauthenticated users to /login on its own,
    // but navigating explicitly avoids leaving this screen on screen while the
    // refresh listenable propagates.
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final prefs = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al menú principal',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text(
          'Tu perfil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(kSpacingM),
          children: <Widget>[
            _ProfileCard(user: user),
            const SizedBox(height: kSpacingL),
            const _SectionLabel('PREFERENCIAS'),
            SwitchListTile(
              value: prefs.notificationsEnabled,
              onChanged: controller.setNotificationsEnabled,
              activeThumbColor: AppColors.primary,
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Notificaciones',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Avisos de partidos y resultados',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              secondary: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: kSpacingS),
            _LanguageTile(
              languageCode: prefs.languageCode,
              onChanged: controller.setLanguageCode,
            ),
            const SizedBox(height: kSpacingL),
            const _SectionLabel('ACERCA DE'),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(
                Icons.info_outline,
                color: AppColors.textSecondary,
              ),
              title: const Text(
                'Versión de la app',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              trailing: Text(
                version.when(
                  loading: () => '…',
                  error: (Object e, StackTrace s) => 'No disponible',
                  data: (String value) => value,
                ),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: kSpacingXL),
            SizedBox(
              height: kMinTouchTarget,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final user = this.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(kSpacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          _Avatar(avatarUrl: user.avatarUrl, name: user.name),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSpacingXS),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: kSpacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    kUserRoleLabels[user.role] ?? 'Usuario',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.name});

  final String? avatarUrl;
  final String name;

  /// Up to two initials, e.g. "Pedro Fernández" -> "PF".
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts
        .where((String p) => p.isNotEmpty)
        .take(2)
        .map((String p) => p.characters.first.toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = this.avatarUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) => const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.background,
        ),
        errorWidget: (BuildContext context, String url, Object error) =>
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.background,
              child: Icon(Icons.person_outline, color: AppColors.textSecondary),
            ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.languageCode, required this.onChanged});

  final String languageCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.language, color: AppColors.textSecondary),
      title: const Text(
        'Idioma',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      trailing: DropdownButton<String>(
        value: languageCode,
        dropdownColor: AppColors.surface,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: AppColors.textPrimary),
        items: <DropdownMenuItem<String>>[
          for (final MapEntry<String, String> entry
              in kSupportedLanguages.entries)
            DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
        ],
        onChanged: (String? value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingS),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
