import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/ui_constants.dart';

/// "Mostrando X - Y de Z" plus numeric page controls, shared by every admin
/// panel tab (Plan.md T-026).
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    required this.page,
    required this.limit,
    required this.total,
    required this.onPageSelected,
    required this.itemNoun,
    super.key,
  });

  /// Current 1-based page.
  final int page;

  /// Page size.
  final int limit;

  /// Total number of items across all pages.
  final int total;

  final ValueChanged<int> onPageSelected;

  /// Plural noun used in the summary, e.g. "clubes".
  final String itemNoun;

  int get _pageCount => total <= 0 ? 1 : ((total - 1) ~/ limit) + 1;

  /// Page numbers to render: a window around the current page so the control
  /// stays a fixed width no matter how many pages exist.
  List<int> get _visiblePages {
    final count = _pageCount;
    if (count <= 5) {
      return List<int>.generate(count, (int i) => i + 1);
    }
    final start = (page - 2).clamp(1, count - 4);
    return List<int>.generate(5, (int i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final first = ((page - 1) * limit) + 1;
    final last = (page * limit).clamp(first, total);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpacingS),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: kSpacingS,
        children: <Widget>[
          Text(
            'Mostrando $first - $last de $total $itemNoun',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ArrowButton(
                icon: Icons.chevron_left,
                tooltip: 'Página anterior',
                onPressed: page > 1 ? () => onPageSelected(page - 1) : null,
              ),
              for (final int p in _visiblePages)
                _PageButton(
                  page: p,
                  selected: p == page,
                  onPressed: () => onPageSelected(p),
                ),
              _ArrowButton(
                icon: Icons.chevron_right,
                tooltip: 'Página siguiente',
                onPressed: page < _pageCount
                    ? () => onPageSelected(page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.textSecondary,
      disabledColor: AppColors.divider,
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.onPressed,
  });

  final int page;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: 'Página $page',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacingXS),
        child: SizedBox(
          width: kMinTouchTarget,
          height: kMinTouchTarget,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: selected
                  ? AppColors.info
                  : AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: selected ? AppColors.info : Colors.transparent,
                ),
              ),
            ),
            child: Text('$page'),
          ),
        ),
      ),
    );
  }
}
