import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';

/// Spanish labels and chip colours for [UserRole], shared by the registered
/// users card and the change-role dialog (Plan.md T-034).
abstract final class RoleDisplay {
  static const Map<UserRole, String> labels = <UserRole, String>{
    UserRole.superAdmin: 'Super Admin',
    UserRole.clubAdmin: 'Administrador de club',
    UserRole.coach: 'Entrenador',
    UserRole.statistician: 'Anotador',
    UserRole.viewer: 'Espectador',
  };

  static const Map<UserRole, Color> colors = <UserRole, Color>{
    UserRole.superAdmin: AppColors.accentGold,
    UserRole.clubAdmin: AppColors.accentPurple,
    UserRole.coach: AppColors.info,
    UserRole.statistician: AppColors.primary,
    UserRole.viewer: AppColors.textSecondary,
  };

  /// Roles a SUPER_ADMIN can assign from the app. Excludes SUPER_ADMIN, which
  /// the backend reserves for `POST /setup/init` (API Plan §2.4), matching the
  /// backend's own `ASSIGNABLE_ROLES` allow-list.
  static const List<UserRole> assignableRoles = <UserRole>[
    UserRole.viewer,
    UserRole.statistician,
    UserRole.coach,
    UserRole.clubAdmin,
  ];

  static String labelOf(UserRole role) => labels[role] ?? role.name;

  static Color colorOf(UserRole role) => colors[role] ?? AppColors.textSecondary;
}
