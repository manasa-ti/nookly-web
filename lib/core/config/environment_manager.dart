import 'environments/development_config.dart';
import 'environments/staging_config.dart';
import 'environments/production_config.dart';

enum Environment { development, staging, production }

class EnvironmentManager {
  static Environment _environment = Environment.development;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  static Environment get currentEnvironment {
    // Try to detect environment from build configuration
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    switch (environment) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      case 'development':
      default:
        return Environment.development;
    }
  }
  
  static String get baseUrl {
    final env = _environment != Environment.development ? _environment : currentEnvironment;
    switch (env) {
      case Environment.development:
        return DevelopmentConfig.baseUrl;
      case Environment.staging:
        return StagingConfig.baseUrl;
      case Environment.production:
        return ProductionConfig.baseUrl;
    }
  }
  
  static String get socketUrl {
    final env = _environment != Environment.development ? _environment : currentEnvironment;
    switch (env) {
      case Environment.development:
        return DevelopmentConfig.socketUrl;
      case Environment.staging:
        return StagingConfig.socketUrl;
      case Environment.production:
        return ProductionConfig.socketUrl;
    }
  }
  
  static bool get enableLogging {
    final env = _environment != Environment.development ? _environment : currentEnvironment;
    switch (env) {
      case Environment.development:
        return DevelopmentConfig.enableLogging;
      case Environment.staging:
        return StagingConfig.enableLogging;
      case Environment.production:
        return ProductionConfig.enableLogging;
    }
  }
  
  static bool get enableDebugMode {
    final env = _environment != Environment.development ? _environment : currentEnvironment;
    switch (env) {
      case Environment.development:
        return DevelopmentConfig.enableDebugMode;
      case Environment.staging:
        return StagingConfig.enableDebugMode;
      case Environment.production:
        return ProductionConfig.enableDebugMode;
    }
  }
  
  /// Whether analytics should be enabled
  /// Enabled in all environments (separate Firebase projects per environment)
  static bool get enableAnalytics {
    return true;
  }
  
  /// Whether crash reporting should be enabled
  /// Enabled in all environments (separate Firebase projects per environment)
  static bool get enableCrashReporting {
    return true;
  }
} 