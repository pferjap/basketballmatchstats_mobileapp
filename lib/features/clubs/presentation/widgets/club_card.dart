import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../domain/entities/club.dart';

/// List row for a club inside the admin panel (Plan.md T-026).
///
/// Shows the crest, name, location and founding year, plus an overflow menu
/// (edit) and a destructive delete button.
class ClubCard extends StatelessWidget {
  const ClubCard({
    required this.club,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Club club;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String? get _location {
    final parts = <String>[?club.city, ?club.country];
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
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
          _ClubCrest(logoUrl: club.logoUrl, name: club.name),
          const SizedBox(width: kSpacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  club.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (location != null) ...<Widget>[
                  const SizedBox(height: kSpacingXS),
                  _IconLine(icon: Icons.location_on_outlined, text: location),
                ],
                if (club.foundedYear != null) ...<Widget>[
                  const SizedBox(height: kSpacingXS),
                  _IconLine(
                    icon: Icons.calendar_today_outlined,
                    text: 'Desde ${club.foundedYear}',
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
            tooltip: 'Eliminar ${club.name}',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ClubCrest extends StatelessWidget {
  const _ClubCrest({required this.logoUrl, required this.name});

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
                Icons.shield_outlined,
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
