import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/utils/platform_utils.dart';

class GoogleSignInService {
  static GoogleSignInService? _instance;
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  GoogleSignInService._();

  static GoogleSignInService get instance {
    _instance ??= GoogleSignInService._();
    return _instance!;
  }

  void initialize() {
    if (_isInitialized) {
      AppLogger.info('GoogleSignInService already initialized');
      return;
    }

    try {
      // Configure Google Sign-In based on platform
      if (kIsWeb) {
        // Web configuration
        _googleSignIn = GoogleSignIn(
          clientId: '957642975258-39lt5kotqdbuvcqg9uic4pplpdq29c1o.apps.googleusercontent.com', // Replace with your web client ID
          scopes: [
            'email',
            'profile',
          ],
        );
        AppLogger.info('GoogleSignIn initialized for web');
      } else if (PlatformUtils.isAndroid) {
        // Android configuration - using Android client ID
        _googleSignIn = GoogleSignIn(
          serverClientId: '957642975258-39lt5kotqdbuvcqg9uic4pplpdq29c1o.apps.googleusercontent.com', // Web client ID
          clientId: '957642975258-k802ombsbqdc6a0qvgubvkoa6s6ensnp.apps.googleusercontent.com',
          scopes: [
            'email',
            'profile',
          ],
        );
        AppLogger.info('GoogleSignIn initialized for Android');
      } else if (PlatformUtils.isIOS) {
        // iOS configuration
        _googleSignIn = GoogleSignIn(
          clientId: '957642975258-256528neeadp0ieai104f80idjnmlngm.apps.googleusercontent.com', // Replace with your iOS client ID
          scopes: [
            'email',
            'profile',
          ],
        );
        AppLogger.info('GoogleSignIn initialized for iOS');
      } else {
        // Fallback or other platforms
        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
          ],
        );
        AppLogger.info('GoogleSignIn initialized for unknown platform');
      }

      _isInitialized = true;
      AppLogger.info('GoogleSignInService initialization completed');
    } catch (e) {
      AppLogger.error('Failed to initialize GoogleSignInService', e, StackTrace.current);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getAuthData() async {
    if (!_isInitialized) {
      throw Exception('GoogleSignInService not initialized. Call initialize() first.');
    }

    try {
      AppLogger.info('Starting Google Sign-In process');
      
      // Sign in
      final GoogleSignInAccount? account = await _googleSignIn?.signIn();
      
      if (account == null) {
        AppLogger.info('Google Sign-In was cancelled by user');
        return null;
      }

      AppLogger.info('Google Sign-In successful for: ${account.email}');

      // Get auth details
      final GoogleSignInAuthentication auth = await account.authentication;
      
      final authData = {
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
        'serverAuthCode': auth.serverAuthCode,
      };

      AppLogger.info('Auth data retrieved successfully');
      AppLogger.info('Email: ${authData['email']}');
      AppLogger.info('Display Name: ${authData['displayName']}');
      AppLogger.info('ID Token length: ${authData['idToken']?.length ?? 0}');
      AppLogger.info('ID Token content: ${authData['idToken']}');
      AppLogger.info('Access Token length: ${authData['accessToken']?.length ?? 0}');
      AppLogger.info('Server Auth Code length: ${authData['serverAuthCode']?.length ?? 0}');

      return authData;
    } catch (e) {
      AppLogger.error('Error during Google Sign-In', e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized) {
      AppLogger.warning('GoogleSignInService not initialized, skipping sign out');
      return;
    }

    try {
      await _googleSignIn?.signOut();
      AppLogger.info('Google Sign-Out successful');
    } catch (e) {
      AppLogger.error('Error during Google Sign-Out', e, StackTrace.current);
      rethrow;
    }
  }

  Future<bool> isSignedIn() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      return await _googleSignIn?.isSignedIn() ?? false;
    } catch (e) {
      AppLogger.error('Error checking sign-in status', e, StackTrace.current);
      return false;
    }
  }

  Future<GoogleSignInAccount?> getCurrentUser() async {
    if (!_isInitialized) {
      return null;
    }

    try {
      return await _googleSignIn?.currentUser;
    } catch (e) {
      AppLogger.error('Error getting current user', e, StackTrace.current);
      return null;
    }
  }
} 