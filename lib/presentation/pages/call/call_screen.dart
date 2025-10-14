import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/core/services/hms_call_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/call_api_service.dart';
import 'package:nookly/core/di/injection_container.dart';

/// Call Screen - Main UI for audio/video calls
/// 
/// Features:
/// - Video rendering for both local and remote participants
/// - Call controls (mute, video on/off, speaker, end call)
/// - Loading states and connection status
/// - Proper error handling
class CallScreen extends StatefulWidget {
  final String roomId;
  final String authToken;
  final bool isAudioCall;
  final String participantName;
  final String? participantAvatar;
  final VoidCallback onCallEnded;

  const CallScreen({
    Key? key,
    required this.roomId,
    required this.authToken,
    required this.isAudioCall,
    required this.participantName,
    this.participantAvatar,
    required this.onCallEnded,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late HMSCallService _callService;
  
  bool _isConnecting = true;
  bool _isCallActive = false;
  bool _isEndingCall = false;
  String _connectionStatus = 'Initializing call...';
  
  // Loading states for buttons
  bool _isMutingAudio = false;
  bool _isMutingVideo = false;
  bool _isChangingSpeaker = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      setState(() {
        _connectionStatus = 'Initializing call service...';
      });
      
      // Get the call service from DI
      _callService = sl<HMSCallService>();
      
      // Initialize if needed
      await _callService.initialize();
      
      setState(() {
        _connectionStatus = 'Setting up call...';
      });
      
      // Set up callbacks
      _callService.onMuteStateChanged = () {
        if (mounted) setState(() {});
      };
      
      _callService.onTracksChanged = () {
        if (mounted) setState(() {});
      };
      
      // Set API service
      final callApiService = sl<CallApiService>();
      _callService.setCallApiService(callApiService);
      
      setState(() {
        _connectionStatus = 'Joining call room...';
      });
      
      // Join the call room
      await _callService.joinRoom(widget.roomId, widget.authToken);
      
      setState(() {
        _isConnecting = false;
        _isCallActive = true;
        _connectionStatus = 'Connected';
      });
      
      AppLogger.info('✅ Call screen initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize call screen: $e');
      if (mounted) {
        setState(() {
          _connectionStatus = 'Connection failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to call: $e'),
            backgroundColor: Colors.red,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  void dispose() {
    AppLogger.info('🔚 CallScreen dispose called');
    // Don't dispose the service here - it's managed by CallManager
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen for video calls)
            if (!widget.isAudioCall)
              Positioned.fill(
                child: _callService.createRemoteVideoView(),
              ),
            
            // Audio call view
            if (widget.isAudioCall)
              _buildAudioCallView(),
            
            // Local video (small overlay for video calls)
            if (!widget.isAudioCall)
              Positioned(
                right: 20,
                top: 20,
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _callService.isLocalVideoReady 
                      ? _callService.createLocalVideoView()
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white24,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_off,
                                  color: Colors.white54,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            
            // Participant info at top
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.participantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // Call controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Status indicator
                    if (_connectionStatus != 'Connected')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _connectionStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _buildCallControls(),
                  ],
                ),
              ),
            ),
            
            // Connecting indicator
            if (_isConnecting)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        _connectionStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Ending call indicator
            if (_isEndingCall)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        _connectionStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCallView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomAvatar(
            name: widget.participantName,
            size: 120,
            imageUrl: widget.participantAvatar,
          ),
          const SizedBox(height: 20),
          Text(
            widget.participantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isConnecting ? 'Connecting...' : 'On Call',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute/Unmute audio
        _buildControlButtonWithLoading(
          icon: _callService.isAudioMuted ? Icons.mic_off : Icons.mic,
          onPressed: _isMutingAudio ? () {} : _toggleAudioMute,
          isLoading: _isMutingAudio,
          backgroundColor: _callService.isAudioMuted 
              ? Colors.red 
              : Colors.white.withOpacity(0.2),
        ),
        
        // Mute/Unmute video (only for video calls)
        if (!widget.isAudioCall)
          _buildControlButtonWithLoading(
            icon: _callService.isVideoMuted ? Icons.videocam_off : Icons.videocam,
            onPressed: _isMutingVideo ? () {} : _toggleVideoMute,
            isLoading: _isMutingVideo,
            backgroundColor: _callService.isVideoMuted 
                ? Colors.red 
                : Colors.white.withOpacity(0.2),
          ),
        
        // Speaker on/off
        _buildControlButtonWithLoading(
          icon: _callService.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          onPressed: _isChangingSpeaker ? () {} : _toggleSpeaker,
          isLoading: _isChangingSpeaker,
        ),
        
        // End call
        _buildControlButtonWithLoading(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          onPressed: _isEndingCall ? () {} : _endCall,
          isLoading: _isEndingCall,
        ),
      ],
    );
  }

  Widget _buildControlButtonWithLoading({
    required IconData icon,
    Color? backgroundColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 24,
      ),
    );
  }

  Future<void> _endCall() async {
    try {
      setState(() {
        _isEndingCall = true;
        _connectionStatus = 'Ending call...';
      });
      
      AppLogger.info('🔚 End call button pressed');
      
      widget.onCallEnded();
      
      setState(() {
        _isCallActive = false;
        _connectionStatus = 'Call ended';
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('❌ Error ending call: $e');
      setState(() {
        _isEndingCall = false;
        _connectionStatus = 'Error ending call';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAudioMute() async {
    try {
      AppLogger.info('🎤 Audio mute button pressed');
      
      // Check if HMS is ready
      final isReady = await _callService.isHMSReady();
      if (!isReady) {
        AppLogger.warning('⚠️ HMS not ready for audio mute');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Call not ready. Please wait...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isMutingAudio = true;
      });
      
      final newMuteState = !_callService.isAudioMuted;
      await _callService.muteAudio(newMuteState);
      
      setState(() {
        _isMutingAudio = false;
      });
      
      // Force UI update after delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });
    } catch (e) {
      AppLogger.error('❌ Error muting audio: $e');
      setState(() {
        _isMutingAudio = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mute audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleVideoMute() async {
    try {
      AppLogger.info('📹 Video mute button pressed');
      
      // Check if HMS is ready
      final isReady = await _callService.isHMSReady();
      if (!isReady) {
        AppLogger.warning('⚠️ HMS not ready for video mute');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Call not ready. Please wait...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isMutingVideo = true;
      });
      
      final newCameraState = !_callService.isVideoMuted;
      await _callService.muteVideo(newCameraState);
      
      setState(() {
        _isMutingVideo = false;
      });
    } catch (e) {
      AppLogger.error('❌ Error muting video: $e');
      setState(() {
        _isMutingVideo = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mute video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      setState(() {
        _isChangingSpeaker = true;
      });
      
      final newSpeakerState = !_callService.isSpeakerOn;
      await _callService.setSpeakerphone(newSpeakerState);
      
      setState(() {
        _isChangingSpeaker = false;
      });
    } catch (e) {
      AppLogger.error('❌ Error setting speakerphone: $e');
      setState(() {
        _isChangingSpeaker = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change speaker: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

