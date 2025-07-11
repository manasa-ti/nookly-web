# Environment Configuration Setup

This document explains how to use the new environment configuration system for the Nookly app.

## Overview

The app now supports three different environments:
- **Development**: `https://dev.nookly.app/api`
- **Staging**: `https://staging-api.nookly.app/api`
- **Production**: `https://api.nookly.app/api`

## Environment Configuration

The app uses Dart environment variables to manage different environments:

- `development` - Development environment
- `staging` - Staging environment  
- `production` - Production environment

### Building for Different Environments

#### Using the Build Script
```bash
# Development
./build_scripts.sh dev

# Staging
./build_scripts.sh staging

# Production
./build_scripts.sh prod
```

#### Manual Build Commands
```bash
# Development
flutter build apk --dart-define=ENVIRONMENT=development
flutter build ios --dart-define=ENVIRONMENT=development

# Staging
flutter build apk --dart-define=ENVIRONMENT=staging
flutter build ios --dart-define=ENVIRONMENT=staging

# Production
flutter build apk --dart-define=ENVIRONMENT=production
flutter build ios --dart-define=ENVIRONMENT=production
```

#### Running in Debug Mode
```bash
# Development (default)
flutter run

# Staging
flutter run --dart-define=ENVIRONMENT=staging

# Production
flutter run --dart-define=ENVIRONMENT=production
```

## Configuration Files

The environment configuration is managed through the following files:

- `lib/core/config/environment_manager.dart` - Main environment manager
- `lib/core/config/environments/development_config.dart` - Development settings
- `lib/core/config/environments/staging_config.dart` - Staging settings
- `lib/core/config/environments/production_config.dart` - Production settings

## Environment Detection

The app automatically detects the current environment based on the build configuration. The `EnvironmentManager` class provides:

- `EnvironmentManager.baseUrl` - API base URL for the current environment
- `EnvironmentManager.socketUrl` - WebSocket URL for the current environment
- `EnvironmentManager.enableLogging` - Whether logging is enabled
- `EnvironmentManager.enableDebugMode` - Whether debug mode is enabled

## Usage in Code

The existing code has been updated to use the environment configuration automatically. The `NetworkService` and `SocketService` now use the appropriate URLs based on the build environment.

## Adding New Environment-Specific Settings

To add new environment-specific settings:

1. Add the setting to each environment config file
2. Add a getter method to `EnvironmentManager`
3. Use `EnvironmentManager.yourSetting` in your code

Example:
```dart
// In development_config.dart
static const String customSetting = 'dev_value';

// In environment_manager.dart
static String get customSetting {
  final env = _environment != Environment.development ? _environment : currentEnvironment;
  switch (env) {
    case Environment.development:
      return DevelopmentConfig.customSetting;
    // ... other cases
  }
}
``` 