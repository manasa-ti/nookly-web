import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:nookly/core/utils/logger.dart';

/// Service for crash reporting and error tracking using Firebase Crashlytics
class CrashReportingService {
  final FirebaseCrashlytics _crashlytics;
  bool _isEnabled = true;

  CrashReportingService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance {
    // Enable crashlytics for all environments (separate Firebase projects per environment)
    _isEnabled = true;
  }

  /// Initialize crash reporting with global error handlers
  Future<void> initialize() async {
    if (!_isEnabled) {
      AppLogger.info('Crash reporting disabled');
      return;
    }

    try {
      // Enable Crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      
      // Set up global error handlers
      _setupErrorHandlers();
      
      AppLogger.info('Crash reporting service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize crash reporting', e);
    }
  }

  /// Set up global Flutter error handlers
  void _setupErrorHandlers() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to console in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      
      // Report to Crashlytics
      _crashlytics.recordFlutterFatalError(details);
      
      AppLogger.error(
        'Flutter error: ${details.exception}',
        details.exception,
        details.stack,
      );
    };

    // Handle asynchronous errors that occur outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, reason: 'Non-Flutter framework error', fatal: true);
      AppLogger.error('Platform error', error, stack);
      return true; // Prevent error from propagating
    };
  }

  /// Record a fatal error (app will crash)
  Future<void> recordFatalError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    if (!_isEnabled) {
      AppLogger.error('Fatal error (crash reporting disabled): $error', error, stackTrace);
      return;
    }

    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: true,
      );
      AppLogger.error('Fatal error recorded: $error', error, stackTrace);
    } catch (e) {
      AppLogger.error('Failed to record fatal error', e);
    }
  }

  /// Record a non-fatal error (app continues running)
  Future<void> recordNonFatalError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isEnabled) {
      AppLogger.warning('Non-fatal error (crash reporting disabled): $error');
      return;
    }

    try {
      // Set custom keys if provided
      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
      AppLogger.warning('Non-fatal error recorded: $error');
    } catch (e) {
      AppLogger.error('Failed to record non-fatal error', e);
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String? userId) async {
    if (!_isEnabled) {
      return;
    }

    try {
      await _crashlytics.setUserIdentifier(userId ?? '');
      AppLogger.debug('Crashlytics user ID set: $userId');
    } catch (e) {
      AppLogger.error('Failed to set Crashlytics user ID', e);
    }
  }

  /// Set custom key-value pair for crash reports
  Future<void> setCustomKey(String key, String value) async {
    if (!_isEnabled) {
      return;
    }

    try {
      _crashlytics.setCustomKey(key, value);
      AppLogger.debug('Crashlytics custom key set: $key = $value');
    } catch (e) {
      AppLogger.error('Failed to set Crashlytics custom key', e);
    }
  }

  /// Set multiple custom keys at once
  Future<void> setCustomKeys(Map<String, String> keys) async {
    if (!_isEnabled) {
      return;
    }

    try {
      for (final entry in keys.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value);
      }
      AppLogger.debug('Crashlytics custom keys set: ${keys.length} keys');
    } catch (e) {
      AppLogger.error('Failed to set Crashlytics custom keys', e);
    }
  }

  /// Log a message to crash reports (useful for debugging)
  Future<void> log(String message) async {
    if (!_isEnabled) {
      AppLogger.debug('Crashlytics log (disabled): $message');
      return;
    }

    try {
      _crashlytics.log(message);
      AppLogger.debug('Crashlytics log: $message');
    } catch (e) {
      AppLogger.error('Failed to log to Crashlytics', e);
    }
  }

  /// Force a test crash (for testing purposes only)
  /// DO NOT use in production
  /// Works in all environments now (separate Firebase projects per environment)
  Future<void> testCrash() async {
    if (!_isEnabled) {
      AppLogger.warning('Test crash called but crashlytics is disabled');
      return;
    }
    
    AppLogger.warning('⚠️ TEST CRASH: Triggering test crash in 2 seconds...');
    AppLogger.warning('⚠️ This will crash the app to test Crashlytics');
    
    // Wait a moment to allow logs to be sent
    await Future.delayed(const Duration(seconds: 2));
    
    // Trigger the crash
    _crashlytics.crash();
  }
  
  /// Test non-fatal error (app continues running)
  /// Useful for testing error reporting without crashing
  Future<void> testNonFatalError() async {
    if (!_isEnabled) {
      AppLogger.warning('Test non-fatal error called but crashlytics is disabled');
      return;
    }
    
    AppLogger.info('🧪 Testing non-fatal error reporting...');
    
    try {
      await recordNonFatalError(
        'Test non-fatal error',
        StackTrace.current,
        reason: 'This is a test error to verify Crashlytics integration',
        additionalData: {
          'test_timestamp': DateTime.now().toIso8601String(),
          'test_type': 'manual_test',
        },
      );
      
      AppLogger.info('✅ Test non-fatal error recorded successfully');
    } catch (e) {
      AppLogger.error('Failed to record test non-fatal error', e);
    }
  }

  /// Clear all user data (call on logout)
  Future<void> clearUserData() async {
    if (!_isEnabled) {
      return;
    }

    try {
      await _crashlytics.setUserIdentifier('');
      // Note: There's no direct method to clear all custom keys,
      // but setting them to empty strings works
      AppLogger.info('Crashlytics user data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear Crashlytics user data', e);
    }
  }

  /// Check if crashlytics is enabled
  bool get isEnabled => _isEnabled;
}

