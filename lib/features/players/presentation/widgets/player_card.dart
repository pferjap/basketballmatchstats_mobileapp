import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/player.dart';
import '../providers/player_form_provider.dart';

/// List row for a player inside the admin panel (Plan.md T-029).
class PlayerCard extends StatelessWidget {
  const PlayerCard({
    required this.player,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Player player;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// "#7 · Base" — whichever of the two is known.
  String? get _numberAndPosition {
    final parts = <String>[
      if (player.jerseyNumber != null) '#${player.jerseyNumber}',
      ?kPlayerPositionLabels[player.position],
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final numberAndPosition = _numberAndPosition;
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
          _PlayerAvatar(photoUrl: player.photoUrl, name: player.fullName),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  player.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (numberAndPosition != null) ...<Widget>[
                  const SizedBox(height: kSpacingXS),
                  Text(
                    numberAndPosition,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (player.teamName != null) ...<Widget>[
                  const SizedBox(height: kSpacingXS),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.groups_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: kSpacingXS),
                      Expanded(
                        child: Text(
                          player.teamName!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
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
            tooltip: 'Eliminar ${player.fullName}',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final photoUrl = this.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
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
        imageUrl: photoUrl,
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
              child: Icon(Icons.person_outline, color: AppColors.textSecondary),
            ),
      ),
    );
  }
}
