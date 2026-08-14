import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/ui_constants.dart';

/// Temporary scaffold for routes whose real screens are implemented in later
/// phases (Home, Teams, Players, Live, Court View, Settings).
///
/// It exists so the router tree defined in T-012 is complete and testable; each
/// future task replaces the corresponding route builder with its real page.
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({
    required this.title,
    this.subtitle,
    super.key,
  });

  /// Screen title, also used as an on-screen marker in tests.
  final String title;

  /// Optional supporting line (e.g. a route parameter).
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: kSpacingM),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: kSpacingXS),
              Text(
                subtitle!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (user != null) ...[
              const SizedBox(height: kSpacingS),
              Text(
                'Sesión: ${user.name} (${user.role.name})',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
