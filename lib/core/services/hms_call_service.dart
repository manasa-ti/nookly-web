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
      // Request permissions
      if (!await _requestPermissions()) {
        onError?.call('Permissions denied');
        return false;
      }

      _currentRoomId = roomId;
      _currentAuthToken = authToken;
      _isAudioCall = isAudioCall;

      // Create room config
      final roomConfig = HMSConfig(
        authToken: authToken,
        userName: "User",
      );

      // Join room
      await _hmsSDK!.join(config: roomConfig);
      
      print('Joining room: $roomId');
      return true;
    } catch (e) {
      print('Failed to join room: $e');
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
    print('Joined room successfully');
    
    // Reset mute states for new call - ensure audio and video are unmuted
    _isMuted = false;
    _isCameraOff = false;
    
    // Find local peer
    _localPeer = room.peers?.firstWhere((peer) => peer.isLocal);
    _localVideoTrack = _localPeer?.videoTrack;
    print('Local peer: ${_localPeer?.name}, Local video track: ${_localVideoTrack?.trackId}');
    
    // Find remote peer
    String? user1Id;
    String? user2Id;
    if (room.peers != null) {
      for (final peer in room.peers!) {
        if (!peer.isLocal) {
          _remotePeer = peer;
          _remoteVideoTrack = peer.videoTrack;
          print('Remote peer: ${peer.name}, Remote video track: ${peer.videoTrack?.trackId}');
          
          // Extract user IDs from peer names (assuming format contains user ID)
          // Try to get from peer.name or peer.customerUserId
          user1Id = _localPeer?.name ?? _localPeer?.customerUserId;
          user2Id = peer.name ?? peer.customerUserId;
          break;
        }
      }
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
    
    onTracksChanged?.call();
    print('Local peer: ${_localPeer?.name}, Remote peer: ${_remotePeer?.name}');
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    print('Peer update: ${peer.name} - $update');
    
    // Skip network quality updates - they happen too frequently and don't affect tracks
    if (update == HMSPeerUpdate.networkQualityUpdated) {
      return;
    }
    
    // Track previous video track IDs to detect actual changes
    final previousLocalTrackId = _localVideoTrack?.trackId;
    final previousRemoteTrackId = _remoteVideoTrack?.trackId;
    
    // Follow official documentation - update peer and tracks directly
    if (peer.isLocal) {
      _localPeer = peer;
      _localVideoTrack = peer.videoTrack;
      print('Local peer updated. Video track: ${_localVideoTrack?.trackId}');
    } else {
      _remotePeer = peer;
      _remoteVideoTrack = peer.videoTrack;
      print('Remote peer updated. Video track: ${_remoteVideoTrack?.trackId}');
    }
    
    // Only call onTracksChanged if tracks actually changed
    final currentLocalTrackId = _localVideoTrack?.trackId;
    final currentRemoteTrackId = _remoteVideoTrack?.trackId;
    
    if (previousLocalTrackId != currentLocalTrackId || 
        previousRemoteTrackId != currentRemoteTrackId) {
      print('Tracks changed - calling onTracksChanged...');
      onTracksChanged?.call();
      print('onTracksChanged completed');
    }
  }

  @override
  void onTrackUpdate({required HMSPeer peer, required HMSTrack track, required HMSTrackUpdate trackUpdate}) {
    print('Track update: ${track.trackId} - $trackUpdate from ${peer.name}');
    
    // Follow official documentation pattern - handle all track update types
    if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
      final videoTrack = track as HMSVideoTrack;
      
      if (peer.isLocal) {
        _localVideoTrack = videoTrack;
        print('Local video track set: ${videoTrack.trackId}');
      } else {
        _remoteVideoTrack = videoTrack;
        print('Remote video track set: ${videoTrack.trackId}');
        print('Remote peer updated: ${_remotePeer?.name}');
        
        // Also update remote peer reference to ensure it's current
        _remotePeer = peer;
      }
      
      // Force UI update
      print('Calling onTracksChanged callback...');
      onTracksChanged?.call();
      print('onTracksChanged callback completed');
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
    final permissions = [
      Permission.microphone,
      Permission.camera,
    ];

    final statuses = await permissions.request();
    
    for (final status in statuses.values) {
      if (!status.isGranted) {
        print('Permission denied: ${status}');
        return false;
      }
    }
    
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