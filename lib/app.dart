import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

/// Root widget of the HoopAnalytics application.
///
/// Wires the shared dark [AppTheme] to a router-driven [MaterialApp] whose
/// route tree and auth/role guards live in [goRouterProvider]. On startup it
/// attempts to restore a cached session so returning users skip the login
/// screen. The different entry points (`main_dev`, `main_staging`, `main_prod`)
/// share this single application root.
class HoopAnalyticsApp extends ConsumerStatefulWidget {
  const HoopAnalyticsApp({super.key});

  @override
  ConsumerState<HoopAnalyticsApp> createState() => _HoopAnalyticsAppState();
}

class _HoopAnalyticsAppState extends ConsumerState<HoopAnalyticsApp> {
  @override
  void initState() {
    super.initState();
    // Best-effort session restore; the router redirects once state settles.
    Future.microtask(
      () => ref.read(authStateProvider.notifier).restoreSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'HoopAnalytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
