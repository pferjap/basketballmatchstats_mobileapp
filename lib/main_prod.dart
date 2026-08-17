import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/config/environment.dart';

/// Production entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.init(Environment.prod);
  runApp(const ProviderScope(child: HoopAnalyticsApp()));
}
