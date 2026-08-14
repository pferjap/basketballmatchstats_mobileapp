import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/config/environment.dart';

/// Default entry point. Points to the development configuration.
///
/// Use `main_dev.dart`, `main_staging.dart` or `main_prod.dart` to target a
/// specific environment explicitly.
void main() {
  EnvConfig.init(Environment.dev);
  runApp(const ProviderScope(child: HoopAnalyticsApp()));
}
