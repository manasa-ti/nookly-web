import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/call_api_service.dart';

/// Enhanced HMS Call Service with fixes for video track and mute state issues
/// 
/// Key Improvements:
/// - State machine for video track lifecycle
/// - Callback-based mute state management (single source of truth)
/// - StreamController for reactive UI updates
/// - Proper disposal and cleanup
/// - Enhanced error handling
class HMSCallService implements HMSUpdateListener {
  HMSSDK? _hmsSDK;
  bool _isInitialized = false;
  bool _isInCall = false;
  bool _isAudioCall = false;
  String? _currentRoomId;
  String? _currentAuthToken;
  
  // Call state - Updated ONLY from HMS callbacks
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  
  // Peer and track variables
  HMSPeer? _localPeer;
  HMSPeer? _remotePeer;
  HMSVideoTrack? _localVideoTrack;
  HMSVideoTrack? _remoteVideoTrack;
  
  // Video track state machine
  VideoTrackState _localVideoState = VideoTrackState.notInitialized;
  VideoTrackState _remoteVideoState = VideoTrackState.notInitialized;
  
  // Stream controller for reactive updates
  final _videoStateController = StreamController<void>.broadcast();
  Stream<void> get videoStateStream => _videoStateController.stream;
  
  // Disposal flag
  bool _isDisposed = false;
  
  // Event callbacks
  Function(String)? onUserJoined;
  Function(String)? onUserLeft;
  Function(String)? onCallEnded;
  Function(String)? onError;
  VoidCallback? onMuteStateChanged;
  VoidCallback? onTracksChanged;

  // API Service
  CallApiService? _callApiService;

  void setCallApiService(CallApiService callApiService) {
    _callApiService = callApiService;
  }

  /// Initialize HMS SDK and request permissions
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      AppLogger.info('🚀 Starting 100ms initialization...');
      await _requestPermissions();
      
      AppLogger.info('🔧 Creating HMSSDK instance...');
      _hmsSDK = HMSSDK();
      
      AppLogger.info('🔧 Building HMSSDK...');
      await _hmsSDK!.build();
      
      // Register this service as listener
      _hmsSDK!.addUpdateListener(listener: this);
      AppLogger.info('🔧 HMS SDK listener registered');
      
      _isInitialized = true;
      AppLogger.info('✅ 100ms call service initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize 100ms: $e');
      rethrow;
    }
  }

  /// Request necessary permissions for calls
  Future<void> _requestPermissions() async {
    try {
      AppLogger.info('🔐 Requesting permissions...');
      final permissions = [
        Permission.microphone,
        Permission.camera,
      ];
      
      final statuses = await permissions.request();
      
      bool allGranted = true;
      for (final status in statuses.entries) {
        AppLogger.info('🔐 ${status.key}: ${status.value}');
        if (!status.value.isGranted) {
          allGranted = false;
          AppLogger.warning('⚠️ Permission not granted: ${status.key}');
        }
      }
      
      if (!allGranted) {
        AppLogger.warning('⚠️ Some permissions not granted, but continuing');
      } else {
        AppLogger.info('✅ All permissions granted');
      }
    } catch (e) {
      AppLogger.warning('⚠️ Error requesting permissions: $e');
    }
  }

  /// Initiate a call with another user
  Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String callType,
  }) async {
    if (!_isInitialized) await initialize();
    if (_callApiService == null) {
      throw Exception('CallApiService not set');
    }

    try {
      _isAudioCall = callType == 'audio';
      
      // Call backend API to initiate call
      final response = await _callApiService!.initiateCall(
        receiverId: receiverId,
        callType: callType,
      );

      final callSession = response['callSession'];
      final tokens = response['tokens'];
      
      AppLogger.info('🔍 Backend response structure:');
      AppLogger.info('🔍 - Full response: $response');
      AppLogger.info('🔍 - callSession: $callSession');
      AppLogger.info('🔍 - tokens: $tokens');
      
      if (callSession == null) {
        throw Exception('Backend response missing callSession');
      }
      
      if (tokens == null) {
        throw Exception('Backend response missing tokens');
      }
      
      _currentRoomId = callSession['hmsRoomId'] ?? callSession['roomId'];
      _currentAuthToken = tokens['caller']['token'];
      
      AppLogger.info('🔍 Parsed values:');
      AppLogger.info('🔍 - Room ID: $_currentRoomId');
      AppLogger.info('🔍 - Auth Token: $_currentAuthToken');
      
      if (_currentRoomId == null) {
        throw Exception('Backend response missing room ID (both hmsRoomId and roomId are null)');
      }
      
      if (_currentAuthToken == null) {
        throw Exception('Backend response missing auth token');
      }
      
      // Now safe to use ! operator
      await joinRoom(_currentRoomId!, _currentAuthToken!);
      
      AppLogger.info('✅ Call initiated successfully');
      return response;
    } catch (e) {
      AppLogger.error('❌ Failed to initiate call: $e');
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<Map<String, dynamic>> acceptCall({
    required String roomId,
  }) async {
    if (!_isInitialized) await initialize();
    if (_callApiService == null) {
      throw Exception('CallApiService not set');
    }

    try {
      final response = await _callApiService!.acceptCall(roomId: roomId);
      
      AppLogger.info('🔍 Accept call response structure:');
      AppLogger.info('🔍 - Full response: $response');
      
      final callSession = response['callSession'];
      
      if (callSession == null) {
        throw Exception('Backend response missing callSession for accept call');
      }
      
      // Handle both nested and direct token structures
      String? token;
      if (response['token'] is Map) {
        token = response['token']['token'];
      } else {
        token = response['token'];
      }
      
      AppLogger.info('🔍 Parsed accept call values:');
      AppLogger.info('🔍 - Token: $token');
      AppLogger.info('🔍 - Call type: ${callSession['callType']}');
      
      if (token == null) {
        throw Exception('Backend response missing token for accept call');
      }
      
      _currentRoomId = roomId;
      _currentAuthToken = token;
      _isAudioCall = callSession['callType'] == 'audio';
      
      // Now safe to use ! operator
      await joinRoom(_currentRoomId!, _currentAuthToken!);
      
      AppLogger.info('✅ Call accepted successfully');
      return response;
    } catch (e) {
      AppLogger.error('❌ Failed to accept call: $e');
      rethrow;
    }
  }

  /// Join 100ms room with token
  Future<void> joinRoom(String roomId, String authToken) async {
    if (_isDisposed) {
      AppLogger.warning('⚠️ Cannot join room - service disposed');
      return;
    }

    try {
      AppLogger.info('🚪 ============================================');
      AppLogger.info('🚪 JOINING ROOM');
      AppLogger.info('🚪 - Room ID: $roomId');
      AppLogger.info('🚪 - Is Audio Call: $_isAudioCall');
      AppLogger.info('🚪 - SDK Initialized: $_isInitialized');
      AppLogger.info('🚪 ============================================');
      
      if (!_isInitialized) {
        AppLogger.error('❌ HMS SDK not initialized!');
        await initialize();
      }
      
      if (_hmsSDK == null) {
        throw Exception('HMS SDK not initialized');
      }
      
      // Reset state
      _clearVideoTracks();
      AppLogger.info('🚪 Video tracks cleared');
      
      // Register listener
      _hmsSDK!.addUpdateListener(listener: this);
      AppLogger.info('🎧 HMS Update Listener registered');
      
      AppLogger.info('🚪 Calling HMS join...');
      // Join the room
      await _hmsSDK!.join(
        config: HMSConfig(
          authToken: authToken,
          userName: 'User_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      
      _isInCall = true;
      _currentRoomId = roomId;
      _currentAuthToken = authToken;
      
      AppLogger.info('✅ HMS join() completed');
      AppLogger.info('✅ In call: $_isInCall');
      AppLogger.info('✅ Successfully joined 100ms room: $roomId');
    } catch (e) {
      AppLogger.error('❌ Failed to join 100ms room: $e');
      rethrow;
    }
  }

  /// Clear all video tracks and reset state
  void _clearVideoTracks() {
    _localVideoTrack = null;
    _remoteVideoTrack = null;
    _localVideoState = VideoTrackState.notInitialized;
    _remoteVideoState = VideoTrackState.notInitialized;
    _localPeer = null;
    _remotePeer = null;
    _videoStateController.add(null);
    AppLogger.info('🧹 Cleared all video tracks and state');
  }

  /// Initialize local video track (called after joining)
  Future<void> _initializeLocalVideoTrack() async {
    if (_isDisposed) return;
    
    try {
      _localVideoState = VideoTrackState.initializing;
      _videoStateController.add(null);
      
      // Poll for video track with timeout
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (_isDisposed) return;
        
        final localPeer = await _hmsSDK!.getLocalPeer();
        
        if (localPeer != null && localPeer.videoTrack != null) {
          _localVideoTrack = localPeer.videoTrack;
          _localPeer = localPeer;
          _localVideoState = VideoTrackState.ready;
          _videoStateController.add(null);
          AppLogger.info('✅ Local video track initialized');
          return;
        }
      }
      
      // Timeout - but don't fail, might be audio-only
      _localVideoState = _isAudioCall 
          ? VideoTrackState.notInitialized 
          : VideoTrackState.failed;
      _videoStateController.add(null);
      AppLogger.warning('⚠️ Local video track initialization timeout');
    } catch (e) {
      _localVideoState = VideoTrackState.failed;
      _videoStateController.add(null);
      AppLogger.error('❌ Failed to initialize local video: $e');
    }
  }

  /// End the current call
  Future<void> endCall() async {
    if (_isDisposed) {
      AppLogger.warning('⚠️ Cannot end call - service disposed');
      return;
    }

    if (!_isInCall || _currentRoomId == null) {
      AppLogger.info('ℹ️ No active call to end');
      return;
    }

    try {
      AppLogger.info('🔚 Ending call for room: $_currentRoomId');
      
      // Leave HMS room first
      if (_hmsSDK != null) {
        try {
          await _hmsSDK!.leave();
          AppLogger.info('✅ Left HMS room successfully');
        } catch (e) {
          AppLogger.warning('⚠️ Error leaving HMS room: $e');
        }
      }
      
      // Notify backend
      try {
        await _callApiService!.endCall(roomId: _currentRoomId!);
        AppLogger.info('✅ Backend notified of call end');
      } catch (backendError) {
        AppLogger.warning('⚠️ Backend call end failed: $backendError');
      }
      
      // Reset state
      _resetCallState();
      
      AppLogger.info('✅ Call ended successfully');
    } catch (e) {
      AppLogger.error('❌ Error ending call: $e');
      _resetCallState();
      rethrow;
    }
  }

  /// Reset call state completely
  void _resetCallState() {
    _isInCall = false;
    _currentRoomId = null;
    _currentAuthToken = null;
    _isMuted = false;
    _isCameraOff = false;
    _isSpeakerOn = true;
    _clearVideoTracks();
    AppLogger.info('🔄 Call state reset complete');
  }

  /// Reject an incoming call
  Future<void> rejectCall({
    required String roomId,
  }) async {
    if (_callApiService == null) {
      throw Exception('CallApiService not set');
    }

    try {
      await _callApiService!.rejectCall(roomId: roomId);
      AppLogger.info('✅ Call rejected successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to reject call: $e');
      rethrow;
    }
  }

  // ============================================================================
  // AUDIO/VIDEO CONTROLS - State updated from HMS callbacks ONLY
  // ============================================================================

  /// Mute/unmute audio
  /// State will be updated via onTrackUpdate callback
  Future<void> muteAudio(bool muted) async {
    if (_isDisposed || !_isInCall) {
      AppLogger.warning('⚠️ Cannot mute audio - disposed or not in call');
      return;
    }

    AppLogger.info('🎤 Requesting audio ${muted ? 'mute' : 'unmute'}...');
    
    try {
      final localPeer = await _hmsSDK!.getLocalPeer();
      if (localPeer?.audioTrack != null) {
        // Request change - state will update via callback
        await _hmsSDK!.switchAudio(isOn: !muted);
        AppLogger.info('✅ Audio mute request sent to HMS');
      } else {
        AppLogger.warning('⚠️ No audio track available');
      }
    } catch (e) {
      AppLogger.error('❌ Error switching audio: $e');
    }
  }

  /// Mute/unmute video
  /// State will be updated via onTrackUpdate callback
  Future<void> muteVideo(bool muted) async {
    if (_isDisposed || !_isInCall) {
      AppLogger.warning('⚠️ Cannot mute video - disposed or not in call');
      return;
    }

    AppLogger.info('📹 Requesting video ${muted ? 'mute' : 'unmute'}...');
    
    try {
      final localPeer = await _hmsSDK!.getLocalPeer();
      if (localPeer?.videoTrack != null) {
        // Request change - state will update via callback
        await _hmsSDK!.switchVideo(isOn: !muted);
        AppLogger.info('✅ Video mute request sent to HMS');
      } else {
        AppLogger.warning('⚠️ No video track available');
      }
    } catch (e) {
      AppLogger.error('❌ Error switching video: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_isDisposed || !_isInCall) {
      AppLogger.warning('⚠️ Cannot switch camera - disposed or not in call');
      return;
    }

    AppLogger.info('📷 Camera switching not implemented in current HMS SDK version');
  }

  /// Enable/disable speakerphone
  Future<void> setSpeakerphone(bool enabled) async {
    if (_isDisposed) {
      AppLogger.warning('⚠️ Cannot set speakerphone - service disposed');
      return;
    }

    AppLogger.info('🔊 setSpeakerphone called - enabled: $enabled');
    _isSpeakerOn = enabled;
    AppLogger.info('✅ Speakerphone ${enabled ? 'enabled' : 'disabled'}');
  }

  // ============================================================================
  // VIDEO RENDERING - Using StreamBuilder for reactive updates
  // ============================================================================

  /// Create local video view widget
  Widget createLocalVideoView() {
    AppLogger.info('🎥 Creating local video view - State: $_localVideoState, Track: ${_localVideoTrack?.trackId}');
    
    return StreamBuilder<void>(
      stream: videoStateStream,
      builder: (context, snapshot) {
        if (_isDisposed) {
          AppLogger.warning('🎥 Local video unavailable - service disposed');
          return _buildVideoPlaceholder('Service disposed');
        }

        switch (_localVideoState) {
          case VideoTrackState.ready:
            if (_localVideoTrack != null) {
              AppLogger.info('🎥 Local video ready - track ID: ${_localVideoTrack!.trackId}');
              return HMSVideoView(
                track: _localVideoTrack!,
                key: ValueKey('local_video_${_localVideoTrack!.trackId}'),
                setMirror: true,
                scaleType: ScaleType.SCALE_ASPECT_FILL,
              );
            }
            AppLogger.warning('🎥 Local video state ready but track is null');
            return _buildVideoPlaceholder('Track unavailable');
            
          case VideoTrackState.initializing:
            return _buildVideoPlaceholder('Initializing camera...');
            
          case VideoTrackState.failed:
            return _buildVideoPlaceholder('Camera unavailable');
            
          case VideoTrackState.notInitialized:
            return _buildVideoPlaceholder('Not connected');
        }
      },
    );
  }

  /// Create remote video view widget
  Widget createRemoteVideoView() {
    AppLogger.info('🎥 Creating remote video view - State: $_remoteVideoState, Track: ${_remoteVideoTrack?.trackId}');
    
    return StreamBuilder<void>(
      stream: videoStateStream,
      builder: (context, snapshot) {
        if (_isDisposed) {
          AppLogger.warning('🎥 Remote video unavailable - service disposed');
          return _buildVideoPlaceholder('Service disposed');
        }

        switch (_remoteVideoState) {
          case VideoTrackState.ready:
            if (_remoteVideoTrack != null) {
              AppLogger.info('🎥 Remote video ready - track ID: ${_remoteVideoTrack!.trackId}');
              return HMSVideoView(
                track: _remoteVideoTrack!,
                key: ValueKey('remote_video_${_remoteVideoTrack!.trackId}'),
                scaleType: ScaleType.SCALE_ASPECT_FILL,
              );
            }
            AppLogger.warning('🎥 Remote video state ready but track is null');
            return _buildVideoPlaceholder('Participant video unavailable');
            
          case VideoTrackState.initializing:
            return _buildVideoPlaceholder('Connecting to participant...');
            
          case VideoTrackState.failed:
            return _buildVideoPlaceholder('Participant video unavailable');
            
          case VideoTrackState.notInitialized:
            return _buildVideoPlaceholder('Waiting for participant...');
        }
      },
    );
  }

  /// Build video placeholder widget
  Widget _buildVideoPlaceholder(String message) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off,
              color: Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  bool get isInCall => _isInCall && !_isDisposed;
  bool get isAudioCall => _isAudioCall;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get currentRoomId => _currentRoomId;
  String? get currentAuthToken => _currentAuthToken;
  HMSSDK? get hmsSDK => _hmsSDK;
  
  // Convenience getters for UI
  bool get isAudioMuted => _isMuted;
  bool get isVideoMuted => _isCameraOff;
  bool get isLocalVideoReady => _localVideoState == VideoTrackState.ready;
  bool get isRemoteVideoReady => _remoteVideoState == VideoTrackState.ready;
  
  /// Check if HMS SDK is ready
  Future<bool> isHMSReady() async {
    if (_hmsSDK == null || _isDisposed) {
      AppLogger.warning('⚠️ HMS SDK is null or service disposed');
      return false;
    }
    
    try {
      final localPeer = await _hmsSDK!.getLocalPeer();
      return localPeer != null && _isInCall && !_isDisposed;
    } catch (e) {
      AppLogger.error('❌ Error checking HMS readiness: $e');
      return false;
    }
  }

  // ============================================================================
  // DISPOSAL
  // ============================================================================

  void dispose() {
    if (_isDisposed) {
      AppLogger.info('ℹ️ Service already disposed');
      return;
    }

    AppLogger.info('🔚 Disposing HMS call service...');
    
    // End call if active
    if (_isInCall) {
      try {
        endCall();
      } catch (e) {
        AppLogger.warning('⚠️ Error ending call during disposal: $e');
      }
    }
    
    // Remove listener
    if (_hmsSDK != null) {
      try {
        _hmsSDK!.removeUpdateListener(listener: this);
        AppLogger.info('🔧 Removed HMS SDK listener');
      } catch (e) {
        AppLogger.warning('⚠️ Error removing HMS SDK listener: $e');
      }
    }
    
    // Close stream controller
    _videoStateController.close();
    
    // Clear state
    _resetCallState();
    _isInitialized = false;
    _isDisposed = true;
    
    AppLogger.info('✅ 100ms call service disposed');
  }

  // ============================================================================
  // HMS UPDATE LISTENER IMPLEMENTATIONS
  // ============================================================================

  @override
  void onJoin({required HMSRoom room}) {
    if (_isDisposed) return;
    
    AppLogger.info('🎉 ============================================');
    AppLogger.info('🎉 onJoin called');
    AppLogger.info('🎉 - Room ID: ${room.id}');
    AppLogger.info('🎉 - Room Name: ${room.name}');
    AppLogger.info('🎉 - Total peers: ${room.peers?.length ?? 0}');
    
    // Log all peers
    if (room.peers != null) {
      for (var peer in room.peers!) {
        AppLogger.info('🎉 Peer in room: ${peer.name} (isLocal: ${peer.isLocal})');
        AppLogger.info('🎉   - Peer ID: ${peer.peerId}');
        AppLogger.info('🎉   - Role: ${peer.role?.name}');
        AppLogger.info('🎉   - Video Track: ${peer.videoTrack?.trackId ?? "NULL"}');
        AppLogger.info('🎉   - Audio Track: ${peer.audioTrack?.trackId ?? "NULL"}');
        
        // Immediately assign tracks if available
        if (peer.isLocal) {
          _localPeer = peer;
          if (peer.videoTrack != null && !_isAudioCall) {
            _localVideoTrack = peer.videoTrack;
            _localVideoState = VideoTrackState.ready;
            _videoStateController.add(null);
            AppLogger.info('🎉 ✅ LOCAL VIDEO ASSIGNED ON JOIN: ${peer.videoTrack!.trackId}');
          }
          if (peer.audioTrack != null) {
            _isMuted = peer.audioTrack!.isMute;
            AppLogger.info('🎉 ✅ LOCAL AUDIO state: ${_isMuted ? "MUTED" : "UNMUTED"}');
          }
        } else {
          _remotePeer = peer;
          if (peer.videoTrack != null && !_isAudioCall) {
            _remoteVideoTrack = peer.videoTrack;
            _remoteVideoState = VideoTrackState.ready;
            _videoStateController.add(null);
            AppLogger.info('🎉 ✅ REMOTE VIDEO ASSIGNED ON JOIN: ${peer.videoTrack!.trackId}');
          }
        }
      }
    }
    AppLogger.info('🎉 ============================================');
    
    _isInCall = true;
    _currentRoomId = room.id;
    
    // Initialize video tracks if not already assigned
    if (!_isAudioCall && _localVideoState != VideoTrackState.ready) {
      AppLogger.info('🎉 Starting video track initialization...');
      _initializeLocalVideoTrack();
    }
    
    AppLogger.info('✅ Successfully joined room: ${room.id}');
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    if (_isDisposed) return;
    
    AppLogger.info('👤 ============================================');
    AppLogger.info('👤 PEER UPDATE: ${peer.name}');
    AppLogger.info('👤 - Update Type: $update');
    AppLogger.info('👤 - Is Local: ${peer.isLocal}');
    AppLogger.info('👤 - Peer ID: ${peer.peerId}');
    AppLogger.info('👤 - Role: ${peer.role?.name ?? "unknown"}');
    AppLogger.info('👤 - Video Track: ${peer.videoTrack != null ? "Available (${peer.videoTrack?.trackId})" : "NULL"}');
    AppLogger.info('👤 - Audio Track: ${peer.audioTrack != null ? "Available (${peer.audioTrack?.trackId})" : "NULL"}');
    AppLogger.info('👤 - Auxiliary Tracks: ${peer.auxiliaryTracks?.length ?? 0}');
    AppLogger.info('👤 ============================================');
    
    switch (update) {
      case HMSPeerUpdate.peerJoined:
        if (!peer.isLocal) {
          _remotePeer = peer;
          onUserJoined?.call(peer.name);
          AppLogger.info('✅ REMOTE PEER JOINED: ${peer.name}');
          
          if (peer.videoTrack != null) {
            _remoteVideoTrack = peer.videoTrack;
            _remoteVideoState = VideoTrackState.ready;
            _videoStateController.add(null);
            AppLogger.info('📹 ✅ Remote video track IMMEDIATELY available on join');
            AppLogger.info('📹 ✅ Track ID: ${peer.videoTrack!.trackId}');
            AppLogger.info('📹 ✅ Track source: ${peer.videoTrack!.source}');
            AppLogger.info('📹 ✅ Track muted: ${peer.videoTrack!.isMute}');
          } else {
            AppLogger.warning('⚠️ Remote video track is NULL on peer join');
            AppLogger.warning('⚠️ Will wait for trackAdded event');
            _remoteVideoState = VideoTrackState.initializing;
            _videoStateController.add(null);
          }
        } else {
          _localPeer = peer;
          AppLogger.info('✅ LOCAL PEER JOINED: ${peer.name}');
          if (peer.videoTrack != null) {
            AppLogger.info('📹 ✅ Local video track available: ${peer.videoTrack!.trackId}');
          } else {
            AppLogger.warning('⚠️ Local video track is NULL on join');
          }
        }
        break;
        
      case HMSPeerUpdate.peerLeft:
        if (!peer.isLocal) {
          _remotePeer = null;
          _remoteVideoTrack = null;
          _remoteVideoState = VideoTrackState.notInitialized;
          _videoStateController.add(null);
          onUserLeft?.call(peer.name);
          AppLogger.info('❌ REMOTE PEER LEFT: ${peer.name}');
        }
        break;
        
      default:
        AppLogger.info('🔄 OTHER PEER UPDATE: $update for ${peer.name} (isLocal: ${peer.isLocal})');
        break;
    }
  }

  @override
  void onTrackUpdate({
    required HMSTrack track,
    required HMSTrackUpdate trackUpdate,
    required HMSPeer peer,
  }) {
    if (_isDisposed) return;
    
    AppLogger.info('🎵 ============================================');
    AppLogger.info('🎵 TRACK UPDATE');
    AppLogger.info('🎵 - Track Kind: ${track.kind}');
    AppLogger.info('🎵 - Track Update: $trackUpdate');
    AppLogger.info('🎵 - Peer: ${peer.name} (isLocal: ${peer.isLocal})');
    AppLogger.info('🎵 - Track ID: ${track.trackId}');
    AppLogger.info('🎵 - Track Source: ${track.source}');
    AppLogger.info('🎵 - Track Muted: ${track.isMute}');
    AppLogger.info('🎵 ============================================');
    
    if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
      _handleVideoTrackUpdate(track as HMSVideoTrack, trackUpdate, peer);
    } else if (track.kind == HMSTrackKind.kHMSTrackKindAudio) {
      _handleAudioTrackUpdate(track, trackUpdate, peer);
    }
  }

  /// Handle video track updates - single source of truth for video state
  void _handleVideoTrackUpdate(
    HMSVideoTrack track,
    HMSTrackUpdate update,
    HMSPeer peer,
  ) {
    if (peer.isLocal) {
      AppLogger.info('📹 LOCAL VIDEO TRACK UPDATE');
      switch (update) {
        case HMSTrackUpdate.trackAdded:
          _localVideoTrack = track;
          _localVideoState = VideoTrackState.ready;
          _isCameraOff = track.isMute;
          AppLogger.info('📹 ✅ LOCAL video track ADDED');
          AppLogger.info('📹 - Track ID: ${track.trackId}');
          AppLogger.info('📹 - Track state: $_localVideoState');
          AppLogger.info('📹 - Camera off: $_isCameraOff');
          onMuteStateChanged?.call();
          break;
          
        case HMSTrackUpdate.trackRemoved:
          _localVideoTrack = null;
          _localVideoState = VideoTrackState.notInitialized;
          AppLogger.info('📹 ❌ LOCAL video track REMOVED');
          break;
          
        case HMSTrackUpdate.trackMuted:
        case HMSTrackUpdate.trackUnMuted:
          // Update state from HMS - single source of truth
          _isCameraOff = track.isMute;
          AppLogger.info('📹 LOCAL video ${track.isMute ? 'MUTED' : 'UNMUTED'}');
          onMuteStateChanged?.call();
          break;
          
        default:
          AppLogger.info('📹 LOCAL video other update: $update');
          break;
      }
      _videoStateController.add(null);
    } else {
      AppLogger.info('📹 REMOTE VIDEO TRACK UPDATE');
      switch (update) {
        case HMSTrackUpdate.trackAdded:
          _remoteVideoTrack = track;
          _remoteVideoState = VideoTrackState.ready;
          AppLogger.info('📹 ✅ REMOTE video track ADDED');
          AppLogger.info('📹 - Track ID: ${track.trackId}');
          AppLogger.info('📹 - Track source: ${track.source}');
          AppLogger.info('📹 - Track muted: ${track.isMute}');
          AppLogger.info('📹 - Track state: $_remoteVideoState');
          AppLogger.info('📹 - Current remote track: ${_remoteVideoTrack?.trackId}');
          break;
          
        case HMSTrackUpdate.trackRemoved:
          _remoteVideoTrack = null;
          _remoteVideoState = VideoTrackState.notInitialized;
          AppLogger.info('📹 ❌ REMOTE video track REMOVED');
          break;
          
        case HMSTrackUpdate.trackMuted:
          AppLogger.info('📹 REMOTE video MUTED');
          break;
          
        case HMSTrackUpdate.trackUnMuted:
          AppLogger.info('📹 REMOTE video UNMUTED');
          break;
          
        default:
          AppLogger.info('📹 REMOTE video other update: $update');
          break;
      }
      _videoStateController.add(null);
    }
  }

  /// Handle audio track updates - single source of truth for audio state
  void _handleAudioTrackUpdate(
    HMSTrack track,
    HMSTrackUpdate update,
    HMSPeer peer,
  ) {
    if (!peer.isLocal) return;
    
    switch (update) {
      case HMSTrackUpdate.trackAdded:
        _isMuted = track.isMute;
        AppLogger.info('🎤 Audio track added - muted: $_isMuted');
        onMuteStateChanged?.call();
        break;
        
      case HMSTrackUpdate.trackMuted:
      case HMSTrackUpdate.trackUnMuted:
        // Update state from HMS - single source of truth
        _isMuted = track.isMute;
        AppLogger.info('🎤 Audio ${track.isMute ? 'muted' : 'unmuted'}');
        onMuteStateChanged?.call();
        break;
        
      default:
        break;
    }
  }

  @override
  void onHMSError({required HMSException error}) {
    if (_isDisposed) return;
    
    AppLogger.error('❌ HMS Error: ${error.message ?? 'Unknown'}');
    AppLogger.error('❌ Code: ${error.code}, Action: ${error.action}');
    onError?.call(error.message ?? 'Unknown error');
  }

  @override
  void onReconnected() {
    if (_isDisposed) return;
    AppLogger.info('✅ HMS Reconnected');
  }

  @override
  void onReconnecting() {
    if (_isDisposed) return;
    AppLogger.info('🔄 HMS Reconnecting');
  }

  @override
  void onRemovedFromRoom({
    required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer,
  }) {
    if (_isDisposed) return;
    AppLogger.info('❌ Removed from room: ${hmsPeerRemovedFromPeer.reason}');
    _resetCallState();
  }

  // Required HMS Update Listener methods (no implementation needed)
  @override
  void onAudioDeviceChanged({
    HMSAudioDevice? currentAudioDevice,
    List<HMSAudioDevice>? availableAudioDevice,
  }) {}

  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}

  @override
  void onChangeTrackStateRequest({
    required HMSTrackChangeRequest hmsTrackChangeRequest,
  }) {}

  @override
  void onMessage({required HMSMessage message}) {}

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}

  @override
  void onPeerListUpdate({
    required List<HMSPeer> addedPeers,
    required List<HMSPeer> removedPeers,
  }) {
    if (_isDisposed) return;
    AppLogger.info('👥 Peer list update - Added: ${addedPeers.length}, Removed: ${removedPeers.length}');
  }
}

/// Video track state machine enum
enum VideoTrackState {
  notInitialized,
  initializing,
  ready,
  failed,
}

