import 'package:flutter/material.dart';

import 'app.dart';

/// Staging entry point.
///
/// Full environment configuration (base URLs, feature flags) is wired in a
/// later task via `EnvConfig`. For now this simply boots the app shell.
void main() {
  runApp(const HoopAnalyticsApp(environmentLabel: 'staging'));
}
