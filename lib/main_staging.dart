import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/config/environment.dart';

/// Staging entry point.
void main() {
  EnvConfig.init(Environment.staging);
  runApp(const ProviderScope(child: HoopAnalyticsApp()));
}
