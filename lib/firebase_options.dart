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
      return environment == Environment.development ? webDev : webProd;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return environment == Environment.development ? androidDev : androidProd;
      case TargetPlatform.iOS:
        return environment == Environment.development ? iosDev : iosProd;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  // ==================== DEVELOPMENT CONFIG ====================
  
  static const FirebaseOptions webDev = FirebaseOptions(
    apiKey: 'AIzaSyAr0YRC4F7JNLBrHlmviaovd_WGOqNrjTc',
    appId: '1:100647528268:web:785550e0f43cd866f5d1e9',
    messagingSenderId: '100647528268',
    projectId: 'nookly-dev',
    authDomain: 'nookly-dev.firebaseapp.com',
    storageBucket: 'nookly-dev.firebasestorage.app',
    measurementId: 'G-THG1KB5PM1',
  );

  static const FirebaseOptions androidDev = FirebaseOptions(
    apiKey: 'AIzaSyCPtF6RUHJupahKGPhxQFbTtQG3nBUYlAs',
    appId: '1:100647528268:android:e8ccbf64da0f0898f5d1e9',
    messagingSenderId: '100647528268',
    projectId: 'nookly-dev',
    storageBucket: 'nookly-dev.firebasestorage.app',
  );

  static const FirebaseOptions iosDev = FirebaseOptions(
    apiKey: 'AIzaSyB7sNe9v8kzXy8w84iWeUEk6SjWH0Rk4y4',
    appId: '1:100647528268:ios:64d810f3f0bda9bcf5d1e9',
    messagingSenderId: '100647528268',
    projectId: 'nookly-dev',
    storageBucket: 'nookly-dev.firebasestorage.app',
    iosBundleId: 'com.nookly.app',
  );

  // ==================== PRODUCTION CONFIG ====================
  
  static const FirebaseOptions webProd = FirebaseOptions(
    apiKey: 'AIzaSyCZH4LcqDDBT58DFnEOW9A1wX9fmzvtd9w',
    appId: '1:348184219109:web:8341550411632c6d35b30c',
    messagingSenderId: '348184219109',
    projectId: 'nookly-18de4',
    authDomain: 'nookly-18de4.firebaseapp.com',
    storageBucket: 'nookly-18de4.firebasestorage.app',
    measurementId: 'G-3K93PDD5ND',
  );

  static const FirebaseOptions androidProd = FirebaseOptions(
    apiKey: 'AIzaSyBu1bNVptEdJG7v9wYmME70QX3DLs8jCmo',
    appId: '1:348184219109:android:2713e537e4ebfe2c35b30c',
    messagingSenderId: '348184219109',
    projectId: 'nookly-18de4',
    storageBucket: 'nookly-18de4.firebasestorage.app',
  );

  static const FirebaseOptions iosProd = FirebaseOptions(
    apiKey: 'AIzaSyB5X1ZpNYguGMX1RRMV8FPEQn7OC7uBOaA',
    appId: '1:348184219109:ios:7fe48593aa9e379d35b30c',
    messagingSenderId: '348184219109',
    projectId: 'nookly-18de4',
    storageBucket: 'nookly-18de4.firebasestorage.app',
    iosBundleId: 'com.nookly.app',
  );
}

