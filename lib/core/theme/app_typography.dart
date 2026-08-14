import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles for the HoopAnalytics design system.
///
/// - [headline]: large scoreboard / marker figures.
/// - [title]: section and page titles.
/// - [body]: default running text.
/// - [caption]: secondary / muted supporting text.
///
/// See Plan.md T-004.
abstract final class AppTypography {
  /// Large scoreboard figures (e.g. the live score marker).
  static const TextStyle headline = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  /// Section and page titles.
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Default body text.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Secondary / muted supporting text.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textSecondary,
  );
}
