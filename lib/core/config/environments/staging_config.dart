class StagingConfig {
  static const String baseUrl = 'https://staging.nookly.app/api';
  static const String socketUrl = 'wss://staging.nookly.app';
  static const bool enableLogging = true;
  static const bool enableDebugMode = true;
  
  // 100ms Configuration - loaded from environment variables
  static String get hmsAppId => const String.fromEnvironment(
    'HMS_APP_ID',
    defaultValue: '',
  );
  
  static String get hmsAuthToken => const String.fromEnvironment(
    'HMS_AUTH_TOKEN',
    defaultValue: '',
  );
} 