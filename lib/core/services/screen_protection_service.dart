import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:nookly/core/services/remote_config_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/di/injection_container.dart' as di;

/// Service for managing screenshot and screen recording prevention
/// Protection is always enabled when requested, independent of Remote Config
/// Remote Config values are logged for informational purposes only
class ScreenProtectionService {
  final RemoteConfigService _remoteConfigService;
  bool _isProtectionActive = false;
  String? _currentProtectedScreen;
  DateTime? _lastProtectionEnableTime;
  DateTime? _lastProtectionDisableTime;
  MethodChannel? _screenshotChannel;
  
  // Note: screen_protector prevents screenshots/recording but doesn't provide
  // a callback. The system (Android/iOS) automatically blocks attempts and
  // may show a system message.
  // On iOS, we use UIApplicationUserDidTakeScreenshotNotification to detect
  // if screenshots are being taken despite protection being enabled.

  ScreenProtectionService({RemoteConfigService? remoteConfigService})
      : _remoteConfigService = remoteConfigService ?? di.sl<RemoteConfigService>() {
    AppLogger.info('📱 ScreenProtectionService initialized on ${Platform.isIOS ? "iOS" : Platform.isAndroid ? "Android" : "Unknown"}');
    
    // Setup screenshot detection on iOS
    if (Platform.isIOS) {
      _setupScreenshotDetection();
    }
  }
  
  /// Setup screenshot detection on iOS
  /// This will detect if screenshots are taken despite protection being enabled
  void _setupScreenshotDetection() {
    _screenshotChannel = const MethodChannel('com.nookly.app/screenshot_detection');
    _screenshotChannel!.setMethodCallHandler((call) async {
      if (call.method == 'screenshotDetected') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final timestamp = args['timestamp'] as double?;
        final message = args['message'] as String?;
        
        AppLogger.error('📸 [SCREEN_PROTECTION] ⚠️⚠️⚠️ SCREENSHOT DETECTED! ⚠️⚠️⚠️');
        AppLogger.error('📸 [SCREEN_PROTECTION] Protection is NOT working - screenshot was taken!');
        AppLogger.error('📸 [SCREEN_PROTECTION] Timestamp: ${timestamp != null ? DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt()) : "unknown"}');
        AppLogger.error('📸 [SCREEN_PROTECTION] Message: $message');
        AppLogger.error('📸 [SCREEN_PROTECTION] Current Protection State: $_isProtectionActive');
        AppLogger.error('📸 [SCREEN_PROTECTION] Protected Screen: $_currentProtectedScreen');
        AppLogger.error('📸 [SCREEN_PROTECTION] Last Enable Time: $_lastProtectionEnableTime');
        AppLogger.error('📸 [SCREEN_PROTECTION] ⚠️⚠️⚠️ PROTECTION FAILED ⚠️⚠️⚠️');
      } else if (call.method == 'screenRecordingDetected') {
        final args = call.arguments as Map<dynamic, dynamic>;
        final timestamp = args['timestamp'] as double?;
        final isRecording = args['isRecording'] as bool? ?? false;
        final message = args['message'] as String?;
        
        if (isRecording) {
          AppLogger.error('🎥 [SCREEN_PROTECTION] ⚠️⚠️⚠️ SCREEN RECORDING DETECTED! ⚠️⚠️⚠️');
          AppLogger.error('🎥 [SCREEN_PROTECTION] Protection may NOT be working - screen recording started!');
          AppLogger.error('🎥 [SCREEN_PROTECTION] Timestamp: ${timestamp != null ? DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt()) : "unknown"}');
          AppLogger.error('🎥 [SCREEN_PROTECTION] Message: $message');
          AppLogger.error('🎥 [SCREEN_PROTECTION] Current Protection State: $_isProtectionActive');
          AppLogger.error('🎥 [SCREEN_PROTECTION] Protected Screen: $_currentProtectedScreen');
          AppLogger.error('🎥 [SCREEN_PROTECTION] ⚠️⚠️⚠️ PROTECTION MAY HAVE FAILED ⚠️⚠️⚠️');
        } else {
          AppLogger.info('🎥 [SCREEN_PROTECTION] Screen recording stopped');
          AppLogger.info('🎥 [SCREEN_PROTECTION] Timestamp: ${timestamp != null ? DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt()) : "unknown"}');
        }
      }
    });
    
    AppLogger.info('📸 [SCREEN_PROTECTION] Screenshot detection enabled on iOS');
    AppLogger.info('🎥 [SCREEN_PROTECTION] Screen recording detection enabled on iOS');
  }

  /// Enable screenshot and screen recording protection
  /// 
  /// [screenType] should be one of: 'video_call', 'chat', 'profile'
  /// [context] is required to show system messages when screenshot is attempted
  Future<bool> enableProtection({
    required String screenType,
    BuildContext? context,
  }) async {
    final startTime = DateTime.now();
    AppLogger.info('🔒 [SCREEN_PROTECTION] ===== ENABLE PROTECTION REQUEST =====');
    AppLogger.info('🔒 [SCREEN_PROTECTION] Screen Type: $screenType');
    AppLogger.info('🔒 [SCREEN_PROTECTION] Platform: ${Platform.isIOS ? "iOS" : Platform.isAndroid ? "Android" : "Unknown"}');
    AppLogger.info('🔒 [SCREEN_PROTECTION] Context Available: ${context != null}');
    AppLogger.info('🔒 [SCREEN_PROTECTION] Current Protection State: $_isProtectionActive');
    AppLogger.info('🔒 [SCREEN_PROTECTION] Current Protected Screen: $_currentProtectedScreen');
    
    try {
      // Log Remote Config state (for debugging only, not used for decision)
      AppLogger.info('🔒 [SCREEN_PROTECTION] Remote Config state (informational only)...');
      final isRemoteConfigInitialized = _remoteConfigService.isInitialized;
      AppLogger.info('🔒 [SCREEN_PROTECTION] Remote Config Initialized: $isRemoteConfigInitialized');
      
      if (isRemoteConfigInitialized) {
        final protectionSettings = _remoteConfigService.getProtectionSettings();
        AppLogger.info('🔒 [SCREEN_PROTECTION] Remote Config Protection Settings (informational):');
        protectionSettings.forEach((key, value) {
          AppLogger.info('🔒 [SCREEN_PROTECTION]   - $key: $value');
        });
      }
      
      // Protection is always enabled regardless of Remote Config values
      AppLogger.info('🔒 [SCREEN_PROTECTION] Enabling protection (independent of Remote Config)');

      // On iOS, always call the API even if we think protection is already active
      // because iOS may have silently disabled protection (e.g., after app backgrounding)
      // On Android, we can skip if already protecting the same screen
      final isIOSAlreadyActive = Platform.isIOS && _isProtectionActive && _currentProtectedScreen == screenType;
      final shouldSkip = !Platform.isIOS && _isProtectionActive && _currentProtectedScreen == screenType;
      
      if (shouldSkip) {
        AppLogger.info('🔒 [SCREEN_PROTECTION] ✅ Protection already active for $screenType (skipping on Android)');
        return true;
      }
      
      if (isIOSAlreadyActive) {
        AppLogger.info('🔒 [SCREEN_PROTECTION] ⚠️ iOS: Re-enabling protection (iOS may have disabled it silently)');
        // On iOS, directly call enable API without disabling first to avoid brief unprotected moment
        // Enable protection
        AppLogger.info('🔒 [SCREEN_PROTECTION] Calling ScreenProtector.protectDataLeakageOn() (iOS re-enable)...');
        final enableStartTime = DateTime.now();
        
        try {
          await ScreenProtector.protectDataLeakageOn();
          final enableDuration = DateTime.now().difference(enableStartTime);
          AppLogger.info('🔒 [SCREEN_PROTECTION] ✅ ScreenProtector.protectDataLeakageOn() completed in ${enableDuration.inMilliseconds}ms');
        } catch (e, stackTrace) {
          AppLogger.error('🔒 [SCREEN_PROTECTION] ❌ CRITICAL: ScreenProtector.protectDataLeakageOn() FAILED', e, stackTrace);
          rethrow;
        }
        
        AppLogger.info('🔒 [SCREEN_PROTECTION] 📱 iOS: Protection API re-called - iOS should now block screenshots');
        _lastProtectionEnableTime = DateTime.now();
        
        final totalDuration = DateTime.now().difference(startTime);
        AppLogger.info('🔒 [SCREEN_PROTECTION] ✅ Protection RE-ENABLED for $screenType (iOS)');
        AppLogger.info('🔒 [SCREEN_PROTECTION] Total Duration: ${totalDuration.inMilliseconds}ms');
        AppLogger.info('🔒 [SCREEN_PROTECTION] ===== ENABLE PROTECTION COMPLETE =====');
        return true;
      }

      // Disable any existing protection first (for different screen or first time enable)
      if (_isProtectionActive) {
        AppLogger.info('🔒 [SCREEN_PROTECTION] Disabling existing protection for $_currentProtectedScreen before enabling for $screenType');
        await disableProtection();
      }

      // Enable protection
      AppLogger.info('🔒 [SCREEN_PROTECTION] Calling ScreenProtector.protectDataLeakageOn()...');
      final enableStartTime = DateTime.now();
      
      try {
        await ScreenProtector.protectDataLeakageOn();
        final enableDuration = DateTime.now().difference(enableStartTime);
        AppLogger.info('🔒 [SCREEN_PROTECTION] ✅ ScreenProtector.protectDataLeakageOn() completed in ${enableDuration.inMilliseconds}ms');
      } catch (e, stackTrace) {
        AppLogger.error('🔒 [SCREEN_PROTECTION] ❌ CRITICAL: ScreenProtector.protectDataLeakageOn() FAILED', e, stackTrace);
        rethrow;
      }
      
      // Verify protection was set (on iOS, we can't directly verify, but we log the attempt)
      if (Platform.isIOS) {
        AppLogger.info('🔒 [SCREEN_PROTECTION] 📱 iOS: Protection API called - iOS should now block screenshots');
        AppLogger.info('🔒 [SCREEN_PROTECTION] 📱 iOS: Note - iOS silently blocks screenshots (no user notification)');
      } else if (Platform.isAndroid) {
        AppLogger.info('🔒 [SCREEN_PROTECTION] 🤖 Android: FLAG_SECURE should be set on window');
      }
      
      // Note: The screen_protector package prevents screenshots/recording
      // but doesn't provide a callback for detection. The system will block
      // the screenshot/recording attempt automatically.

      _isProtectionActive = true;
      _currentProtectedScreen = screenType;
      _lastProtectionEnableTime = DateTime.now();
      
      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.info('🔒 [SCREEN_PROTECTION] ✅ Protection ENABLED for $screenType');
      AppLogger.info('🔒 [SCREEN_PROTECTION] Protection State: $_isProtectionActive');
      AppLogger.info('🔒 [SCREEN_PROTECTION] Protected Screen: $_currentProtectedScreen');
      AppLogger.info('🔒 [SCREEN_PROTECTION] Enable Time: $_lastProtectionEnableTime');
      AppLogger.info('🔒 [SCREEN_PROTECTION] Total Duration: ${totalDuration.inMilliseconds}ms');
      AppLogger.info('🔒 [SCREEN_PROTECTION] ===== ENABLE PROTECTION COMPLETE =====');
      
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('🔒 [SCREEN_PROTECTION] ❌ FAILED to enable screenshot protection', e, stackTrace);
      AppLogger.error('🔒 [SCREEN_PROTECTION] Error Type: ${e.runtimeType}');
      AppLogger.error('🔒 [SCREEN_PROTECTION] Error Message: ${e.toString()}');
      AppLogger.info('🔒 [SCREEN_PROTECTION] ===== ENABLE PROTECTION FAILED =====');
      return false;
    }
  }

  /// Disable screenshot and screen recording protection
  Future<void> disableProtection() async {
    final startTime = DateTime.now();
    AppLogger.info('🔓 [SCREEN_PROTECTION] ===== DISABLE PROTECTION REQUEST =====');
    AppLogger.info('🔓 [SCREEN_PROTECTION] Current Protection State: $_isProtectionActive');
    AppLogger.info('🔓 [SCREEN_PROTECTION] Current Protected Screen: $_currentProtectedScreen');
    AppLogger.info('🔓 [SCREEN_PROTECTION] Platform: ${Platform.isIOS ? "iOS" : Platform.isAndroid ? "Android" : "Unknown"}');
    
    if (!_isProtectionActive) {
      AppLogger.info('🔓 [SCREEN_PROTECTION] ⚠️ Protection not active - nothing to disable');
      AppLogger.info('🔓 [SCREEN_PROTECTION] ===== DISABLE PROTECTION SKIPPED =====');
      return;
    }

    try {
      final previousScreen = _currentProtectedScreen;
      final protectionDuration = _lastProtectionEnableTime != null 
          ? DateTime.now().difference(_lastProtectionEnableTime!)
          : null;
      
      AppLogger.info('🔓 [SCREEN_PROTECTION] Disabling protection for: $previousScreen');
      if (protectionDuration != null) {
        AppLogger.info('🔓 [SCREEN_PROTECTION] Protection was active for: ${protectionDuration.inSeconds}s');
      }
      
      AppLogger.info('🔓 [SCREEN_PROTECTION] Calling ScreenProtector.protectDataLeakageOff()...');
      final disableStartTime = DateTime.now();
      
      try {
        await ScreenProtector.protectDataLeakageOff();
        final disableDuration = DateTime.now().difference(disableStartTime);
        AppLogger.info('🔓 [SCREEN_PROTECTION] ✅ ScreenProtector.protectDataLeakageOff() completed in ${disableDuration.inMilliseconds}ms');
      } catch (e, stackTrace) {
        AppLogger.error('🔓 [SCREEN_PROTECTION] ❌ CRITICAL: ScreenProtector.protectDataLeakageOff() FAILED', e, stackTrace);
        rethrow;
      }
      
      _isProtectionActive = false;
      _currentProtectedScreen = null;
      _lastProtectionDisableTime = DateTime.now();
      
      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.info('🔓 [SCREEN_PROTECTION] ✅ Protection DISABLED for $previousScreen');
      AppLogger.info('🔓 [SCREEN_PROTECTION] Protection State: $_isProtectionActive');
      AppLogger.info('🔓 [SCREEN_PROTECTION] Disable Time: $_lastProtectionDisableTime');
      AppLogger.info('🔓 [SCREEN_PROTECTION] Total Duration: ${totalDuration.inMilliseconds}ms');
      AppLogger.info('🔓 [SCREEN_PROTECTION] ===== DISABLE PROTECTION COMPLETE =====');
    } catch (e, stackTrace) {
      AppLogger.error('🔓 [SCREEN_PROTECTION] ❌ FAILED to disable screenshot protection', e, stackTrace);
      AppLogger.error('🔓 [SCREEN_PROTECTION] Error Type: ${e.runtimeType}');
      AppLogger.error('🔓 [SCREEN_PROTECTION] Error Message: ${e.toString()}');
      AppLogger.info('🔓 [SCREEN_PROTECTION] ===== DISABLE PROTECTION FAILED =====');
    }
  }

  /// Check if protection is currently active
  bool get isProtectionEnabled => _isProtectionActive;

  /// Get the currently protected screen type
  String? get currentProtectedScreen => _currentProtectedScreen;
  
  /// Get detailed protection status for debugging
  Map<String, dynamic> getProtectionStatus() {
    return {
      'isProtectionActive': _isProtectionActive,
      'currentProtectedScreen': _currentProtectedScreen,
      'lastProtectionEnableTime': _lastProtectionEnableTime?.toIso8601String(),
      'lastProtectionDisableTime': _lastProtectionDisableTime?.toIso8601String(),
      'platform': Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Unknown',
      'remoteConfigInitialized': _remoteConfigService.isInitialized,
    };
  }
  
  /// Log current protection status (for debugging)
  void logProtectionStatus() {
    AppLogger.info('📊 [SCREEN_PROTECTION] ===== PROTECTION STATUS =====');
    final status = getProtectionStatus();
    status.forEach((key, value) {
      AppLogger.info('📊 [SCREEN_PROTECTION] $key: $value');
    });
    AppLogger.info('📊 [SCREEN_PROTECTION] ===== END STATUS =====');
  }

  // Note: The screen_protector package blocks screenshots/recording at the OS level.
  // When a screenshot is attempted, Android/iOS will automatically prevent it.
  // On Android, the user may see a system toast message; on iOS, the action
  // is silently blocked. We cannot intercept this to show a custom message
  // because the OS handles it before our app is notified.

  /// Refresh protection state - re-enables protection if it's currently active
  /// Useful to ensure protection is still active after app lifecycle changes
  Future<void> refreshProtectionState({
    required String screenType,
    BuildContext? context,
  }) async {
    if (_isProtectionActive && _currentProtectedScreen == screenType) {
      // Re-enable protection to ensure it's still active
      AppLogger.info('🔒 [SCREEN_PROTECTION] Refreshing protection for $screenType');
      await enableProtection(screenType: screenType, context: context);
    } else if (!_isProtectionActive) {
      // If not active, enable it
      AppLogger.info('🔒 [SCREEN_PROTECTION] Protection not active, enabling for $screenType');
      await enableProtection(screenType: screenType, context: context);
    }
  }
}

