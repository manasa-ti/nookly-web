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

  /// Initialize Remote Config with defaults only (no network fetch)
  /// This allows the app to start immediately with default values,
  /// while Remote Config can be fetched in the background later
  Future<void> initializeDefaultsOnly() async {
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

      // Don't fetch yet - just mark as initialized with defaults
      _isInitialized = true;
      AppLogger.info('✅ Remote Config initialized with defaults (fetch deferred)');
    } catch (e) {
      AppLogger.error('Failed to initialize Remote Config defaults', e);
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
    AppLogger.debug('📊 [REMOTE_CONFIG] Checking global screenshot protection...');
    AppLogger.debug('📊 [REMOTE_CONFIG] Remote Config initialized: $_isInitialized');
    AppLogger.debug('📊 [REMOTE_CONFIG] Remote Config instance: ${_remoteConfig != null}');
    
    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.warning('📊 [REMOTE_CONFIG] ⚠️ Remote Config not initialized, using default: true');
      return true; // Default to enabled for security
    }

    try {
      final enabled = _remoteConfig!.getBool(_enableScreenshotProtectionKey);
      AppLogger.debug('📊 [REMOTE_CONFIG] Screenshot protection enabled (global): $enabled');
      AppLogger.debug('📊 [REMOTE_CONFIG] Config key used: $_enableScreenshotProtectionKey');
      return enabled;
    } catch (e, stackTrace) {
      AppLogger.error('📊 [REMOTE_CONFIG] ❌ Error reading screenshot protection config', e, stackTrace);
      AppLogger.error('📊 [REMOTE_CONFIG] Error type: ${e.runtimeType}');
      return true; // Default to enabled
    }
  }

  /// Check if a specific screen should be protected
  /// 
  /// [screenType] should be one of: 'video_call', 'chat', 'profile'
  bool shouldProtectScreen(String screenType) {
    AppLogger.debug('📊 [REMOTE_CONFIG] Checking protection for screen: $screenType');
    
    final globalEnabled = isScreenshotProtectionEnabled();
    if (!globalEnabled) {
      AppLogger.debug('📊 [REMOTE_CONFIG] Screenshot protection globally disabled - returning false');
      return false;
    }

    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.warning('📊 [REMOTE_CONFIG] ⚠️ Remote Config not initialized, using default: true');
      return true;
    }

    try {
      bool shouldProtect = false;
      String? configKey;

      switch (screenType.toLowerCase()) {
        case 'video_call':
        case 'call':
          configKey = _protectVideoCallsKey;
          shouldProtect = _remoteConfig!.getBool(_protectVideoCallsKey);
          break;
        case 'chat':
        case 'chat_screen':
          configKey = _protectChatScreenKey;
          shouldProtect = _remoteConfig!.getBool(_protectChatScreenKey);
          break;
        case 'profile':
        case 'profile_pages':
          configKey = _protectProfilePagesKey;
          shouldProtect = _remoteConfig!.getBool(_protectProfilePagesKey);
          break;
        default:
          AppLogger.warning('📊 [REMOTE_CONFIG] ⚠️ Unknown screen type: $screenType - defaulting to protected');
          return true; // Default to protected for unknown types
      }

      AppLogger.debug('📊 [REMOTE_CONFIG] Screen type: $screenType');
      AppLogger.debug('📊 [REMOTE_CONFIG] Config key: $configKey');
      AppLogger.debug('📊 [REMOTE_CONFIG] Should protect: $shouldProtect');
      return shouldProtect;
    } catch (e, stackTrace) {
      AppLogger.error('📊 [REMOTE_CONFIG] ❌ Error reading screen protection config for $screenType', e, stackTrace);
      AppLogger.error('📊 [REMOTE_CONFIG] Error type: ${e.runtimeType}');
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

