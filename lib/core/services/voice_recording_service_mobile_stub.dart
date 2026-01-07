// Stub file for mobile platforms
// This file is only imported on non-web platforms to satisfy conditional import requirements

/// Stub class for mobile platforms
/// This class is never actually used on mobile - it's only for type checking
class WebMediaRecorderWrapper {
  Future<Map<String, dynamic>> startRecording() {
    throw UnimplementedError('WebMediaRecorderWrapper is only available on web');
  }
  
  Future<String> stopRecording() {
    throw UnimplementedError('WebMediaRecorderWrapper is only available on web');
  }
  
  void dispose() {
    throw UnimplementedError('WebMediaRecorderWrapper is only available on web');
  }
}

