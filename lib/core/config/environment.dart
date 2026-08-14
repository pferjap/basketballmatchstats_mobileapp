/// Application runtime environments.
///
/// Each value maps to an independent configuration (base URLs, feature flags)
/// resolved by [EnvConfig]. See Agent_Mobile.md §11.
enum Environment { dev, staging, prod }
