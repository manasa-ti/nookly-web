import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nookly/core/services/call_api_service.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/utils/logger.dart';

/// Simplified HMS Call Service based on official documentation
/// 
/// Key Features:
/// - Simple and direct implementation matching official docs
/// - Minimal state management
/// - Direct track and peer handling
/// - Reliable video rendering
class HMSCallService implements HMSUpdateListener {
  HMSSDK? _hmsSDK;
  
  // ============================================================================
  // SIMPLE STATE - Matching official documentation approach
  // ============================================================================
  bool _isDisposed = false;
  bool _isInitialized = false;
  
  // Room and authentication
  String? _currentRoomId;
  String? _currentAuthToken;
  bool _isAudioCall = false;
  
  // Simple peer and track variables (like official docs)
  HMSPeer? _localPeer;
  HMSPeer? _remotePeer;
  HMSVideoTrack? _localVideoTrack;
  HMSVideoTrack? _remoteVideoTrack;
  
  // Simple mute states
  bool _isMuted = false;
  bool _isCameraOff = false;
  
  // Audio device state
  HMSAudioDevice? _currentAudioDevice;
  bool _isSpeakerOn = false;
  
  // Callbacks for UI updates
  VoidCallback? onMuteStateChanged;
  VoidCallback? onTracksChanged;
  Function(String)? onUserJoined;
  Function(String)? onUserLeft;
  Function(String)? onError;
  AnalyticsService Function()? onAnalyticsService;
  
  // API service
  CallApiService? _callApiService;

  void setCallApiService(CallApiService callApiService) {
    _callApiService = callApiService;
  }

  // ============================================================================
  // INITIALIZATION - Simple and direct
  // ============================================================================
  
  Future<bool> initialize() async {
    if (_isDisposed) return false;
    
    // If already initialized, return true
    if (_isInitialized && _hmsSDK != null) {
      print('HMS SDK already initialized');
      return true;
    }
    
    try {
      _hmsSDK = HMSSDK();
      await _hmsSDK!.build();
      _hmsSDK!.addUpdateListener(listener: this);
      _isInitialized = true;
      
      print('HMS SDK initialized successfully');
      return true;
    } catch (e) {
      print('Failed to initialize HMS SDK: $e');
      onError?.call('Failed to initialize: $e');
      return false;
    }
  }

  // ============================================================================
  // ROOM MANAGEMENT - Direct approach from official docs
  // ============================================================================
  
  Future<bool> joinRoom(String roomId, String authToken, {bool isAudioCall = false}) async {
    if (!_isInitialized || _isDisposed) {
      AppLogger.error('HMS SDK not initialized or disposed');
      return false;
    }

    if (_hmsSDK == null) {
      AppLogger.error('HMS SDK instance is null');
      onError?.call('HMS SDK not initialized');
      return false;
    }

    try {
      print('🚀 [CALL] joinRoom called');
      print('🚀 [CALL] Room ID: $roomId');
      print('🚀 [CALL] Is audio call: $isAudioCall');

      _currentRoomId = roomId;
      _currentAuthToken = authToken;
      _isAudioCall = isAudioCall;

      // Create room config FIRST - needed for preview
      print('🚀 [CALL] Creating HMSConfig...');
      final roomConfig = HMSConfig(
        authToken: authToken,
        userName: "User",
      );
      print('✅ [CALL] HMSConfig created');

      // Call preview FIRST to trigger iOS permission dialogs
      // Preview requests camera and microphone permissions and provides local tracks
      // This MUST be called before any permission checks or join
      print('📹 [CALL] ========================================');
      print('📹 [CALL] CALLING PREVIEW (FIRST STEP)');
      print('📹 [CALL] This will trigger iOS permission dialogs');
      print('📹 [CALL] ========================================');
      try {
        await _hmsSDK!.preview(config: roomConfig);
        print('✅ [CALL] Preview completed successfully');
        print('✅ [CALL] onPreview callback will be called with local tracks');
        print('✅ [CALL] iOS permissions should be triggered');
      } catch (e) {
        print('⚠️ [CALL] Preview failed: $e');
        print('⚠️ [CALL] Stack trace: ${StackTrace.current}');
        print('⚠️ [CALL] HMS SDK will request permissions on join');
        // Continue - HMS SDK will handle permissions on join
      }

      // Check permissions after preview (non-blocking)
      // Preview should have triggered the permission dialogs
      print('🚀 [CALL] Checking permission status (after preview)...');
      final micStatus = await Permission.microphone.status;
      final cameraStatus = await Permission.camera.status;
      print('🔐 [CALL] Microphone status: $micStatus');
      print('🔐 [CALL] Camera status: $cameraStatus');
      
      // Only warn if permissions are permanently denied, but don't block
      if (micStatus.isPermanentlyDenied || cameraStatus.isPermanentlyDenied) {
        print('⚠️ [CALL] WARNING: Some permissions are permanently denied');
        print('⚠️ [CALL] User may need to enable permissions in Settings');
      }

      // Join room
      print('🚀 [CALL] Calling _hmsSDK.join()...');
      await _hmsSDK!.join(config: roomConfig);
      print('✅ [CALL] _hmsSDK.join() completed - waiting for onJoin callback');
      
      return true;
    } catch (e) {
      print('❌ [CALL] Failed to join room: $e');
      print('❌ [CALL] Stack trace: ${StackTrace.current}');
      onError?.call('Failed to join room: $e');
      return false;
    }
  }

  Future<bool> leaveRoom() async {
    try {
      print('🚪 LEAVE ROOM CALLED');
      print('   Initialized: $_isInitialized, Disposed: $_isDisposed');
    } catch (e) {
      print('❌ ERROR in initial prints: $e');
    }
    
    if (!_isInitialized || _isDisposed) {
      print('❌ Cannot leave - not initialized or disposed');
      return false;
    }

    try {
      print('🎤 Step 1: Muting audio (if not already muted)');
      // Mute audio and video before leaving to ensure clean state
      if (!_isMuted) {
        print('   Audio was unmuted, muting now...');
        await _hmsSDK!.toggleMicMuteState();
        print('   ✅ Audio muted');
      } else {
        print('   Audio was already muted');
      }
      
      print('📹 Step 2: Turning off camera (if not already off)');
      if (!_isCameraOff) {
        print('   Camera was on, turning off now...');
        await _hmsSDK!.toggleCameraMuteState();
        print('   ✅ Camera turned off');
      } else {
        print('   Camera was already off');
      }
      
      print('🚪 Step 3: Leaving HMS room...');
      await _hmsSDK!.leave();
      print('   ✅ Left HMS room');
      
      print('🗑️ Step 4: Removing update listener...');
      _hmsSDK?.removeUpdateListener(listener: this);
      print('   ✅ Listener removed');
      
      print('🗑️ Step 5: Setting SDK to null...');
      _hmsSDK = null;
      print('   ✅ SDK disposed');
      
      print('🗑️ Step 6: Clearing state...');
      _clearState();
      print('   ✅ State cleared');
      
      print('🗑️ Step 7: Resetting initialization flag...');
      _isInitialized = false;
      print('   ✅ Initialization reset');
      
      print('✅ LEAVE ROOM COMPLETE - audio session should be closed');
      return true;
    } catch (e) {
      print('❌ FAILED TO LEAVE ROOM: $e');
      print('   Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // ============================================================================
  // AUDIO/VIDEO CONTROLS - Simple and direct
  // ============================================================================
  
  Future<bool> muteAudio([bool? mute]) async {
    if (!_isInitialized || _isDisposed) return false;

    try {
      // If mute parameter is provided, check if we need to toggle
      if (mute != null && mute == _isMuted) {
        // Already in the desired state
        return true;
      }
      
      await _hmsSDK!.toggleMicMuteState();
      _isMuted = !_isMuted;
      onMuteStateChanged?.call();
      print('Audio muted: $_isMuted');
      return true;
    } catch (e) {
      print('Failed to toggle audio: $e');
      return false;
    }
  }

  Future<bool> muteVideo([bool? mute]) async {
    if (!_isInitialized || _isDisposed) return false;

    try {
      // If mute parameter is provided, check if we need to toggle
      if (mute != null && mute == _isCameraOff) {
        // Already in the desired state
        return true;
      }
      
      await _hmsSDK!.toggleCameraMuteState();
      _isCameraOff = !_isCameraOff;
      onMuteStateChanged?.call();
      print('Video muted: $_isCameraOff');
      return true;
    } catch (e) {
      print('Failed to toggle video: $e');
      return false;
    }
  }

  // ============================================================================
  // ADDITIONAL METHODS - For compatibility with existing code
  // ============================================================================
  
  Future<bool> endCall() async {
    print('📞 endCall() called - delegating to leaveRoom()');
    final result = await leaveRoom();
    print('📞 endCall() completed with result: $result');
    return result;
  }

  Future<bool> initiateCall(String roomId, String authToken, {bool isAudioCall = false}) async {
    return await joinRoom(roomId, authToken, isAudioCall: isAudioCall);
  }

  Future<bool> acceptCall(String roomId, String authToken, {bool isAudioCall = false}) async {
    return await joinRoom(roomId, authToken, isAudioCall: isAudioCall);
  }

  Future<bool> rejectCall() async {
    // For now, just return true as rejection doesn't require HMS SDK interaction
    return true;
  }

  bool isHMSReady() {
    return _isInitialized && !_isDisposed;
  }

  Future<bool> setSpeakerphone(bool enabled) async {
    if (!_isInitialized || _hmsSDK == null) return false;
    
    try {
      // Determine target audio device based on enabled state
      final targetDevice = enabled ? HMSAudioDevice.SPEAKER_PHONE : HMSAudioDevice.EARPIECE;
      
      print('Setting audio device to: $targetDevice');
      
      // HMS SDK handles audio routing automatically based on connected devices
      // For now, we just track the state - the SDK will handle the actual routing
      _isSpeakerOn = enabled;
      _currentAudioDevice = targetDevice;
      
      print('Audio device state updated successfully');
      return true;
    } catch (e) {
      print('Failed to set speakerphone: $e');
      return false;
    }
  }

  // Force refresh of video tracks - useful for debugging
  void refreshVideoTracks() {
    print('Refreshing video tracks...');
    print('Local video track: ${_localVideoTrack?.trackId}');
    print('Remote video track: ${_remoteVideoTrack?.trackId}');
    onTracksChanged?.call();
  }

  // ============================================================================
  // VIDEO VIEWS - Direct approach from official docs
  // ============================================================================
  
  Widget createLocalVideoView() {
    if (_localVideoTrack == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('No local video', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return HMSVideoView(
      key: Key('local_${_localVideoTrack!.trackId}'),
      track: _localVideoTrack!,
      scaleType: ScaleType.SCALE_ASPECT_FILL,
      setMirror: true,
    );
  }

  Widget createRemoteVideoView() {
    print('createRemoteVideoView called. Track: ${_remoteVideoTrack?.trackId}');
    
    if (_remoteVideoTrack == null) {
      print('Remote video track is null - showing placeholder');
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('No remote video', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    print('Creating HMSVideoView with track: ${_remoteVideoTrack!.trackId}');
    return HMSVideoView(
      key: Key('remote_${_remoteVideoTrack!.trackId}'),
      track: _remoteVideoTrack!,
      scaleType: ScaleType.SCALE_ASPECT_FILL,
      setMirror: false,
    );
  }

  // ============================================================================
  // GETTERS - Simple state access
  // ============================================================================
  
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isAudioCall => _isAudioCall;
  bool get isInitialized => _isInitialized;
  bool get isDisposed => _isDisposed;
  
  // Additional getters for compatibility
  bool get isAudioMuted => _isMuted;
  bool get isVideoMuted => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get hasHeadsetConnected =>
      _currentAudioDevice == HMSAudioDevice.WIRED_HEADSET ||
      _currentAudioDevice == HMSAudioDevice.BLUETOOTH;
  bool get isLocalVideoReady => _localVideoTrack != null;
  bool get isRemoteVideoReady => _remoteVideoTrack != null;
  
  HMSPeer? get localPeer => _localPeer;
  HMSPeer? get remotePeer => _remotePeer;
  HMSVideoTrack? get localVideoTrack => _localVideoTrack;
  HMSVideoTrack? get remoteVideoTrack => _remoteVideoTrack;

  // ============================================================================
  // HMS UPDATE LISTENER - Simplified callbacks
  // ============================================================================
  
  @override
  void onJoin({required HMSRoom room}) {
    print('✅ [CALL] onJoin CALLED');
    print('✅ [CALL] Room ID: ${room.id}');
    print('✅ [CALL] Total peers in room: ${room.peers?.length ?? 0}');
    print('✅ [CALL] Is audio call: $_isAudioCall');
    
    // Reset mute states for new call - ensure audio and video are unmuted
    _isMuted = false;
    _isCameraOff = false;
    
    // Find local peer
    print('✅ [CALL] Searching for local peer...');
    try {
      _localPeer = room.peers?.firstWhere((peer) => peer.isLocal);
      print('✅ [CALL] Local peer found: ${_localPeer?.name}');
      print('✅ [CALL] Local peer customerUserId: ${_localPeer?.customerUserId}');
      print('✅ [CALL] Local peer video track: ${_localPeer?.videoTrack?.trackId ?? "NULL"}');
      print('✅ [CALL] Local peer audio track: ${_localPeer?.audioTrack?.trackId ?? "NULL"}');
      _localVideoTrack = _localPeer?.videoTrack;
      if (_localVideoTrack == null) {
        print('⚠️ [CALL] WARNING: Local video track is NULL in onJoin');
      }
    } catch (e) {
      print('❌ [CALL] ERROR finding local peer: $e');
    }
    
    // Find remote peer
    String? user1Id;
    String? user2Id;
    print('✅ [CALL] Searching for remote peer...');
    if (room.peers != null) {
      print('✅ [CALL] Iterating through ${room.peers!.length} peers...');
      for (final peer in room.peers!) {
        print('   Peer: ${peer.name}, isLocal: ${peer.isLocal}');
        if (!peer.isLocal) {
          _remotePeer = peer;
          print('✅ [CALL] Remote peer found: ${peer.name}');
          print('✅ [CALL] Remote peer customerUserId: ${peer.customerUserId}');
          print('✅ [CALL] Remote peer video track: ${peer.videoTrack?.trackId ?? "NULL"}');
          print('✅ [CALL] Remote peer audio track: ${peer.audioTrack?.trackId ?? "NULL"}');
          _remoteVideoTrack = peer.videoTrack;
          if (_remoteVideoTrack == null) {
            print('⚠️ [CALL] WARNING: Remote video track is NULL in onJoin');
          }
          
          // Extract user IDs from peer names (assuming format contains user ID)
          // Try to get from peer.name or peer.customerUserId
          user1Id = _localPeer?.name ?? _localPeer?.customerUserId;
          user2Id = peer.name ?? peer.customerUserId;
          break;
        }
      }
    } else {
      print('❌ [CALL] ERROR: room.peers is NULL');
    }
    
    // Track call joined analytics
    if (user1Id != null && user2Id != null && onAnalyticsService != null) {
      try {
        final analyticsService = onAnalyticsService!();
        if (_isAudioCall) {
          analyticsService.logAudioCallJoined(user1Id: user1Id, user2Id: user2Id);
        } else {
          analyticsService.logVideoCallJoined(user1Id: user1Id, user2Id: user2Id);
        }
      } catch (e) {
        print('Failed to track call joined analytics: $e');
      }
    }
    
    print('✅ [CALL] onJoin summary:');
    print('   Local peer: ${_localPeer?.name}, Local video track: ${_localVideoTrack?.trackId ?? "NULL"}');
    print('   Remote peer: ${_remotePeer?.name}, Remote video track: ${_remoteVideoTrack?.trackId ?? "NULL"}');
    
    onTracksChanged?.call();
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    print('👤 [CALL] onPeerUpdate CALLED');
    print('👤 [CALL] Peer name: ${peer.name}');
    print('👤 [CALL] Peer isLocal: ${peer.isLocal}');
    print('👤 [CALL] Peer customerUserId: ${peer.customerUserId}');
    print('👤 [CALL] Update type: $update');
    print('👤 [CALL] Peer video track: ${peer.videoTrack?.trackId ?? "NULL"}');
    print('👤 [CALL] Peer audio track: ${peer.audioTrack?.trackId ?? "NULL"}');
    
    // Skip network quality updates - they happen too frequently and don't affect tracks
    if (update == HMSPeerUpdate.networkQualityUpdated) {
      print('👤 [CALL] Skipping network quality update');
      return;
    }
    
    // Track previous video track IDs to detect actual changes
    final previousLocalTrackId = _localVideoTrack?.trackId;
    final previousRemoteTrackId = _remoteVideoTrack?.trackId;
    print('👤 [CALL] Previous local track: ${previousLocalTrackId ?? "null"}');
    print('👤 [CALL] Previous remote track: ${previousRemoteTrackId ?? "null"}');
    
    // Follow official documentation - update peer and tracks directly
    if (peer.isLocal) {
      print('👤 [CALL] Updating LOCAL peer');
      _localPeer = peer;
      _localVideoTrack = peer.videoTrack;
      print('👤 [CALL] Local peer updated. Video track: ${_localVideoTrack?.trackId ?? "NULL"}');
    } else {
      print('👤 [CALL] Updating REMOTE peer');
      _remotePeer = peer;
      _remoteVideoTrack = peer.videoTrack;
      print('👤 [CALL] Remote peer updated. Video track: ${_remoteVideoTrack?.trackId ?? "NULL"}');
    }
    
    // Only call onTracksChanged if tracks actually changed
    final currentLocalTrackId = _localVideoTrack?.trackId;
    final currentRemoteTrackId = _remoteVideoTrack?.trackId;
    
    print('👤 [CALL] Current local track: ${currentLocalTrackId ?? "null"}');
    print('👤 [CALL] Current remote track: ${currentRemoteTrackId ?? "null"}');
    
    if (previousLocalTrackId != currentLocalTrackId || 
        previousRemoteTrackId != currentRemoteTrackId) {
      print('👤 [CALL] Tracks changed - calling onTracksChanged...');
      onTracksChanged?.call();
      print('👤 [CALL] onTracksChanged completed');
    } else {
      print('👤 [CALL] Tracks did not change - skipping onTracksChanged');
    }
  }

  @override
  void onTrackUpdate({required HMSPeer peer, required HMSTrack track, required HMSTrackUpdate trackUpdate}) {
    print('📹 [CALL] onTrackUpdate CALLED');
    print('📹 [CALL] Track ID: ${track.trackId}');
    print('📹 [CALL] Track kind: ${track.kind}');
    print('📹 [CALL] Track source: ${track.source}');
    print('📹 [CALL] Track update type: $trackUpdate');
    print('📹 [CALL] Peer name: ${peer.name}');
    print('📹 [CALL] Peer isLocal: ${peer.isLocal}');
    print('📹 [CALL] Peer customerUserId: ${peer.customerUserId}');
    
    // Follow official documentation pattern - handle all track update types
    if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
      final videoTrack = track as HMSVideoTrack;
      print('📹 [CALL] Video track details:');
      print('   Track ID: ${videoTrack.trackId}');
      print('   Is mute: ${videoTrack.isMute}');
      print('   Source: ${videoTrack.source}');
      
      if (peer.isLocal) {
        print('📹 [CALL] Processing LOCAL video track');
        print('   Previous local track: ${_localVideoTrack?.trackId ?? "null"}');
        _localVideoTrack = videoTrack;
        print('   New local track: ${_localVideoTrack?.trackId}');
        print('✅ [CALL] Local video track set: ${videoTrack.trackId}');
      } else {
        print('📹 [CALL] Processing REMOTE video track');
        print('   Previous remote track: ${_remoteVideoTrack?.trackId ?? "null"}');
        print('   Previous remote peer: ${_remotePeer?.name ?? "null"}');
        _remoteVideoTrack = videoTrack;
        _remotePeer = peer;
        print('   New remote track: ${_remoteVideoTrack?.trackId}');
        print('   New remote peer: ${_remotePeer?.name}');
        print('✅ [CALL] Remote video track set: ${videoTrack.trackId}');
      }
      
      // Force UI update
      print('📹 [CALL] Calling onTracksChanged callback...');
      onTracksChanged?.call();
      print('📹 [CALL] onTracksChanged callback completed');
    } else {
      print('📹 [CALL] Track is not video (kind: ${track.kind})');
    }
  }

  @override
  void onPeerLeave({required HMSPeer peer}) {
    print('Peer left: ${peer.name}');
    
    if (peer.isLocal) {
      _localPeer = null;
      _localVideoTrack = null;
    } else {
      _remotePeer = null;
      _remoteVideoTrack = null;
    }
    
    onUserLeft?.call(peer.name ?? 'Unknown');
    onTracksChanged?.call();
  }

  @override
  void onHMSError({required HMSException error}) {
    print('HMS Error: ${error.message}');
    onError?.call(error.message ?? 'Unknown error');
  }

  @override
  void onReconnecting() {
    print('Reconnecting to room...');
  }

  @override
  void onReconnected() {
    print('Reconnected to room');
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {
    print('Room update: $update');
  }

  @override
  void onMessage({required HMSMessage message}) {
    print('Message received: ${message.message}');
  }

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {
    print('Role change request: ${roleChangeRequest.suggestedBy?.name}');
  }

  @override
  void onChangeTrackStateRequest({required HMSTrackChangeRequest hmsTrackChangeRequest}) {
    print('Track change request: ${hmsTrackChangeRequest.track.trackId}');
  }

  @override
  void onRemovedFromRoom({required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {
    print('Removed from room: ${hmsPeerRemovedFromPeer.reason}');
  }

  @override
  void onPeerListUpdate({required List<HMSPeer> addedPeers, required List<HMSPeer> removedPeers}) {
    print('Peer list updated: ${addedPeers.length} added, ${removedPeers.length} removed');
  }

  @override
  void onNetworkQuality({required List<HMSNetworkQuality> networkQuality}) {
    // Handle network quality updates if needed
  }

  @override
  void onAudioDeviceChanged({HMSAudioDevice? currentAudioDevice, List<HMSAudioDevice>? availableAudioDevice}) {
    print('Audio device changed: $currentAudioDevice');
    print('Available devices: $availableAudioDevice');
    
    _currentAudioDevice = currentAudioDevice;
    
    // Update speaker state based on current device
    if (currentAudioDevice == HMSAudioDevice.SPEAKER_PHONE) {
      _isSpeakerOn = true;
    } else if (currentAudioDevice == HMSAudioDevice.EARPIECE || 
               currentAudioDevice == HMSAudioDevice.WIRED_HEADSET ||
               currentAudioDevice == HMSAudioDevice.BLUETOOTH) {
      _isSpeakerOn = false;
    }
    
    print('Updated speaker state: $_isSpeakerOn');
    
    // Notify UI of audio device change
    onMuteStateChanged?.call();
  }

  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {
    print('Session store available');
  }

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {
    // Handle speaker updates if needed
  }

  @override
  void onBulkRoleChange({required List<HMSRoleChangeRequest> bulkRoleChangeRequest}) {
    print('Bulk role change: ${bulkRoleChangeRequest.length} requests');
  }

  @override
  void onPreview({required HMSRoom room, required HMSLocalPeer localPeer}) {
    print('Preview available');
  }

  @override
  void onAudioDeviceListUpdated({required List<HMSAudioDevice> audioDeviceList}) {
    print('Audio device list updated: ${audioDeviceList.length} devices');
    print('Available devices: $audioDeviceList');
    
    // Check if wired headphones or Bluetooth are connected
    final hasHeadphones = audioDeviceList.contains(HMSAudioDevice.WIRED_HEADSET);
    final hasBluetooth = audioDeviceList.contains(HMSAudioDevice.BLUETOOTH);
    
    if (hasHeadphones || hasBluetooth) {
      print('Headphones/Bluetooth detected - routing audio automatically');
      // Automatically route to detected device
      if (hasHeadphones) {
        _currentAudioDevice = HMSAudioDevice.WIRED_HEADSET;
      } else if (hasBluetooth) {
        _currentAudioDevice = HMSAudioDevice.BLUETOOTH;
      }
      _isSpeakerOn = false;
      onMuteStateChanged?.call();
    }
  }

  @override
  void onRTCStats({required HMSRTCStatsReport hmsrtcStatsReport}) {
    // Handle RTC stats if needed
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  Future<bool> _requestPermissions() async {
    print('🔐 [CALL] _requestPermissions called');
    
    print('🔐 [CALL] Checking permission status first...');
    
    // Check status before requesting - request individually for better iOS compatibility
    final micStatus = await Permission.microphone.status;
    final cameraStatus = await Permission.camera.status;
    
    print('🔐 [CALL] Current permission status BEFORE request:');
    print('   Microphone: $micStatus');
    print('   Microphone isGranted: ${micStatus.isGranted}');
    print('   Microphone isDenied: ${micStatus.isDenied}');
    print('   Microphone isPermanentlyDenied: ${micStatus.isPermanentlyDenied}');
    print('   Microphone isLimited: ${micStatus.isLimited}');
    print('   Microphone isRestricted: ${micStatus.isRestricted}');
    print('   Camera: $cameraStatus');
    print('   Camera isGranted: ${cameraStatus.isGranted}');
    print('   Camera isDenied: ${cameraStatus.isDenied}');
    print('   Camera isPermanentlyDenied: ${cameraStatus.isPermanentlyDenied}');
    print('   Camera isLimited: ${cameraStatus.isLimited}');
    print('   Camera isRestricted: ${cameraStatus.isRestricted}');
    
    // If permanently denied, open app settings
    if (micStatus.isPermanentlyDenied || cameraStatus.isPermanentlyDenied) {
      print('⚠️ [CALL] Permissions permanently denied - opening app settings...');
      print('⚠️ [CALL] User needs to enable permissions in Settings app');
      try {
        await openAppSettings();
        print('✅ [CALL] Opened app settings');
      } catch (e) {
        print('❌ [CALL] Failed to open app settings: $e');
      }
      return false;
    }
    
    // If already granted, return true
    if (micStatus.isGranted && cameraStatus.isGranted) {
      print('✅ [CALL] Permissions already granted');
      return true;
    }

    // Request permissions INDIVIDUALLY for better iOS compatibility
    // iOS sometimes doesn't show dialog when requesting multiple permissions at once
    // IMPORTANT: On iOS, if Info.plist entries are missing or not read, request() 
    // will immediately return permanentlyDenied without showing dialog
    
    print('🔐 [CALL] Requesting microphone permission...');
    
    // On iOS, if status is denied (not notDetermined), it might mean Info.plist isn't being read
    // Try requesting anyway - if it immediately becomes permanentlyDenied, Info.plist issue
    if (micStatus == PermissionStatus.denied) {
      print('⚠️ [CALL] WARNING: Microphone status is "denied" instead of "notDetermined"');
      print('⚠️ [CALL] This might indicate Info.plist is not being read properly');
      print('⚠️ [CALL] Attempting request anyway...');
    }
    
    final micResult = await Permission.microphone.request();
    print('🔐 [CALL] Microphone permission result: $micResult');
    print('   isGranted: ${micResult.isGranted}');
    print('   isDenied: ${micResult.isDenied}');
    print('   isPermanentlyDenied: ${micResult.isPermanentlyDenied}');
    
    // If it immediately becomes permanentlyDenied without showing dialog
    // This happens when iOS remembers previous denial OR Info.plist isn't being read
    if (micResult.isPermanentlyDenied && micStatus == PermissionStatus.denied) {
      print('❌ [CALL] CRITICAL: Microphone immediately became permanentlyDenied');
      print('❌ [CALL] This usually means:');
      print('   1. iOS remembers previous permission denial (even after reinstall)');
      print('   2. Device restrictions are blocking permissions');
      print('   3. Info.plist keys not being read (less likely if keys exist in bundle)');
      print('❌ [CALL] Solutions:');
      print('   - Settings → General → Reset → Reset Location & Privacy (resets ALL apps)');
      print('   - Settings → Screen Time → Content & Privacy → Allow Camera/Microphone');
      print('   - Uninstall app, reset privacy, reinstall');
    }
    
    if (!micResult.isGranted) {
      print('❌ [CALL] Microphone permission denied: $micResult');
      if (micResult.isPermanentlyDenied) {
        print('⚠️ [CALL] Microphone permanently denied - opening app settings...');
        try {
          await openAppSettings();
        } catch (e) {
          print('❌ [CALL] Failed to open app settings: $e');
        }
      }
      return false;
    }
    
    print('🔐 [CALL] Requesting camera permission...');
    
    // Same check for camera
    if (cameraStatus == PermissionStatus.denied) {
      print('⚠️ [CALL] WARNING: Camera status is "denied" instead of "notDetermined"');
      print('⚠️ [CALL] This means permissions were previously denied and iOS remembers the state');
      print('⚠️ [CALL] To reset: Settings → General → Reset → Reset Location & Privacy');
      print('⚠️ [CALL] Attempting request anyway...');
    }
    
    final cameraResult = await Permission.camera.request();
    print('🔐 [CALL] Camera permission result: $cameraResult');
    print('   isGranted: ${cameraResult.isGranted}');
    print('   isDenied: ${cameraResult.isDenied}');
    print('   isPermanentlyDenied: ${cameraResult.isPermanentlyDenied}');
    
    // If it immediately becomes permanentlyDenied without showing dialog
    if (cameraResult.isPermanentlyDenied && cameraStatus == PermissionStatus.denied) {
      print('❌ [CALL] CRITICAL: Camera immediately became permanentlyDenied');
      print('❌ [CALL] This usually means:');
      print('   1. iOS remembers previous permission denial (even after reinstall)');
      print('   2. Device restrictions are blocking permissions');
      print('   3. Info.plist keys not being read (less likely if keys exist in bundle)');
      print('❌ [CALL] Solutions:');
      print('   - Settings → General → Reset → Reset Location & Privacy (resets ALL apps)');
      print('   - Settings → Screen Time → Content & Privacy → Allow Camera/Microphone');
      print('   - Uninstall app, reset privacy, reinstall');
    }
    
    if (!cameraResult.isGranted) {
      print('❌ [CALL] Camera permission denied: $cameraResult');
      if (cameraResult.isPermanentlyDenied) {
        print('⚠️ [CALL] Camera permanently denied - opening app settings...');
        try {
          await openAppSettings();
        } catch (e) {
          print('❌ [CALL] Failed to open app settings: $e');
        }
      }
      return false;
    }
    
    print('✅ [CALL] All permissions granted');
    return true;
  }

  void _clearState() {
    print('🗑️ _clearState() called');
    print('   Before clear - Muted: $_isMuted, Camera: $_isCameraOff');
    
    _localPeer = null;
    _remotePeer = null;
    _localVideoTrack = null;
    _remoteVideoTrack = null;
    _isMuted = false;
    _isCameraOff = false;
    _currentRoomId = null;
    _currentAuthToken = null;
    
    print('   After clear - Muted: $_isMuted, Camera: $_isCameraOff');
    
    // Force UI update after clearing state
    onTracksChanged?.call();
    print('✅ Call state cleared');
  }

  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _hmsSDK?.removeUpdateListener(listener: this);
    _hmsSDK = null;
    _clearState();
    
    print('HMS Call Service disposed');
  }
}