import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/ui_constants.dart';

/// Labelled dropdown used by the admin create/edit forms (Plan.md T-028 to
/// T-030), styled to match [AdminFormField].
///
/// [items] maps each selectable value to the label shown for it.
class AdminDropdownField<T> extends StatelessWidget {
  const AdminDropdownField({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    super.key,
  });

  /// Caption rendered above the dropdown.
  final String label;

  /// Selectable values mapped to their display labels.
  final Map<T, String> items;

  /// Currently selected value, or `null` when nothing is chosen yet.
  final T? value;

  final ValueChanged<T?> onChanged;

  /// Placeholder shown while [value] is null.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpacingXS),
          DropdownButtonFormField<T>(
            initialValue: value,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary),
            hint: hint == null
                ? null
                : Text(
                    hint!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: kSpacingM,
                horizontal: kSpacingM,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.info),
              ),
            ),
            items: <DropdownMenuItem<T>>[
              for (final MapEntry<T, String> entry in items.entries)
                DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
