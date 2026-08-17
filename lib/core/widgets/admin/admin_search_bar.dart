import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/ui_constants.dart';

/// Search field plus a "Filtros" button, shared by every admin panel tab
/// (Plan.md T-026).
///
/// Keystrokes are debounced before [onSearchChanged] fires so typing does not
/// issue one request per character.
class AdminSearchBar extends StatefulWidget {
  const AdminSearchBar({
    required this.hintText,
    required this.onSearchChanged,
    this.onFiltersPressed,
    this.debounce = const Duration(milliseconds: 300),
    super.key,
  });

  /// Placeholder shown while the field is empty, e.g. "Buscar club...".
  final String hintText;

  /// Called with the trimmed query once the user stops typing.
  final ValueChanged<String> onSearchChanged;

  /// Optional handler for the filters button; the button is hidden when null.
  final VoidCallback? onFiltersPressed;

  /// How long to wait after the last keystroke before searching.
  final Duration debounce;

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      widget.onSearchChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: kSpacingS,
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
          ),
        ),
        if (widget.onFiltersPressed != null) ...<Widget>[
          const SizedBox(width: kSpacingS),
          SizedBox(
            height: kMinTouchTarget,
            child: OutlinedButton.icon(
              onPressed: widget.onFiltersPressed,
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filtros'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
