// Web-specific screenshot detection and protection service
// This file is only used for web compilation
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

/// Web screenshot detection service
/// Detects screenshot attempts and triggers callbacks
class WebScreenshotProtectionService {
  StreamController<bool>? _screenshotDetectedController;
  StreamController<bool>? _screenRecordingDetectedController;
  bool _isInitialized = false;
  
  Stream<bool> get screenshotDetected => _screenshotDetectedController?.stream ?? const Stream.empty();
  Stream<bool> get screenRecordingDetected => _screenRecordingDetectedController?.stream ?? const Stream.empty();
  
  /// Initialize screenshot detection
  void initialize() {
    if (_isInitialized) return;
    
    _screenshotDetectedController = StreamController<bool>.broadcast();
    _screenRecordingDetectedController = StreamController<bool>.broadcast();
    
    _setupScreenshotDetection();
    _isInitialized = true;
  }
  
  void _setupScreenshotDetection() {
    // Listen for custom screenshot-detected events from JavaScript
    html.window.addEventListener('screenshot-detected', (html.Event event) {
      _screenshotDetectedController?.add(true);
    });
    
    // Listen for screen recording detection
    html.window.addEventListener('screen-recording-detected', (html.Event event) {
      final customEvent = event as html.CustomEvent;
      final isRecording = customEvent.detail as bool? ?? false;
      _screenRecordingDetectedController?.add(isRecording);
    });
    
    // Also listen for visibility changes (might indicate screenshot on some browsers)
    html.document.addEventListener('visibilitychange', (html.Event event) {
      // Tab became hidden - might be screenshot or tab switch
      // We'll let JavaScript handle the timing logic
      // Note: html.document.hidden is not nullable, but we check it anyway
    });
  }
  
  void dispose() {
    _screenshotDetectedController?.close();
    _screenshotDetectedController = null;
    _screenRecordingDetectedController?.close();
    _screenRecordingDetectedController = null;
    _isInitialized = false;
  }
}

