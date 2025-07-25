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
               uri.pathSegments.isNotEmpty && 
               uri.pathSegments.first == 'reset-password' &&
               uri.pathSegments.length > 1) {
        
        final token = uri.pathSegments[1];
        AppLogger.info('Password reset token extracted from custom scheme: $token');
        
        // Navigate to reset password page
        _navigateToResetPassword(token);
      }
      else {
        AppLogger.warning('Deep link not recognized: $link');
        AppLogger.warning('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
      }
    } catch (e) {
      AppLogger.error('Error parsing deep link: $e');
    }
  }

  void _navigateToResetPassword(String token) {
    AppLogger.info('Attempting to navigate to reset password page with token: $token');
    final navigatorKey = AuthHandler.navigatorKey;
    if (navigatorKey.currentContext != null) {
      AppLogger.info('Navigator context found, pushing ResetPasswordPage');
      Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(token: token),
        ),
      );
    } else {
      AppLogger.error('Navigator context is null, cannot navigate to reset password page');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
    AppLogger.info('DeepLinkService disposed');
  }
} 