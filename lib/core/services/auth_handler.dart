import 'package:flutter/material.dart';
import 'package:hushmate/core/utils/logger.dart';

class AuthHandler {
  static final AuthHandler _instance = AuthHandler._internal();
  factory AuthHandler() => _instance;
  AuthHandler._internal();

  // Global navigator key to access navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Callback function to trigger logout
  VoidCallback? _onLogoutCallback;

  void setLogoutCallback(VoidCallback callback) {
    _onLogoutCallback = callback;
  }

  void clearLogoutCallback() {
    _onLogoutCallback = null;
  }

  void triggerLogout() {
    AppLogger.info('🔐 AuthHandler: Triggering logout due to 401 error');
    
    if (_onLogoutCallback != null) {
      _onLogoutCallback!();
    } else {
      AppLogger.warning('⚠️ AuthHandler: No logout callback set');
    }
  }

  void navigateToLogin() {
    AppLogger.info('🔐 AuthHandler: Navigating to login screen');
    
    if (navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } else {
      AppLogger.error('❌ AuthHandler: Navigator context is null');
    }
  }

  // Check if an endpoint is critical (should trigger logout on 401)
  bool isCriticalEndpoint(String path) {
    final criticalEndpoints = [
      '/users/profile',
      '/users/recommendations', 
      '/users/matches',
    ];
    
    return criticalEndpoints.any((endpoint) => path.contains(endpoint));
  }
} 