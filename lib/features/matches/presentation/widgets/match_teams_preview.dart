import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MatchTeamsPreview extends StatelessWidget {
  const MatchTeamsPreview({
    this.homeTeamName,
    this.awayTeamName,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
    super.key,
  });

  final String? homeTeamName;
  final String? awayTeamName;
  final String? homeTeamLogoUrl;
  final String? awayTeamLogoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _TeamAvatar(
          name: homeTeamName,
          logoUrl: homeTeamLogoUrl,
          label: 'Local',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'VS',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _TeamAvatar(
          name: awayTeamName,
          logoUrl: awayTeamLogoUrl,
          label: 'Visitante',
        ),
      ],
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({this.name, this.logoUrl, required this.label});

  final String? name;
  final String? logoUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasLogo
              ? Image.network(
                  logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.groups_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  ),
                )
              : const Icon(
                  Icons.groups_outlined,
                  size: 32,
                  color: AppColors.textSecondary,
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            name ?? label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: name != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
