import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nookly/core/services/voice_player_service.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/core/utils/logger.dart';

class VoicePlayerWidget extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onPlaybackComplete;
  final Function(String messageId)? onMarkAsPlayed;

  const VoicePlayerWidget({
    Key? key,
    required this.message,
    required this.isMe,
    this.onPlaybackComplete,
    this.onMarkAsPlayed,
  }) : super(key: key);

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget>
    with TickerProviderStateMixin {
  final VoicePlayerService _playerService = VoicePlayerService();
  
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _currentUrl;
  bool _isSending = false; // Track if message is still sending (temp URL)
  
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
    _loadVoiceUrl();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupListeners() {
    _positionSubscription = _playerService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _playingSubscription = _playerService.isPlayingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
        
        if (playing) {
          _waveController.repeat();
        } else {
          _waveController.stop();
        }
      }
    });

    // Listen for playback completion
    _playerService.stateStream.listen((state) {
      if (mounted && state.processingState == ProcessingState.completed) {
        AppLogger.info('🎵 Voice playback completed for message: ${widget.message.id}');
        _onPlaybackCompleted();
      }
    });
  }

  Future<void> _loadVoiceUrl() async {
    if (widget.message.metadata?.voice == null) {
      AppLogger.error('❌ No voice metadata found for message');
      setState(() {
        _hasError = true;
      });
      return;
    }

    final voiceMetadata = widget.message.metadata!.voice!;
    _currentUrl = voiceMetadata.voiceUrl;
    _totalDuration = Duration(seconds: voiceMetadata.voiceDuration);
    
    // Check if this is a temp message (still sending)
    _isSending = _currentUrl == 'temp_url' || 
                 _currentUrl!.startsWith('temp_') ||
                 widget.message.status == 'sending' ||
                 widget.message.id.startsWith('temp_');

    // TODO: Check if URL is expired and refresh if needed
    // For now, we'll use the URL as-is
  }

  // TODO: Implement voice URL refresh functionality

  Future<void> _togglePlayback() async {
    if (_currentUrl == null || _hasError) return;
    
    // Validate URL before attempting to play
    if (_currentUrl!.isEmpty || 
        _currentUrl == 'temp_url' || 
        _currentUrl!.startsWith('temp_') ||
        (!_currentUrl!.startsWith('http://') && !_currentUrl!.startsWith('https://') && !_currentUrl!.startsWith('blob:'))) {
      AppLogger.error('❌ Cannot play voice: Invalid URL: $_currentUrl');
      setState(() {
        _hasError = true;
      });
      return;
    }

    try {
      if (_isPlaying) {
        await _playerService.pause();
      } else {
        final success = await _playerService.play(_currentUrl!);
        if (success) {
          setState(() {
            _totalDuration = _playerService.totalDuration;
          });
        } else {
          setState(() {
            _hasError = true;
          });
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error toggling playback: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  void _onPlaybackCompleted() {
    // Stop the player and reset UI
    _playerService.stop();
    setState(() {
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
    
    // Call the general playback complete callback
    widget.onPlaybackComplete?.call();
  }


  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_totalDuration == null || _totalDuration!.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration!.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isMe ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with view-once indicator
          Row(
            children: [
              Icon(
                Icons.mic,
                color: widget.isMe ? Colors.white : Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Voice message',
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_totalDuration != null)
                Text(
                  _formatDuration(_totalDuration!),
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.white60,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Playback controls and progress
          Row(
            children: [
              // Play/Pause button (disabled if sending)
              GestureDetector(
                onTap: _isSending ? null : _togglePlayback,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _isSending 
                        ? (widget.isMe ? Colors.grey[300] : Colors.white.withOpacity(0.1))
                        : (widget.isMe ? Colors.white : Colors.white.withOpacity(0.2)),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isMe ? (Colors.grey[600] ?? Colors.grey) : Colors.white70,
                            ),
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: widget.isMe ? Colors.grey[600] : Colors.white,
                          size: 16,
                        ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Progress bar
              Expanded(
                child: Column(
                  children: [
                    // Progress bar
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: (widget.isMe ? Colors.white : Colors.white).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            decoration: BoxDecoration(
                              color: (widget.isMe ? Colors.white : Colors.white).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Progress
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.isMe ? Colors.white : Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Time display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            color: widget.isMe ? Colors.white70 : Colors.white60,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (_totalDuration != null)
                          Text(
                            _formatDuration(_totalDuration!),
                            style: TextStyle(
                              color: widget.isMe ? Colors.white70 : Colors.white60,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Waveform visualization (simplified)
          if (_isPlaying)
            Container(
              height: 20,
              margin: const EdgeInsets.only(top: 8),
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: VoiceWaveformPainter(_waveAnimation.value, _progress),
                    size: const Size(double.infinity, 20),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading voice message...',
            style: TextStyle(
              color: widget.isMe ? Colors.white70 : Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Failed to load voice message',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _waveController.dispose();
    try {
      _playerService.dispose();
    } catch (e) {
      // On web, just_audio dispose() may throw UnimplementedError
      // This is a known issue with just_audio on web
      // Ignore the error as the player will be cleaned up by garbage collection
    }
    super.dispose();
  }
}

class VoiceWaveformPainter extends CustomPainter {
  final double animationValue;
  final double progress;
  
  VoiceWaveformPainter(this.animationValue, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final barWidth = 2.0;
    final barSpacing = 3.0;
    final maxBarHeight = size.height * 0.8;
    
    // Generate waveform based on animation value and progress
    for (double x = 0; x < size.width; x += barWidth + barSpacing) {
      final normalizedX = x / size.width;
      final wave1 = (math.sin(normalizedX * math.pi * 6 + animationValue * math.pi * 2) * 0.5 + 0.5);
      final wave2 = (math.sin(normalizedX * math.pi * 12 + animationValue * math.pi * 3) * 0.3 + 0.7);
      final barHeight = (wave1 * wave2) * maxBarHeight;
      
      // Fade out bars that are past the progress point
      final opacity = normalizedX <= progress ? 1.0 : 0.3;
      paint.color = Colors.white.withOpacity(0.6 * opacity);
      
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(VoiceWaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.progress != progress;
  }
}

