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
  static const String _androidAppLinkKey = 'android_app_link';
  static const String _iosAppLinkKey = 'ios_app_link';
  static const String _callsEnabledKey = 'calls_enabled';

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
        _androidAppLinkKey: '',
        _iosAppLinkKey: '',
        _callsEnabledKey: true,
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
        _androidAppLinkKey: '',
        _iosAppLinkKey: '',
        _callsEnabledKey: true,
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

    AppLogger.info('🔄 [REMOTE_CONFIG] Starting fetch and activate...');
    AppLogger.info('🔄 [REMOTE_CONFIG] Remote Config instance: ${_remoteConfig != null}');
    AppLogger.info('🔄 [REMOTE_CONFIG] Is initialized: $_isInitialized');
    
    try {
      AppLogger.info('🔄 [REMOTE_CONFIG] Calling fetchAndActivate()...');
      final activated = await _remoteConfig!.fetchAndActivate();
      
      AppLogger.info('🔄 [REMOTE_CONFIG] fetchAndActivate() completed');
      AppLogger.info('🔄 [REMOTE_CONFIG] Activated: $activated');
      
      if (activated) {
        AppLogger.info('✅ Remote Config values fetched and activated');
      } else {
        AppLogger.info('ℹ️ Remote Config fetch completed, no new values activated (using cached/current values)');
      }
      
      // Always log current values after fetch, regardless of whether they were newly activated
      AppLogger.info('🔄 [REMOTE_CONFIG] Logging current values...');
      _logCurrentValues();
      
      // Verify the calls_enabled value specifically
      try {
        final callsEnabledValue = _remoteConfig!.getBool(_callsEnabledKey);
        AppLogger.info('🔍 [REMOTE_CONFIG] Verified calls_enabled value: $callsEnabledValue');
      } catch (e, stackTrace) {
        AppLogger.error('🔍 [REMOTE_CONFIG] Error verifying calls_enabled value', e, stackTrace);
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ [REMOTE_CONFIG] Failed to fetch Remote Config', e, stackTrace);
      AppLogger.error('❌ [REMOTE_CONFIG] Error type: ${e.runtimeType}');
      AppLogger.error('❌ [REMOTE_CONFIG] Error message: ${e.toString()}');
      
      // Check if it's a network error
      if (e.toString().contains('network') || e.toString().contains('timeout') || e.toString().contains('connection')) {
        AppLogger.error('❌ [REMOTE_CONFIG] Network/connection error detected');
      }
      
      // Check if it's a Firebase error
      if (e.toString().contains('firebase') || e.toString().contains('Firebase')) {
        AppLogger.error('❌ [REMOTE_CONFIG] Firebase-specific error detected');
      }
      
      // Continue with cached/default values
      AppLogger.warning('⚠️ [REMOTE_CONFIG] Using cached/default values due to fetch failure');
      // Still log current values (which will be defaults)
      _logCurrentValues();
    }
  }

  /// Check if screenshot protection is globally enabled
  bool isScreenshotProtectionEnabled() {
    if (_remoteConfig == null || !_isInitialized) {
      return true; // Default to enabled for security
    }

    try {
      final enabled = _remoteConfig!.getBool(_enableScreenshotProtectionKey);
      return enabled;
    } catch (e, stackTrace) {
      AppLogger.error('Error reading screenshot protection config', e, stackTrace);
      return true; // Default to enabled
    }
  }

  /// Check if a specific screen should be protected
  /// 
  /// [screenType] should be one of: 'video_call', 'chat', 'profile'
  bool shouldProtectScreen(String screenType) {
    final globalEnabled = isScreenshotProtectionEnabled();
    if (!globalEnabled) {
      return false;
    }

    if (_remoteConfig == null || !_isInitialized) {
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
          return true; // Default to protected for unknown types
      }

      return shouldProtect;
    } catch (e, stackTrace) {
      AppLogger.error('Error reading screen protection config for $screenType', e, stackTrace);
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
    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.info('📊 Remote Config values (using defaults):');
      AppLogger.info('  enable_screenshot_protection: true');
      AppLogger.info('  protect_video_calls: true');
      AppLogger.info('  protect_chat_screen: true');
      AppLogger.info('  protect_profile_pages: true');
      AppLogger.info('  android_app_link: ""');
      AppLogger.info('  ios_app_link: ""');
      AppLogger.info('  calls_enabled: true');
      return;
    }

    try {
      AppLogger.info('📊 Remote Config values fetched:');
      
      // Get each value individually with error handling
      try {
        final enableScreenshot = _remoteConfig!.getBool(_enableScreenshotProtectionKey);
        AppLogger.info('  enable_screenshot_protection: $enableScreenshot');
      } catch (e) {
        AppLogger.warning('  enable_screenshot_protection: error reading value - $e');
      }
      
      try {
        final protectVideoCalls = _remoteConfig!.getBool(_protectVideoCallsKey);
        AppLogger.info('  protect_video_calls: $protectVideoCalls');
      } catch (e) {
        AppLogger.warning('  protect_video_calls: error reading value - $e');
      }
      
      try {
        final protectChatScreen = _remoteConfig!.getBool(_protectChatScreenKey);
        AppLogger.info('  protect_chat_screen: $protectChatScreen');
      } catch (e) {
        AppLogger.warning('  protect_chat_screen: error reading value - $e');
      }
      
      try {
        final protectProfilePages = _remoteConfig!.getBool(_protectProfilePagesKey);
        AppLogger.info('  protect_profile_pages: $protectProfilePages');
      } catch (e) {
        AppLogger.warning('  protect_profile_pages: error reading value - $e');
      }
      
      try {
        final androidAppLink = _remoteConfig!.getString(_androidAppLinkKey);
        AppLogger.info('  android_app_link: "$androidAppLink"');
      } catch (e) {
        AppLogger.warning('  android_app_link: error reading value - $e');
      }
      
      try {
        final iosAppLink = _remoteConfig!.getString(_iosAppLinkKey);
        AppLogger.info('  ios_app_link: "$iosAppLink"');
      } catch (e) {
        AppLogger.warning('  ios_app_link: error reading value - $e');
      }
      
      try {
        final callsEnabled = _remoteConfig!.getBool(_callsEnabledKey);
        AppLogger.info('  calls_enabled: $callsEnabled');
      } catch (e) {
        AppLogger.warning('  calls_enabled: error reading value - $e');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error logging Remote Config values', e, stackTrace);
    }
  }

  /// Check if Remote Config is initialized
  bool get isInitialized => _isInitialized;

  /// Get Android app store link from Remote Config
  String getAndroidAppLink() {
    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.warning('Remote Config not initialized, returning empty string for Android app link');
      return '';
    }

    try {
      final link = _remoteConfig!.getString(_androidAppLinkKey);
      AppLogger.info('Android app link from Remote Config: $link');
      return link;
    } catch (e) {
      AppLogger.error('Error reading Android app link from Remote Config', e);
      return '';
    }
  }

  /// Get iOS app store link from Remote Config
  String getIosAppLink() {
    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.warning('Remote Config not initialized, returning empty string for iOS app link');
      return '';
    }

    try {
      final link = _remoteConfig!.getString(_iosAppLinkKey);
      AppLogger.info('iOS app link from Remote Config: $link');
      return link;
    } catch (e) {
      AppLogger.error('Error reading iOS app link from Remote Config', e);
      return '';
    }
  }

  /// Check if calls (audio and video) are enabled
  bool isCallsEnabled() {
    AppLogger.info('🔍 [REMOTE_CONFIG] isCallsEnabled() called');
    AppLogger.info('🔍 [REMOTE_CONFIG] _remoteConfig is null: ${_remoteConfig == null}');
    AppLogger.info('🔍 [REMOTE_CONFIG] _isInitialized: $_isInitialized');
    
    if (_remoteConfig == null || !_isInitialized) {
      AppLogger.warning('Remote Config not initialized, using default: false for calls_enabled');
      return false; // Default to disabled
    }

    try {
      AppLogger.info('🔍 [REMOTE_CONFIG] Reading calls_enabled from remote config...');
      final enabled = _remoteConfig!.getBool(_callsEnabledKey);
      AppLogger.info('🔍 [REMOTE_CONFIG] Calls enabled value read: $enabled');
      AppLogger.info('🔍 [REMOTE_CONFIG] Returning: $enabled');
      return enabled;
    } catch (e, stackTrace) {
      AppLogger.error('❌ [REMOTE_CONFIG] Error reading calls_enabled from Remote Config', e, stackTrace);
      AppLogger.error('❌ [REMOTE_CONFIG] Error type: ${e.runtimeType}');
      AppLogger.error('❌ [REMOTE_CONFIG] Error message: ${e.toString()}');
      return false; // Default to disabled on error
    }
  }
}

