import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/team.dart';

/// List row for a team inside the admin panel (Plan.md T-028).
class TeamCard extends StatelessWidget {
  const TeamCard({
    required this.team,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Team team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
      child: Row(
        children: <Widget>[
          _TeamCrest(logoUrl: team.logoUrl, name: team.name),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  team.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (team.clubName != null) ...<Widget>[
                  const SizedBox(height: kSpacingXS),
                  _IconLine(icon: Icons.shield_outlined, text: team.clubName!),
                ],
                if (team.category != null) ...<Widget>[
                  const SizedBox(height: kSpacingXS),
                  _IconLine(
                    icon: Icons.emoji_events_outlined,
                    text: team.category!,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            tooltip: 'Más acciones',
            color: AppColors.surface,
            onSelected: (String value) {
              if (value == 'edit') {
                onEdit();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text(
                  'Editar',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
            tooltip: 'Eliminar ${team.name}',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _TeamCrest extends StatelessWidget {
  const _TeamCrest({required this.logoUrl, required this.name});

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final logoUrl = this.logoUrl;
    if (logoUrl == null || logoUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.background,
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) => const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.background,
        ),
        errorWidget: (BuildContext context, String url, Object error) =>
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.background,
              child: Icon(
                Icons.groups_outlined,
                color: AppColors.textSecondary,
              ),
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
    return Row(
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
          ),
        ),
      ],
    );
  }
}
