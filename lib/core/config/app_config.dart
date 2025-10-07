/// Application configuration
/// Contains environment-specific settings and constants
class AppConfig {
  final String environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableCrashlytics;
  final int sessionTimeout;
  final int maxRetryAttempts;
  final Duration connectionTimeout;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final Map<String, dynamic>? additionalConfig;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
    this.enableLogging = false,
    this.enableCrashlytics = false,
    this.sessionTimeout = 3600, // 1 hour in seconds
    this.maxRetryAttempts = 3,
    this.connectionTimeout = const Duration(seconds: 30),
    this.additionalConfig,
  });

  /// Development configuration
  factory AppConfig.development() {
    return const AppConfig(
      environment: 'development',
      apiBaseUrl: 'https://dev-api.algebraskolan.se',
      firebaseProjectId: 'algebra-dev',
      firebaseStorageBucket: 'algebra-dev.appspot.com',
      enableLogging: true,
      enableCrashlytics: false,
      sessionTimeout: 7200, // 2 hours for development
    );
  }

  /// Staging configuration
  factory AppConfig.staging() {
    return const AppConfig(
      environment: 'staging',
      apiBaseUrl: 'https://staging-api.algebraskolan.se',
      firebaseProjectId: 'algebra-82c5d',
      firebaseStorageBucket: 'algebra-82c5d.firebasestorage.app',
      enableLogging: true,
      enableCrashlytics: true,
    );
  }

  /// Production configuration
  factory AppConfig.production() {
    return const AppConfig(
      environment: 'production',
      apiBaseUrl: 'https://api.algebraskolan.se',
      firebaseProjectId: 'algebra-82c5d',
      firebaseStorageBucket: 'algebra-82c5d.firebasestorage.app',
      enableLogging: false,
      enableCrashlytics: true,
    );
  }

  /// Test configuration
  factory AppConfig.test() {
    return const AppConfig(
      environment: 'test',
      apiBaseUrl: 'http://localhost:8080',
      firebaseProjectId: 'algebra-dev',
      firebaseStorageBucket: 'algebra-dev.appspot.com',
      enableLogging: true,
      enableCrashlytics: false,
      connectionTimeout: Duration(seconds: 5),
    );
  }

  bool get isDevelopment => environment == 'development';
  bool get isStaging => environment == 'staging';
  bool get isProduction => environment == 'production';
  bool get isTest => environment == 'test';

  @override
  String toString() {
    return 'AppConfig(environment: $environment, apiBaseUrl: $apiBaseUrl, '
           'enableLogging: $enableLogging, enableCrashlytics: $enableCrashlytics)';
  }
}

/// Global app configuration instance
late AppConfig appConfig;

/// Initialize app configuration based on environment
void initializeAppConfig(String environment) {
  switch (environment) {
    case 'development':
      appConfig = AppConfig.development();
      break;
    case 'staging':
      appConfig = AppConfig.staging();
      break;
    case 'production':
      appConfig = AppConfig.production();
      break;
    case 'test':
      appConfig = AppConfig.test();
      break;
    default:
      appConfig = AppConfig.development();
  }
}