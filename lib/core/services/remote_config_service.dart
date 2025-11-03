import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:nookly/core/utils/logger.dart';

/// Service for managing Firebase Remote Config
/// Used to remotely control app features without requiring app updates
class RemoteConfigService {
  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  // Remote Config Keys
  static const String _enableScreenshotProtectionKey = 'enable_screenshot_protection';
  static const String _protectVideoCallsKey = 'protect_video_calls';
  static const String _protectChatScreenKey = 'protect_chat_screen';
  static const String _protectProfilePagesKey = 'protect_profile_pages';

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    if (_isInitialized && _remoteConfig != null) {
      AppLogger.info('Remote Config already initialized');
      return;
    }

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values for development/fallback
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set default parameter values
      await _remoteConfig!.setDefaults({
        _enableScreenshotProtectionKey: true,
        _protectVideoCallsKey: true,
        _protectChatScreenKey: true,
        _protectProfilePagesKey: true,
      });

      // Fetch and activate
      await fetchAndActivate();

      _isInitialized = true;
      AppLogger.info('✅ Remote Config initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize Remote Config', e);
      // Continue with defaults if Remote Config fails
      _isInitialized = false;
    }
  }

  /// Fetch latest configuration from Firebase and activate it
  Future<void> fetchAndActivate() async {
    if (_remoteConfig == null) {
      AppLogger.warning('Remote Config not initialized, using defaults');
      return;
    }

    try {
      final activated = await _remoteConfig!.fetchAndActivate();
      if (activated) {
        AppLogger.info('✅ Remote Config values fetched and activated');
        _logCurrentValues();
      } else {
        AppLogger.info('Remote Config fetch completed, no new values activated');
      }
    } catch (e) {
      AppLogger.error('Failed to fetch Remote Config', e);
      // Continue with cached/default values
    }
  }

  /// Check if screenshot protection is globally enabled
  bool isScreenshotProtectionEnabled() {
    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.warning('Remote Config not initialized, using default: true');
      return true; // Default to enabled for security
    }

    try {
      final enabled = _remoteConfig!.getBool(_enableScreenshotProtectionKey);
      AppLogger.debug('Screenshot protection enabled (global): $enabled');
      return enabled;
    } catch (e) {
      AppLogger.error('Error reading screenshot protection config', e);
      return true; // Default to enabled
    }
  }

  /// Check if a specific screen should be protected
  /// 
  /// [screenType] should be one of: 'video_call', 'chat', 'profile'
  bool shouldProtectScreen(String screenType) {
    if (!isScreenshotProtectionEnabled()) {
      AppLogger.debug('Screenshot protection globally disabled');
      return false;
    }

    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.warning('Remote Config not initialized, using default: true');
      return true;
    }

    try {
      bool shouldProtect = false;

      switch (screenType.toLowerCase()) {
        case 'video_call':
        case 'call':
          shouldProtect = _remoteConfig!.getBool(_protectVideoCallsKey);
          break;
        case 'chat':
        case 'chat_screen':
          shouldProtect = _remoteConfig!.getBool(_protectChatScreenKey);
          break;
        case 'profile':
        case 'profile_pages':
          shouldProtect = _remoteConfig!.getBool(_protectProfilePagesKey);
          break;
        default:
          AppLogger.warning('Unknown screen type: $screenType');
          return true; // Default to protected for unknown types
      }

      AppLogger.debug('Screenshot protection for $screenType: $shouldProtect');
      return shouldProtect;
    } catch (e) {
      AppLogger.error('Error reading screen protection config for $screenType', e);
      return true; // Default to protected
    }
  }

  /// Get all current protection settings (for debugging)
  Map<String, bool> getProtectionSettings() {
    if (_remoteConfig == null || !_isInitialized) {
      return {
        _enableScreenshotProtectionKey: true,
        _protectVideoCallsKey: true,
        _protectChatScreenKey: true,
        _protectProfilePagesKey: true,
      };
    }

    try {
      return {
        _enableScreenshotProtectionKey: _remoteConfig!.getBool(_enableScreenshotProtectionKey),
        _protectVideoCallsKey: _remoteConfig!.getBool(_protectVideoCallsKey),
        _protectChatScreenKey: _remoteConfig!.getBool(_protectChatScreenKey),
        _protectProfilePagesKey: _remoteConfig!.getBool(_protectProfilePagesKey),
      };
    } catch (e) {
      AppLogger.error('Error getting protection settings', e);
      return {};
    }
  }

  /// Log current Remote Config values (for debugging)
  void _logCurrentValues() {
    final settings = getProtectionSettings();
    AppLogger.info('📊 Remote Config Protection Settings:');
    settings.forEach((key, value) {
      AppLogger.info('  $key: $value');
    });
  }

  /// Check if Remote Config is initialized
  bool get isInitialized => _isInitialized;
}

