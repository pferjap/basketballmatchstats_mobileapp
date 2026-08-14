import 'package:flutter/material.dart';

/// Semantic color palette for the HoopAnalytics dark theme.
///
/// Derived from the app's screen designs: dark background with orange accents,
/// green for made baskets / connected state, and red for fouls / errors.
/// See Agent_Mobile.md and Plan.md T-004.
abstract final class AppColors {
  /// Primary dark background.
  static const Color background = Color(0xFF0D1117);

  /// Cards and containers surface.
  static const Color surface = Color(0xFF1C2128);

  /// Primary accent (orange) — main button, highlights.
  static const Color primary = Color(0xFFF5A623);

  /// Success (green) — made baskets, connected status.
  static const Color success = Color(0xFF4CAF50);

  /// Error (red) — fouls, errors.
  static const Color error = Color(0xFFE53935);

  /// Warning (light orange) — reconnecting status.
  static const Color warning = Color(0xFFFF9800);

  /// Primary text color.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary / muted text color.
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// Divider / border color.
  static const Color divider = Color(0xFF2D333B);
}
