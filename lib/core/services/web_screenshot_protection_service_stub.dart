// Stub file for mobile platforms
// This file is only imported on non-web platforms to satisfy conditional import requirements

import 'dart:async';

/// Stub class for mobile platforms
/// This class is never actually used on mobile - it's only for type checking
class WebScreenshotProtectionService {
  Stream<bool> get screenshotDetected => const Stream.empty();
  Stream<bool> get screenRecordingDetected => const Stream.empty();
  
  void initialize() {
    throw UnimplementedError('WebScreenshotProtectionService is only available on web');
  }
  
  void dispose() {
    throw UnimplementedError('WebScreenshotProtectionService is only available on web');
  }
}

