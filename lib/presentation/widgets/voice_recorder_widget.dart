import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nookly/core/services/voice_recording_service.dart';
import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/core/utils/logger.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath, Duration duration)? onRecordingComplete;
  final Function()? onRecordingCancelled;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;

  const VoiceRecorderWidget({
    Key? key,
    this.onRecordingComplete,
    this.onRecordingCancelled,
    this.onStartRecording,
    this.onStopRecording,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final VoiceRecordingService _recordingService = VoiceRecordingService();
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  Duration _currentDuration = Duration.zero;
  RecordingState _recordingState = RecordingState.idle;
  String? _recordingPath;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<RecordingState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupListeners() {
    _durationSubscription = _recordingService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _currentDuration = duration;
        });
      }
    });

    _stateSubscription = _recordingService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _recordingState = state;
        });
        
        switch (state) {
          case RecordingState.recording:
            _pulseController.repeat(reverse: true);
            _waveController.repeat();
            widget.onStartRecording?.call();
            break;
          case RecordingState.stopped:
            _pulseController.stop();
            _waveController.stop();
            widget.onStopRecording?.call();
            // Auto-complete recording when stopped (for hold-to-record UX)
            if (_recordingPath != null) {
              _handleRecordingComplete();
            }
            break;
          case RecordingState.cancelled:
            _pulseController.stop();
            _waveController.stop();
            widget.onRecordingCancelled?.call();
            break;
          case RecordingState.error:
            _pulseController.stop();
            _waveController.stop();
            _showErrorSnackBar('Failed to record voice message');
            break;
          case RecordingState.idle:
            _pulseController.stop();
            _waveController.stop();
            break;
        }
      }
    });
  }

  void _handleRecordingComplete() {
    if (_recordingPath != null) {
      widget.onRecordingComplete?.call(_recordingPath!, _currentDuration);
    }
  }

  Future<void> _startRecording() async {
    try {
      final path = await _recordingService.startRecording();
      if (path != null) {
        setState(() {
          _recordingPath = path;
        });
        AppLogger.info('🎤 Recording started: $path');
      } else {
        _showErrorSnackBar('Failed to start recording');
      }
    } catch (e) {
      AppLogger.error('❌ Error starting recording: $e');
      _showErrorSnackBar('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recordingService.stopRecording();
      if (path != null) {
        setState(() {
          _recordingPath = path;
        });
        AppLogger.info('🛑 Recording stopped: $path');
      }
    } catch (e) {
      AppLogger.error('❌ Error stopping recording: $e');
      _showErrorSnackBar('Failed to stop recording');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recordingService.cancelRecording();
      setState(() {
        _recordingPath = null;
        _currentDuration = Duration.zero;
      });
      AppLogger.info('❌ Recording cancelled');
    } catch (e) {
      AppLogger.error('❌ Error cancelling recording: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording status and duration
          Row(
            children: [
              Icon(
                _recordingState == RecordingState.recording ? Icons.mic : Icons.mic_none,
                color: _recordingState == RecordingState.recording ? Colors.red : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _recordingState == RecordingState.recording ? 'Recording...' : 'Hold to record',
                style: const TextStyle(
                  color: AppColors.white85,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_recordingState == RecordingState.recording)
                Text(
                  _formatDuration(_currentDuration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Recording controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel button
              if (_recordingState == RecordingState.recording)
                GestureDetector(
                  onTap: _cancelRecording,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              
              // Record/Stop button
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                onTap: () {
                  if (_recordingState == RecordingState.recording) {
                    _stopRecording();
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _recordingState == RecordingState.recording ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _recordingState == RecordingState.recording ? Colors.red : AppColors.white85,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_recordingState == RecordingState.recording ? Colors.red : AppColors.white85).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _recordingState == RecordingState.recording ? Icons.stop : Icons.mic,
                          color: _recordingState == RecordingState.recording ? AppColors.white85 : Colors.grey[600],
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Send button (only show when recording is stopped)
              if (_recordingState == RecordingState.stopped && _recordingPath != null)
                GestureDetector(
                  onTap: _handleRecordingComplete,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          
          // Waveform visualization (simplified)
          if (_recordingState == RecordingState.recording)
            Container(
              height: 40,
              margin: const EdgeInsets.only(top: 12),
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaveformPainter(_waveAnimation.value),
                    size: const Size(double.infinity, 40),
                  );
                },
              ),
            ),
          
          // Max duration warning
          if (_currentDuration.inSeconds >= VoiceRecordingService.maxDurationSeconds - 10)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Text(
                'Max duration: ${VoiceRecordingService.maxDurationSeconds ~/ 60} minutes',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _recordingService.dispose();
    super.dispose();
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;
  
  WaveformPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final barWidth = 3.0;
    final barSpacing = 4.0;
    final maxBarHeight = size.height * 0.8;
    
    // Generate random-like waveform based on animation value
    for (double x = 0; x < size.width; x += barWidth + barSpacing) {
      final normalizedX = x / size.width;
      final wave1 = (math.sin(normalizedX * math.pi * 4 + animationValue * math.pi * 2) * 0.5 + 0.5);
      final wave2 = (math.sin(normalizedX * math.pi * 8 + animationValue * math.pi * 3) * 0.3 + 0.7);
      final barHeight = (wave1 * wave2) * maxBarHeight;
      
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

