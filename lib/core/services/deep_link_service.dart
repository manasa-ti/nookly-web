import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/auth_handler.dart';
import 'package:nookly/presentation/pages/auth/reset_password_page.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _subscription;
  bool _isInitialized = false;
  bool _isProcessingDeepLink = false;
  String? _pendingResetToken;

  bool get isProcessingDeepLink => _isProcessingDeepLink;
  String? get pendingResetToken => _pendingResetToken;

  void initialize() {
    if (_isInitialized) return;
    
    AppLogger.info('Initializing DeepLinkService');
    _isInitialized = true;
    
    // Handle initial link if app was launched from a link
    _handleInitialLink();
    
    // Listen to incoming links when app is already running
    _subscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri.toString());
        }
      },
      onError: (error) {
        AppLogger.error('Deep link error: $error');
      },
    );
  }

  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        AppLogger.info('App launched from deep link: $initialLink');
        _handleDeepLink(initialLink.toString());
      }
    } catch (e) {
      AppLogger.error('Error handling initial deep link: $e');
    }
  }

  void _handleDeepLink(String? link) {
    if (link == null) return;
    
    AppLogger.info('Handling deep link: $link');
    _isProcessingDeepLink = true;
    
    try {
      final uri = Uri.parse(link);
      AppLogger.info('Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
      AppLogger.info('Path segments: ${uri.pathSegments}');
      
      // Handle password reset links (https://nookly.app/reset-password/token)
      if (uri.scheme == 'https' && 
          uri.host == 'nookly.app' &&
          uri.pathSegments.isNotEmpty && 
          uri.pathSegments.first == 'reset-password' &&
          uri.pathSegments.length > 1) {
        
        final token = uri.pathSegments[1];
        AppLogger.info('Password reset token extracted from HTTPS: $token');
        
        // Navigate to reset password page
        _navigateToResetPassword(token);
      }
      // Handle custom scheme links (nookly://reset-password/token)
      else if (uri.scheme == 'nookly' && 
               uri.host == 'reset-password' &&
               uri.pathSegments.isNotEmpty) {
        
        final token = uri.pathSegments[0];
        AppLogger.info('Password reset token extracted from custom scheme: $token');
        AppLogger.info('Token length: ${token.length}');
        
        // Navigate to reset password page
        _navigateToResetPassword(token);
      }
      else {
        // Try alternative parsing for custom scheme links
        if (uri.scheme == 'nookly' && link.contains('reset-password')) {
          AppLogger.info('Attempting alternative parsing for custom scheme link');
          final parts = link.split('/');
          if (parts.length >= 4 && parts[2] == 'reset-password') {
            final token = parts[3];
            AppLogger.info('Password reset token extracted via alternative parsing: $token');
            _navigateToResetPassword(token);
            return;
          }
        }
        
        AppLogger.warning('Deep link not recognized: $link');
        AppLogger.warning('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
        _isProcessingDeepLink = false;
      }
    } catch (e) {
      AppLogger.error('Error parsing deep link: $e');
      _isProcessingDeepLink = false;
    }
  }

  void _navigateToResetPassword(String token) {
    AppLogger.info('Attempting to navigate to reset password page with token: $token');
    AppLogger.info('Token validation: isEmpty=${token.isEmpty}, length=${token.length}');
    _pendingResetToken = token;
    
    // Try immediate navigation first
    final navigatorKey = AuthHandler.navigatorKey;
    AppLogger.info('Navigator key current context: ${navigatorKey.currentContext != null}');
    
    if (navigatorKey.currentContext != null) {
      AppLogger.info('Navigator context found immediately, navigating to ResetPasswordPage');
      _performNavigation(token);
      return;
    }
    
    // If immediate navigation fails, try with delays
    AppLogger.info('Navigator context not available immediately, trying with delays');
    
    // Try after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (navigatorKey.currentContext != null) {
        AppLogger.info('Navigator context found after 100ms, navigating to ResetPasswordPage');
        _performNavigation(token);
        return;
      }
      
      // Try after a longer delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (navigatorKey.currentContext != null) {
          AppLogger.info('Navigator context found after 1s, navigating to ResetPasswordPage');
          _performNavigation(token);
        } else {
          AppLogger.error('Failed to navigate after multiple attempts - Navigator context is null');
          _isProcessingDeepLink = false;
          _pendingResetToken = null;
        }
      });
    });
  }

  void _performNavigation(String token) {
    final navigatorKey = AuthHandler.navigatorKey;
    if (navigatorKey.currentContext != null) {
      AppLogger.info('Performing navigation to ResetPasswordPage with token: $token');
      
      // Use pushAndRemoveUntil to clear the navigation stack and prevent
      // the splash screen's authentication check from interfering
      Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(token: token),
        ),
        (route) => false, // Remove all previous routes
      );
      
      // Reset the flags after successful navigation
      _isProcessingDeepLink = false;
      _pendingResetToken = null;
      
      AppLogger.info('Successfully navigated to ResetPasswordPage');
    } else {
      AppLogger.error('Cannot perform navigation - Navigator context is null');
    }
  }

  // Public method to manually trigger reset password navigation (for testing)
  void navigateToResetPassword(String token) {
    AppLogger.info('Manual navigation to reset password page requested with token: $token');
    _isProcessingDeepLink = true;
    _pendingResetToken = token;
    _performNavigation(token);
  }

  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
    AppLogger.info('DeepLinkService disposed');
  }
} 