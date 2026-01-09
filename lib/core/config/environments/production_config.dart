class ProductionConfig {
  static const String baseUrl = 'https://api.nookly.app/api';
  static const String socketUrl = 'wss://api.nookly.app';
  static const bool enableLogging = false;
  static const bool enableDebugMode = false;
  
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