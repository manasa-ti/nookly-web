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
      // Screenshot and screen recording detection handlers
      // Logging removed as per requirements
    });
  }

  /// Enable screenshot and screen recording protection
  /// 
  /// [screenType] should be one of: 'video_call', 'chat', 'profile'
  /// [context] is required to show system messages when screenshot is attempted
  Future<bool> enableProtection({
    required String screenType,
    BuildContext? context,
  }) async {
    try {

      // On iOS, always call the API even if we think protection is already active
      // because iOS may have silently disabled protection (e.g., after app backgrounding)
      // On Android, we can skip if already protecting the same screen
      final isIOSAlreadyActive = Platform.isIOS && _isProtectionActive && _currentProtectedScreen == screenType;
      final shouldSkip = !Platform.isIOS && _isProtectionActive && _currentProtectedScreen == screenType;
      
      if (shouldSkip) {
        return true;
      }
      
      if (isIOSAlreadyActive) {
        // On iOS, directly call enable API without disabling first to avoid brief unprotected moment
        await ScreenProtector.protectDataLeakageOn();
        _lastProtectionEnableTime = DateTime.now();
        return true;
      }

      // Disable any existing protection first (for different screen or first time enable)
      if (_isProtectionActive) {
        await disableProtection();
      }

      // Enable protection
      await ScreenProtector.protectDataLeakageOn();

      _isProtectionActive = true;
      _currentProtectedScreen = screenType;
      _lastProtectionEnableTime = DateTime.now();
      
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enable screenshot protection', e, stackTrace);
      return false;
    }
  }

  /// Disable screenshot and screen recording protection
  Future<void> disableProtection() async {
    if (!_isProtectionActive) {
      return;
    }

    try {
      await ScreenProtector.protectDataLeakageOff();
      
      _isProtectionActive = false;
      _currentProtectedScreen = null;
      _lastProtectionDisableTime = DateTime.now();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to disable screenshot protection', e, stackTrace);
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
    // Logging removed
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
      await enableProtection(screenType: screenType, context: context);
    } else if (!_isProtectionActive) {
      // If not active, enable it
      await enableProtection(screenType: screenType, context: context);
    }
  }
}

