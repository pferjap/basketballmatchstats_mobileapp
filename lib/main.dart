import 'package:flutter/material.dart';

import 'app.dart';

/// Default entry point. Points to the development configuration.
///
/// Use `main_dev.dart`, `main_staging.dart` or `main_prod.dart` to target a
/// specific environment explicitly.
void main() {
  runApp(const HoopAnalyticsApp(environmentLabel: 'dev'));
}
