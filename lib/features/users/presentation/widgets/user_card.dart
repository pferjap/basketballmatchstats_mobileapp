import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/app_user.dart';
import 'role_display.dart';

/// List row for a registered user (Plan.md T-034).
///
/// Shows the avatar (initials fallback), full name, email, a coloured role
/// chip, the club name (or "Sin club"), the sign-up age, and the "Cambiar rol"
/// / "Asignar club" actions.
class UserCard extends StatelessWidget {
  const UserCard({
    required this.user,
    required this.onChangeRole,
    required this.onAssignClub,
    super.key,
  });

  final AppUser user;
  final VoidCallback onChangeRole;
  final VoidCallback onAssignClub;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingS),
      padding: const EdgeInsets.all(kSpacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Avatar(user: user),
              const SizedBox(width: kSpacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.fullName.isEmpty ? user.email : user.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
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
                  ],
                ),
              ),
              _RoleChip(role: user.role),
            ],
          ),
          const SizedBox(height: kSpacingS),
          Row(
            children: <Widget>[
              _IconLine(
                icon: Icons.shield_outlined,
                text: user.clubName ?? 'Sin club',
              ),
              const SizedBox(width: kSpacingM),
              _IconLine(
                icon: Icons.schedule,
                text: _registeredAgo(user.createdAt),
              ),
            ],
          ),
          const SizedBox(height: kSpacingM),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChangeRole,
                  icon: const Icon(Icons.manage_accounts, size: 18),
                  label: const Text('Cambiar rol'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: kSpacingS),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignClub,
                  icon: const Icon(Icons.apartment, size: 18),
                  label: const Text('Asignar club'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Human-readable sign-up age, e.g. "Registrado hoy" / "Registrado hace 3
  /// días".
  static String _registeredAgo(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays >= 365) {
      final years = diff.inDays ~/ 365;
      return 'Registrado hace $years ${years == 1 ? 'año' : 'años'}';
    }
    if (diff.inDays >= 30) {
      final months = diff.inDays ~/ 30;
      return 'Registrado hace $months ${months == 1 ? 'mes' : 'meses'}';
    }
    if (diff.inDays >= 1) {
      return 'Registrado hace ${diff.inDays} '
          '${diff.inDays == 1 ? 'día' : 'días'}';
    }
    if (diff.inHours >= 1) {
      return 'Registrado hace ${diff.inHours} '
          '${diff.inHours == 1 ? 'hora' : 'horas'}';
    }
    return 'Registrado hoy';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (context, url) => _initialsAvatar(),
          errorWidget: (context, url, error) => _initialsAvatar(),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: RoleDisplay.colorOf(user.role).withValues(alpha: 0.2),
      child: Text(
        user.initials,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final color = RoleDisplay.colorOf(role);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingS,
        vertical: kSpacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        RoleDisplay.labelOf(role),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: kSpacingXS),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
