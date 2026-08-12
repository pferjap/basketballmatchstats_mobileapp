import 'package:flutter/material.dart';

/// Root widget of the HoopAnalytics application.
///
/// The visual design system (theme, colors, typography) is introduced in a
/// later task. For now this provides a minimal, runnable [MaterialApp] shell so
/// the different entry points (`main_dev`, `main_staging`, `main_prod`) share a
/// single application root.
class HoopAnalyticsApp extends StatelessWidget {
  const HoopAnalyticsApp({super.key, this.environmentLabel = 'dev'});

  /// Human-readable label of the active environment, shown while the real
  /// environment configuration is not yet wired up.
  final String environmentLabel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoopAnalytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF5A623)),
        useMaterial3: true,
      ),
      home: _PlaceholderHome(environmentLabel: environmentLabel),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome({required this.environmentLabel});

  final String environmentLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HoopAnalytics')),
      body: Center(
        child: Text('HoopAnalytics — $environmentLabel'),
      ),
    );
  }
}
