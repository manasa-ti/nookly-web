import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:nookly/core/utils/logger.dart';

class VoicePlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamController<Duration>? _positionController;
  StreamController<PlayerState>? _stateController;
  StreamController<bool>? _isPlayingController;
  
  String? _currentUrl;
  Duration? _totalDuration;

  Stream<Duration> get positionStream => _positionController?.stream ?? const Stream.empty();
  Stream<PlayerState> get stateStream => _stateController?.stream ?? const Stream.empty();
  Stream<bool> get isPlayingStream => _isPlayingController?.stream ?? const Stream.empty();
  
  Duration get currentPosition => _audioPlayer.position;
  Duration? get totalDuration => _totalDuration;
  bool get isPlaying => _audioPlayer.playing;
  bool get isPaused => _audioPlayer.playerState.processingState == ProcessingState.ready && !isPlaying;

  VoicePlayerService() {
    _initializePlayer();
  }

  void _initializePlayer() {
    _positionController = StreamController<Duration>.broadcast();
    _stateController = StreamController<PlayerState>.broadcast();
    _isPlayingController = StreamController<bool>.broadcast();

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _positionController?.add(position);
    });

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _stateController?.add(state);
      _isPlayingController?.add(state.playing);
      
      if (state.processingState == ProcessingState.completed) {
        AppLogger.info('🎵 Voice playback completed');
        _onPlaybackCompleted();
      }
    });
  }

  Future<bool> play(String url) async {
    try {
      // Validate URL - reject temp URLs and invalid URLs
      if (url.isEmpty || 
          url == 'temp_url' || 
          url.startsWith('temp_') ||
          (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('blob:'))) {
        AppLogger.error('❌ Invalid voice URL: $url');
        return false;
      }
      
      if (_currentUrl == url && isPaused) {
        // Resume playback
        await _audioPlayer.play();
        AppLogger.info('▶️ Resumed voice playback');
        return true;
      }

      if (_currentUrl != url) {
        // Load new audio
        _currentUrl = url;
        AppLogger.info('🎵 Loading voice message: $url');
        
        await _audioPlayer.setUrl(url);
        _totalDuration = _audioPlayer.duration;
        AppLogger.info('🎵 Voice duration: ${_totalDuration?.inSeconds}s');
      }

      await _audioPlayer.play();
      AppLogger.info('▶️ Started voice playback');
      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to play voice message: $e');
      // Set error state - just log the error, don't add to stream
      AppLogger.error('❌ Player state error: $e');
      return false;
    }
  }

  Future<void> pause() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        AppLogger.info('⏸️ Paused voice playback');
      }
    } catch (e) {
      // On web, just_audio may throw UnimplementedError
      // This is a known issue with just_audio on web
      // Log as warning instead of error
      AppLogger.warning('⚠️ Failed to pause voice playback (may be web limitation): $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentUrl = null;
      _totalDuration = null;
      AppLogger.info('⏹️ Stopped voice playback');
    } catch (e) {
      AppLogger.error('❌ Failed to stop voice playback: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      AppLogger.info('⏭️ Seeked to: ${position.inSeconds}s');
    } catch (e) {
      AppLogger.error('❌ Failed to seek voice playback: $e');
    }
  }

  Future<void> seekToStart() async {
    await seek(Duration.zero);
  }

  Future<void> seekToEnd() async {
    if (_totalDuration != null) {
      await seek(_totalDuration!);
    }
  }

  void _onPlaybackCompleted() {
    // This will be called when playback completes
    // The UI can listen to this and handle view-once logic
  }

  void dispose() {
    try {
      _audioPlayer.dispose();
    } catch (e) {
      // On web, just_audio dispose() may throw UnimplementedError
      // This is a known issue with just_audio on web
      // Ignore the error as the player will be cleaned up by garbage collection
    }
    _positionController?.close();
    _stateController?.close();
    _isPlayingController?.close();
  }
}
