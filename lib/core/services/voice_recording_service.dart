import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nookly/core/utils/logger.dart';

class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;
  StreamController<Duration>? _durationController;
  StreamController<RecordingState>? _stateController;
  bool _isRecording = false;
  bool _isDisposed = false;
  
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
  }

  Future<bool> _requestPermissions() async {
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

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/voice_$timestamp.$audioFormat';

      AppLogger.info('🎤 Starting voice recording to: $filePath');

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: sampleRate,
          bitRate: bitRate,
        ),
        path: filePath,
      );

      _currentDuration = Duration.zero;

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

      AppLogger.info('✅ Voice recording started successfully');
      return filePath;
    } catch (e) {
      AppLogger.error('❌ Failed to start voice recording: $e');
      _stateController?.add(RecordingState.error);
      _isRecording = false;
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!isRecording) {
        AppLogger.warning('⚠️ Not currently recording');
        return null;
      }

      _isRecording = false; // Set this first to stop the timer
      final path = await _recorder.stop();
      _stopDurationTimer();
      _stateController?.add(RecordingState.stopped);

      AppLogger.info('🛑 Voice recording stopped: $path');
      return path;
    } catch (e) {
      AppLogger.error('❌ Failed to stop voice recording: $e');
      _isRecording = false;
      _stateController?.add(RecordingState.error);
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (isRecording) {
        final path = await _recorder.stop();
        _stopDurationTimer();
        
        // Delete the recorded file
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            AppLogger.info('🗑️ Cancelled recording and deleted file: $path');
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
    _recorder.dispose();
  }
}

enum RecordingState {
  idle,
  recording,
  stopped,
  cancelled,
  error,
}
