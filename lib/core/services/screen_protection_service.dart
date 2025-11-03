import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:nookly/core/services/remote_config_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/di/injection_container.dart' as di;

/// Service for managing screenshot and screen recording prevention
/// Integrates with Remote Config to control protection remotely
class ScreenProtectionService {
  final RemoteConfigService _remoteConfigService;
  bool _isProtectionActive = false;
  String? _currentProtectedScreen;
  
  // Note: screen_protector prevents screenshots/recording but doesn't provide
  // a callback. The system (Android/iOS) automatically blocks attempts and
  // may show a system message.

  ScreenProtectionService({RemoteConfigService? remoteConfigService})
      : _remoteConfigService = remoteConfigService ?? di.sl<RemoteConfigService>();

  /// Enable screenshot and screen recording protection
  /// 
  /// [screenType] should be one of: 'video_call', 'chat', 'profile'
  /// [context] is required to show system messages when screenshot is attempted
  Future<bool> enableProtection({
    required String screenType,
    BuildContext? context,
  }) async {
    try {
      // Check if protection should be enabled via Remote Config
      if (!_remoteConfigService.shouldProtectScreen(screenType)) {
        AppLogger.info('🔒 Screenshot protection disabled via Remote Config for $screenType');
        return false;
      }

      // Check if already protecting this screen
      if (_isProtectionActive && _currentProtectedScreen == screenType) {
        AppLogger.debug('🔒 Protection already active for $screenType');
        return true;
      }

      // Disable any existing protection first
      if (_isProtectionActive) {
        await disableProtection();
      }

      // Enable protection
      await ScreenProtector.protectDataLeakageOn();
      
      // Note: The screen_protector package prevents screenshots/recording
      // but doesn't provide a callback for detection. The system will block
      // the screenshot/recording attempt automatically.

      _isProtectionActive = true;
      _currentProtectedScreen = screenType;
      AppLogger.info('🔒 Screenshot protection enabled for $screenType');
      return true;
    } catch (e) {
      AppLogger.error('Failed to enable screenshot protection', e);
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
      
      final previousScreen = _currentProtectedScreen;
      _isProtectionActive = false;
      _currentProtectedScreen = null;
      
      if (previousScreen != null) {
        AppLogger.info('🔓 Screenshot protection disabled for $previousScreen');
      }
    } catch (e) {
      AppLogger.error('Failed to disable screenshot protection', e);
    }
  }

  /// Check if protection is currently active
  bool get isProtectionEnabled => _isProtectionActive;

  /// Get the currently protected screen type
  String? get currentProtectedScreen => _currentProtectedScreen;

  // Note: The screen_protector package blocks screenshots/recording at the OS level.
  // When a screenshot is attempted, Android/iOS will automatically prevent it.
  // On Android, the user may see a system toast message; on iOS, the action
  // is silently blocked. We cannot intercept this to show a custom message
  // because the OS handles it before our app is notified.

  /// Refresh protection state based on Remote Config
  /// Useful if Remote Config values change while app is running
  Future<void> refreshProtectionState({
    required String screenType,
    BuildContext? context,
  }) async {
    if (_isProtectionActive && _currentProtectedScreen == screenType) {
      // Re-check Remote Config and update protection if needed
      final shouldProtect = _remoteConfigService.shouldProtectScreen(screenType);
      
      if (shouldProtect && !_isProtectionActive) {
        await enableProtection(screenType: screenType, context: context);
      } else if (!shouldProtect && _isProtectionActive) {
        await disableProtection();
      }
    }
  }
}

