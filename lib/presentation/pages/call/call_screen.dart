import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:nookly/core/services/call_service.dart';
import 'package:nookly/core/utils/logger.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final bool isAudioCall;
  final String participantName;
  final String? participantAvatar;
  final VoidCallback onCallEnded;

  const CallScreen({
    Key? key,
    required this.channelName,
    required this.isAudioCall,
    required this.participantName,
    this.participantAvatar,
    required this.onCallEnded,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _callService.startCall(widget.channelName, widget.isAudioCall);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        AppLogger.info('✅ Call initialized successfully');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to initialize call: $e');
      // Handle initialization error
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _callService.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video view
            if (!widget.isAudioCall)
              _buildVideoView(),

            // Audio call view
            if (widget.isAudioCall)
              _buildAudioCallView(),

            // Call controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildCallControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    return Stack(
      children: [
        // Remote video
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _callService.engine!,
            canvas: const VideoCanvas(uid: 0),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        ),
        // Local video (small overlay)
        Positioned(
          right: 20,
          top: 20,
          child: SizedBox(
            width: 100,
            height: 150,
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _callService.engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioCallView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: widget.participantAvatar != null
                ? NetworkImage(widget.participantAvatar!)
                : null,
            child: widget.participantAvatar == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            widget.participantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Calling...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
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
        _buildControlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          onPressed: () {
            setState(() => _isMuted = !_isMuted);
            _callService.engine?.muteLocalAudioStream(_isMuted);
          },
        ),
        if (!widget.isAudioCall)
          _buildControlButton(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            onPressed: () {
              setState(() => _isCameraOff = !_isCameraOff);
              _callService.engine?.muteLocalVideoStream(_isCameraOff);
            },
          ),
        _buildControlButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          onPressed: () {
            setState(() => _isSpeakerOn = !_isSpeakerOn);
            _callService.engine?.setEnableSpeakerphone(_isSpeakerOn);
          },
        ),
        _buildControlButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          onPressed: () {
            _callService.endCall();
            widget.onCallEnded();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.white24,
  }) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: backgroundColor,
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        onPressed: onPressed,
      ),
    );
  }
} 