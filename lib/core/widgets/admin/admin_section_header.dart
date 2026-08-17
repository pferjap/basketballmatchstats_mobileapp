import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/ui_constants.dart';

/// Section title plus a primary "create" action, shared by every admin panel
/// tab (Plan.md T-026).
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    required this.title,
    required this.createLabel,
    required this.onCreate,
    super.key,
  });

  /// Section title, e.g. "Clubs".
  final String title;

  /// Label of the create button, e.g. "Crear club".
  final String createLabel;

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: kSpacingS),
        SizedBox(
          height: kMinTouchTarget,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(createLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
