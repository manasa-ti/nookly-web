// File generated manually for Firebase configuration
// This file contains Firebase options for all platforms and environments

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:nookly/core/config/environment_manager.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Automatically selects the correct environment (development/production) based on EnvironmentManager.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final environment = EnvironmentManager.currentEnvironment;
    
    if (kIsWeb) {
      switch (environment) {
        case Environment.development:
          return webDev;
        case Environment.staging:
        case Environment.production:
          return webProd; // Staging uses prod Firebase project
      }
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        switch (environment) {
          case Environment.development:
            return androidDev;
          case Environment.staging:
          case Environment.production:
            return androidProd; // Staging uses prod Firebase project
        }
      case TargetPlatform.iOS:
        switch (environment) {
          case Environment.development:
            return iosDev;
          case Environment.staging:
          case Environment.production:
            return iosProd; // Staging uses prod Firebase project
        }
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  // ==================== DEVELOPMENT CONFIG ====================
  
  static FirebaseOptions get webDev => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_WEB_DEV_API_KEY', defaultValue: 'AIzaSyAr0YRC4F7JNLBrHlmviaovd_WGOqNrjTc'),
    appId: const String.fromEnvironment('FIREBASE_WEB_DEV_APP_ID', defaultValue: '1:100647528268:web:785550e0f43cd866f5d1e9'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_WEB_DEV_MESSAGING_SENDER_ID', defaultValue: '100647528268'),
    projectId: const String.fromEnvironment('FIREBASE_WEB_DEV_PROJECT_ID', defaultValue: 'nookly-dev'),
    authDomain: const String.fromEnvironment('FIREBASE_WEB_DEV_AUTH_DOMAIN', defaultValue: 'nookly-dev.firebaseapp.com'),
    storageBucket: const String.fromEnvironment('FIREBASE_WEB_DEV_STORAGE_BUCKET', defaultValue: 'nookly-dev.firebasestorage.app'),
    measurementId: const String.fromEnvironment('FIREBASE_WEB_DEV_MEASUREMENT_ID', defaultValue: 'G-THG1KB5PM1'),
  );

  static FirebaseOptions get androidDev => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_ANDROID_DEV_API_KEY', defaultValue: 'AIzaSyCPtF6RUHJupahKGPhxQFbTtQG3nBUYlAs'),
    appId: const String.fromEnvironment('FIREBASE_ANDROID_DEV_APP_ID', defaultValue: '1:100647528268:android:e8ccbf64da0f0898f5d1e9'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_ANDROID_DEV_MESSAGING_SENDER_ID', defaultValue: '100647528268'),
    projectId: const String.fromEnvironment('FIREBASE_ANDROID_DEV_PROJECT_ID', defaultValue: 'nookly-dev'),
    storageBucket: const String.fromEnvironment('FIREBASE_ANDROID_DEV_STORAGE_BUCKET', defaultValue: 'nookly-dev.firebasestorage.app'),
  );

  static FirebaseOptions get iosDev => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_IOS_DEV_API_KEY', defaultValue: 'AIzaSyB7sNe9v8kzXy8w84iWeUEk6SjWH0Rk4y4'),
    appId: const String.fromEnvironment('FIREBASE_IOS_DEV_APP_ID', defaultValue: '1:100647528268:ios:64d810f3f0bda9bcf5d1e9'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_IOS_DEV_MESSAGING_SENDER_ID', defaultValue: '100647528268'),
    projectId: const String.fromEnvironment('FIREBASE_IOS_DEV_PROJECT_ID', defaultValue: 'nookly-dev'),
    storageBucket: const String.fromEnvironment('FIREBASE_IOS_DEV_STORAGE_BUCKET', defaultValue: 'nookly-dev.firebasestorage.app'),
    iosBundleId: const String.fromEnvironment('FIREBASE_IOS_DEV_BUNDLE_ID', defaultValue: 'com.nookly.app'),
  );

  // ==================== PRODUCTION CONFIG ====================
  
  static FirebaseOptions get webProd => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_WEB_PROD_API_KEY', defaultValue: 'AIzaSyCZH4LcqDDBT58DFnEOW9A1wX9fmzvtd9w'),
    appId: const String.fromEnvironment('FIREBASE_WEB_PROD_APP_ID', defaultValue: '1:348184219109:web:8341550411632c6d35b30c'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_WEB_PROD_MESSAGING_SENDER_ID', defaultValue: '348184219109'),
    projectId: const String.fromEnvironment('FIREBASE_WEB_PROD_PROJECT_ID', defaultValue: 'nookly-18de4'),
    authDomain: const String.fromEnvironment('FIREBASE_WEB_PROD_AUTH_DOMAIN', defaultValue: 'nookly-18de4.firebaseapp.com'),
    storageBucket: const String.fromEnvironment('FIREBASE_WEB_PROD_STORAGE_BUCKET', defaultValue: 'nookly-18de4.firebasestorage.app'),
    measurementId: const String.fromEnvironment('FIREBASE_WEB_PROD_MEASUREMENT_ID', defaultValue: 'G-3K93PDD5ND'),
  );

  static FirebaseOptions get androidProd => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_ANDROID_PROD_API_KEY', defaultValue: 'AIzaSyBu1bNVptEdJG7v9wYmME70QX3DLs8jCmo'),
    appId: const String.fromEnvironment('FIREBASE_ANDROID_PROD_APP_ID', defaultValue: '1:348184219109:android:2713e537e4ebfe2c35b30c'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID', defaultValue: '348184219109'),
    projectId: const String.fromEnvironment('FIREBASE_ANDROID_PROD_PROJECT_ID', defaultValue: 'nookly-18de4'),
    storageBucket: const String.fromEnvironment('FIREBASE_ANDROID_PROD_STORAGE_BUCKET', defaultValue: 'nookly-18de4.firebasestorage.app'),
  );

  static FirebaseOptions get iosProd => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_IOS_PROD_API_KEY', defaultValue: 'AIzaSyB5X1ZpNYguGMX1RRMV8FPEQn7OC7uBOaA'),
    appId: const String.fromEnvironment('FIREBASE_IOS_PROD_APP_ID', defaultValue: '1:348184219109:ios:7fe48593aa9e379d35b30c'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_IOS_PROD_MESSAGING_SENDER_ID', defaultValue: '348184219109'),
    projectId: const String.fromEnvironment('FIREBASE_IOS_PROD_PROJECT_ID', defaultValue: 'nookly-18de4'),
    storageBucket: const String.fromEnvironment('FIREBASE_IOS_PROD_STORAGE_BUCKET', defaultValue: 'nookly-18de4.firebasestorage.app'),
    iosBundleId: const String.fromEnvironment('FIREBASE_IOS_PROD_BUNDLE_ID', defaultValue: 'com.nookly.app'),
  );
}

