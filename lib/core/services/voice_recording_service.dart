import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nookly/core/utils/file_io_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nookly/core/utils/logger.dart';

// Conditional imports
import 'package:record/record.dart' show AudioRecorder, RecordConfig, AudioEncoder;
import 'voice_recording_service_web.dart' if (dart.library.io) 'voice_recording_service_mobile_stub.dart' as web_recording;

class VoiceRecordingService {
  // Mobile recorder (only used on non-web)
  AudioRecorder? _recorder;
  
  // Web recorder wrapper (only used on web)
  web_recording.WebMediaRecorderWrapper? _webRecorder;
  
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;
  StreamController<Duration>? _durationController;
  StreamController<RecordingState>? _stateController;
  bool _isRecording = false;
  bool _isDisposed = false;
  String? _currentRecordingPath; // Blob URL on web, file path on mobile
  
  static const int maxDurationSeconds = 300; // 5 minutes
  static const String audioFormat = 'm4a';
  static const int sampleRate = 44100;
  static const int bitRate = 64000; // 64kbps for voice optimization

  Stream<Duration> get durationStream => _durationController?.stream ?? const Stream.empty();
  Stream<RecordingState> get stateStream => _stateController?.stream ?? const Stream.empty();
  
  Duration get currentDuration => _currentDuration;
  bool get isRecording => _isRecording;

  VoiceRecordingService() {
    // Ensure controllers exist so listeners added before startRecording still receive events
    _durationController = StreamController<Duration>.broadcast();
    _stateController = StreamController<RecordingState>.broadcast();
    
    if (!kIsWeb) {
      _recorder = AudioRecorder();
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) {
      // On web, permissions are handled by browser when accessing MediaStream
      // getUserMedia will prompt for permission automatically
      return true;
    }
    
    final microphonePermission = await Permission.microphone.request();
    if (microphonePermission != PermissionStatus.granted) {
      AppLogger.error('❌ Microphone permission denied');
      return false;
    }
    return true;
  }

  Future<String?> startRecording() async {
    try {
      if (isRecording) {
        AppLogger.warning('⚠️ Already recording, stopping current recording first');
        await stopRecording();
      }

      if (!await _requestPermissions()) {
        return null;
      }

      if (kIsWeb) {
        return await _startWebRecording();
      } else {
        return await _startMobileRecording();
      }
    } catch (e) {
      AppLogger.error('❌ Failed to start voice recording: $e');
      _stateController?.add(RecordingState.error);
      _isRecording = false;
      return null;
    }
  }

  Future<String?> _startMobileRecording() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/voice_$timestamp.$audioFormat';

    AppLogger.info('🎤 Starting mobile voice recording to: $filePath');

      await _recorder!.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: sampleRate,
          bitRate: bitRate,
        ),
        path: filePath,
      );

    _currentDuration = Duration.zero;
    _currentRecordingPath = filePath;

    // (Re)create controllers if needed
    if (_durationController == null || _durationController!.isClosed) {
      _durationController = StreamController<Duration>.broadcast();
    }
    if (_stateController == null || _stateController!.isClosed) {
      _stateController = StreamController<RecordingState>.broadcast();
    }

    _isRecording = true;
    // Emit initial values for fresh subscribers
    _durationController?.add(Duration.zero);
    _stateController?.add(RecordingState.recording);
    _startDurationTimer();

    AppLogger.info('✅ Mobile voice recording started successfully');
    return filePath;
  }

  Future<String?> _startWebRecording() async {
    try {
      AppLogger.info('🎤 Starting web voice recording...');
      
      _webRecorder = web_recording.WebMediaRecorderWrapper();
      await _webRecorder!.startRecording();
      
      _currentDuration = Duration.zero;
      // Blob URL will be set when recording stops
      _currentRecordingPath = null;

      // (Re)create controllers if needed
      if (_durationController == null || _durationController!.isClosed) {
        _durationController = StreamController<Duration>.broadcast();
      }
      if (_stateController == null || _stateController!.isClosed) {
        _stateController = StreamController<RecordingState>.broadcast();
      }

      _isRecording = true;
      _durationController?.add(Duration.zero);
      _stateController?.add(RecordingState.recording);
      _startDurationTimer();

      AppLogger.info('✅ Web voice recording started successfully');
      // Return placeholder - actual blob URL will be available after stop
      return 'web_recording_in_progress';
    } catch (e) {
      AppLogger.error('❌ Failed to start web recording: $e');
      _webRecorder?.dispose();
      _webRecorder = null;
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!isRecording) {
        AppLogger.warning('⚠️ Not currently recording');
        return null;
      }

      _isRecording = false; // Set this first to stop the timer
      _stopDurationTimer();
      
      if (kIsWeb) {
        return await _stopWebRecording();
      } else {
        return await _stopMobileRecording();
      }
    } catch (e) {
      AppLogger.error('❌ Failed to stop voice recording: $e');
      _isRecording = false;
      _stateController?.add(RecordingState.error);
      return null;
    }
  }

  Future<String?> _stopMobileRecording() async {
    final path = await _recorder!.stop();
    _currentRecordingPath = path;
    _stateController?.add(RecordingState.stopped);
    AppLogger.info('🛑 Mobile voice recording stopped: $path');
    return path;
  }

  Future<String?> _stopWebRecording() async {
    try {
      if (_webRecorder == null) {
        throw StateError('Web recorder not initialized');
      }
      
      final blobUrl = await _webRecorder!.stopRecording();
      _currentRecordingPath = blobUrl;
      
      _stateController?.add(RecordingState.stopped);
      AppLogger.info('🛑 Web voice recording stopped: $blobUrl');
      
      return blobUrl;
    } catch (e) {
      AppLogger.error('❌ Failed to stop web recording: $e');
      _webRecorder?.dispose();
      _webRecorder = null;
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (isRecording) {
        if (kIsWeb) {
          _webRecorder?.dispose();
          _webRecorder = null;
          _currentRecordingPath = null;
          AppLogger.info('🗑️ Cancelled web recording');
        } else {
          final path = await _recorder!.stop();
          _stopDurationTimer();
          
          // Delete the recorded file
          if (path != null) {
            try {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
                AppLogger.info('🗑️ Cancelled recording and deleted file: $path');
              }
            } catch (e) {
              // File operations not available
              AppLogger.warning('Failed to delete recording file: $e');
            }
          }
        }
      }
      
      _isRecording = false;
      _stateController?.add(RecordingState.cancelled);
    } catch (e) {
      AppLogger.error('❌ Failed to cancel voice recording: $e');
      _stateController?.add(RecordingState.error);
      _isRecording = false;
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || _durationController == null || _durationController!.isClosed) {
        timer.cancel();
        return;
      }
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      _currentDuration = Duration(seconds: timer.tick);
      try {
        _durationController?.add(_currentDuration);
      } catch (e) {
        AppLogger.error('❌ Failed to emit duration update: $e');
        timer.cancel();
      }
      // Auto-stop at max duration
      if (_currentDuration.inSeconds >= maxDurationSeconds) {
        AppLogger.info('⏰ Max recording duration reached, stopping recording');
        stopRecording();
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void dispose() {
    _isDisposed = true;
    _isRecording = false;
    _stopDurationTimer();
    try { _durationController?.close(); } catch (_) {}
    try { _stateController?.close(); } catch (_) {}
    
    if (!kIsWeb && _recorder != null) {
      _recorder!.dispose();
      _recorder = null;
    }
    
    if (kIsWeb && _webRecorder != null) {
      _webRecorder!.dispose();
      _webRecorder = null;
    }
  }
}

enum RecordingState {
  idle,
  recording,
  stopped,
  cancelled,
  error,
}

