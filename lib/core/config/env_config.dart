import 'environment.dart';

/// Immutable, per-environment configuration singleton.
///
/// Initialize once from an entry point via [EnvConfig.init] before calling
/// `runApp`, then read the active configuration through [EnvConfig.instance].
/// See Agent_Mobile.md §11.
class EnvConfig {
  const EnvConfig._({
    required this.environment,
    required this.baseUrl,
    required this.wsUrl,
    required this.enableOfflineMode,
    required this.enableShotChart,
    required this.enableAnalyticsModule,
  });

  /// Active environment.
  final Environment environment;

  /// REST API base URL (includes the `/api/v1` prefix).
  final String baseUrl;

  /// WebSocket gateway URL.
  final String wsUrl;

  /// Enables offline-first annotation (local event queue).
  final bool enableOfflineMode;

  /// Enables the interactive shot chart on the Court View.
  final bool enableShotChart;

  /// Enables the (future) BI/analytics module scaffold.
  final bool enableAnalyticsModule;

  static EnvConfig? _instance;

  /// Whether [init] has already been called.
  static bool get isInitialized => _instance != null;

  /// The active configuration. Throws [StateError] if [init] was not called.
  static EnvConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'EnvConfig has not been initialized. Call EnvConfig.init() from your '
        'entry point before accessing EnvConfig.instance.',
      );
    }
    return config;
  }

  /// Initializes the singleton for the given [environment].
  ///
  /// Safe to call multiple times (e.g. in tests); the latest call wins.
  static void init(Environment environment) {
    _instance = _configFor(environment);
  }

  static EnvConfig _configFor(Environment environment) {
    switch (environment) {
      case Environment.dev:
        return const EnvConfig._(
          environment: Environment.dev,
          baseUrl: 'http://10.0.2.2:3001/',
          wsUrl: 'ws://10.0.2.2:3001',
          enableOfflineMode: true,
          enableShotChart: true,
          enableAnalyticsModule: true,
        );
      case Environment.staging:
        return const EnvConfig._(
          environment: Environment.staging,
          baseUrl: 'https://staging-api.hoopanalytics.com/api/v1',
          wsUrl: 'wss://staging-api.hoopanalytics.com',
          enableOfflineMode: true,
          enableShotChart: true,
          enableAnalyticsModule: false,
        );
      case Environment.prod:
        return const EnvConfig._(
          environment: Environment.prod,
          baseUrl: 'https://basketballmatchstats-latest.onrender.com/',
          wsUrl: 'wss://basketballmatchstats-latest.onrender.com/',
          enableOfflineMode: true,
          enableShotChart: true,
          enableAnalyticsModule: false,
        );
    }
  }
}
