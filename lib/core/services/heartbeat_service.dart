import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/utils/logger.dart';

/// Global heartbeat service to manage online status
/// This service handles starting/stopping heartbeat based on app lifecycle
class HeartbeatService with WidgetsBindingObserver {
  static final HeartbeatService _instance = HeartbeatService._internal();
  factory HeartbeatService() => _instance;
  HeartbeatService._internal();

  SocketService? _socketService;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;
  bool _isAppActive = true;

  /// Initialize the heartbeat service
  void initialize() {
    if (_isInitialized) return;
    
    AppLogger.info('💓 HeartbeatService: Initializing heartbeat service');
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Get socket service from dependency injection
    try {
      _socketService = sl<SocketService>();
      _isInitialized = true;
      AppLogger.info('💓 HeartbeatService: Successfully initialized');
    } catch (e) {
      AppLogger.error('❌ HeartbeatService: Failed to get SocketService: $e');
    }
  }

  /// Dispose the heartbeat service
  void dispose() {
    if (!_isInitialized) return;
    
    AppLogger.info('💓 HeartbeatService: Disposing heartbeat service');
    
    // Stop heartbeat
    _stopHeartbeat();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _isInitialized = false;
    _socketService = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info('💓 HeartbeatService: App lifecycle changed to: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppActive = true;
        _startHeartbeat();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isAppActive = false;
        _stopHeartbeat();
        break;
      case AppLifecycleState.inactive:
        // Don't stop heartbeat on inactive (e.g., incoming call, notification)
        // Only stop on paused/detached
        break;
      case AppLifecycleState.hidden:
        // App is hidden but may still be active
        break;
    }
  }

  /// Start heartbeat with 30-second interval
  void _startHeartbeat() {
    if (!_isInitialized || _socketService == null) {
      AppLogger.warning('⚠️ HeartbeatService: Cannot start heartbeat - not initialized or no socket service');
      return;
    }

    // Stop existing heartbeat if any
    _stopHeartbeat();

    AppLogger.info('💓 HeartbeatService: Starting heartbeat (30s interval)');
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_socketService?.isConnected == true && _isAppActive) {
        _sendHeartbeat();
      } else {
        AppLogger.warning('⚠️ HeartbeatService: Stopping heartbeat - socket disconnected or app inactive');
        timer.cancel();
        _heartbeatTimer = null;
      }
    });
  }

  /// Stop heartbeat
  void _stopHeartbeat() {
    if (_heartbeatTimer != null) {
      AppLogger.info('💓 HeartbeatService: Stopping heartbeat');
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }
  }

  /// Send heartbeat to server
  void _sendHeartbeat() {
    if (_socketService?.isConnected == true) {
      AppLogger.info('💓 HeartbeatService: Sending heartbeat');
      _socketService!.sendHeartbeat();
    } else {
      AppLogger.warning('⚠️ HeartbeatService: Cannot send heartbeat - socket not connected');
    }
  }

  /// Manually start heartbeat (for testing or special cases)
  void startHeartbeat() {
    if (_isInitialized) {
      _isAppActive = true;
      _startHeartbeat();
    }
  }

  /// Manually stop heartbeat (for testing or special cases)
  void stopHeartbeat() {
    if (_isInitialized) {
      _isAppActive = false;
      _stopHeartbeat();
    }
  }

  /// Check if heartbeat is currently active
  bool get isHeartbeatActive => _heartbeatTimer != null && _isAppActive;

  /// Get heartbeat status info
  Map<String, dynamic> getHeartbeatStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAppActive': _isAppActive,
      'isHeartbeatActive': isHeartbeatActive,
      'socketConnected': _socketService?.isConnected ?? false,
      'hasSocketService': _socketService != null,
    };
  }
}
