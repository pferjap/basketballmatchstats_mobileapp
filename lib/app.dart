import 'package:flutter/material.dart';

import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';

/// Root widget of the HoopAnalytics application.
///
/// The visual design system (theme, colors, typography) is introduced in a
/// later task. For now this provides a minimal, runnable [MaterialApp] shell so
/// the different entry points (`main_dev`, `main_staging`, `main_prod`) share a
/// single application root. Environment values are read from [EnvConfig], which
/// must be initialized before the app is built.
class HoopAnalyticsApp extends StatelessWidget {
  const HoopAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoopAnalytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final config = EnvConfig.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('HoopAnalytics')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('HoopAnalytics — ${config.environment.name}'),
            const SizedBox(height: 8),
            Text(config.baseUrl),
          ],
        ),
      ),
    );
  }
}
