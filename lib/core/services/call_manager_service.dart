import 'package:flutter/material.dart';
import 'package:nookly/core/services/hms_call_service.dart';
import 'package:nookly/core/services/call_api_service.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/presentation/pages/call/call_screen.dart';
import 'package:nookly/presentation/pages/call/incoming_call_screen.dart';

/// Call Manager Service - Orchestrates audio/video calls
/// 
/// IMPORTANT: Socket event handling is isolated to prevent conflicts with:
/// - Game features (game_invite, game_move, etc.)
/// - Chat features (message, typing, etc.)
/// - Other existing socket events
/// 
/// Only handles call-specific events:
/// - incoming_call
/// - call_accepted
/// - call_rejected  
/// - call_ended
class CallManagerService {
  static final CallManagerService _instance = CallManagerService._internal();
  factory CallManagerService() => _instance;
  CallManagerService._internal();

  HMSCallService? _callService;
  CallApiService? _callApiService;
  SocketService? _socketService;
  BuildContext? _context;
  String? _currentUserId;
  bool _isInCall = false;
  String? _currentRoomId;
  bool _isInitialized = false;

  /// Initialize the call manager with required dependencies
  /// 
  /// NOTE: Socket listeners are registered here ONLY for call-specific events
  /// They are completely isolated from other socket events (games, chat, etc.)
  void initialize({
    required CallApiService callApiService,
    required SocketService socketService,
    required BuildContext context,
    required HMSCallService callService,
    String? currentUserId,
  }) {
    if (_isInitialized) {
      AppLogger.warning('⚠️ Call manager already initialized, skipping');
      return;
    }

    _callApiService = callApiService;
    _socketService = socketService;
    _context = context;
    _currentUserId = currentUserId;
    _callService = callService;
    
    _callService?.setCallApiService(callApiService);
    _setupSocketListeners();
    
    _isInitialized = true;
    AppLogger.info('✅ Call manager initialized for user: $_currentUserId');
  }

  /// Setup socket listeners for call-specific events ONLY
  /// 
  /// These event names are isolated and won't interfere with:
  /// - game_invite, game_move, game_state_update (game events)
  /// - message, typing (chat events)
  /// - Any other existing socket events
  void _setupSocketListeners() {
    if (_socketService == null) return;

    AppLogger.info('🔵 [CALL] Setting up isolated socket listeners');
    AppLogger.info('🔵 [CALL] Current user: $_currentUserId');

    // CALL-SPECIFIC EVENT: incoming_call
    _socketService!.on('incoming_call', (data) {
      AppLogger.info('🔵 [CALL] Received incoming_call event: $data');
      _handleIncomingCall(data);
    });

    // CALL-SPECIFIC EVENT: call_accepted
    _socketService!.on('call_accepted', (data) {
      AppLogger.info('🔵 [CALL] Received call_accepted event: $data');
      _handleCallAccepted(data);
    });

    // CALL-SPECIFIC EVENT: call_rejected
    _socketService!.on('call_rejected', (data) {
      AppLogger.info('🔵 [CALL] Received call_rejected event: $data');
      _handleCallRejected(data);
    });

    // CALL-SPECIFIC EVENT: call_ended
    _socketService!.on('call_ended', (data) {
      AppLogger.info('🔵 [CALL] Received call_ended event: $data');
      _handleCallEnded(data);
    });

    AppLogger.info('✅ [CALL] Socket listeners registered (isolated from other features)');
  }

  /// Remove ONLY call-specific socket listeners
  /// 
  /// This ensures we don't accidentally remove listeners for:
  /// - Games
  /// - Chat messages
  /// - Other features
  void _removeSocketListeners() {
    if (_socketService == null) return;

    AppLogger.info('🔵 [CALL] Removing isolated socket listeners');

    try {
      _socketService!.off('incoming_call');
      _socketService!.off('call_accepted');
      _socketService!.off('call_rejected');
      _socketService!.off('call_ended');
      AppLogger.info('✅ [CALL] Socket listeners removed successfully');
    } catch (e) {
      AppLogger.warning('⚠️ [CALL] Error removing socket listeners: $e');
    }
  }

  /// Handle incoming call socket event
  void _handleIncomingCall(Map<String, dynamic> data) {
    AppLogger.info('📞 [CALL] Processing incoming call...');
    AppLogger.info('📞 [CALL] Data: $data');
    
    if (_context == null || _currentUserId == null) {
      AppLogger.error('❌ [CALL] Cannot handle - context or user ID null');
      return;
    }

    // Don't show incoming call if already in a call
    if (_isInCall) {
      AppLogger.info('⚠️ [CALL] Ignoring - already in call');
      return;
    }

    final roomId = data['roomId'] as String?;
    final callType = data['callType'] as String?;
    final from = data['from'] as String?;
    final receiverId = data['receiverId'] as String?;
    final callerName = data['callerName'] as String?;
    final callerAvatar = data['callerAvatar'] as String?;

    // Only handle calls for current user
    if (receiverId != _currentUserId) {
      AppLogger.info('⚠️ [CALL] Ignoring - not for current user');
      return;
    }

    if (roomId == null || callType == null || from == null) {
      AppLogger.error('❌ [CALL] Invalid data: $data');
      return;
    }

    AppLogger.info('📞 [CALL] Showing incoming call screen');

    // Show incoming call screen
    Navigator.of(_context!).push(
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(
          roomId: roomId,
          callerName: callerName ?? 'Incoming Call',
          callerAvatar: callerAvatar,
          callType: callType,
          onCallAccepted: (roomId) => acceptCall(roomId),
          onCallRejected: (roomId) => rejectCall(roomId),
        ),
      ),
    );
  }

  /// Handle call accepted socket event
  void _handleCallAccepted(Map<String, dynamic> data) {
    AppLogger.info('✅ [CALL] Call accepted by other party: $data');
    // Update UI if needed
  }

  /// Handle call rejected socket event
  void _handleCallRejected(Map<String, dynamic> data) {
    AppLogger.info('❌ [CALL] Call rejected by other party: $data');
    // Update UI if needed - maybe show a toast
  }

  /// Handle call ended socket event
  void _handleCallEnded(Map<String, dynamic> data) {
    AppLogger.info('🔚 [CALL] Call ended by other party: $data');
    
    // End call locally
    try {
      _callService?.endCall();
    } catch (e) {
      AppLogger.warning('⚠️ [CALL] Error ending call: $e');
    }
    
    _isInCall = false;
    _currentRoomId = null;
  }

  /// Initiate a call with another user
  Future<void> initiateCall({
    required String receiverId,
    required String callType,
    required String receiverName,
    String? receiverAvatar,
  }) async {
    if (_isInCall) {
      AppLogger.warning('⚠️ [CALL] Already in a call');
      return;
    }

    if (!_isInitialized) {
      AppLogger.error('❌ [CALL] Service not initialized');
      throw Exception('Call manager not initialized');
    }

    try {
      AppLogger.info('🚀 [CALL] Initiating $callType call with $receiverName');

      // Show loading indicator
      if (_context != null) {
        showDialog(
          context: _context!,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Initiating call...'),
              ],
            ),
          ),
        );
      }

      // Initiate call via API service
      final response = await _callApiService!.initiateCall(
        receiverId: receiverId,
        callType: callType,
      );

      // Close loading dialog
      if (_context != null && Navigator.canPop(_context!)) {
        Navigator.of(_context!).pop();
      }

      // Validate response structure with null safety
      final callSession = response['callSession'];
      if (callSession == null) {
        AppLogger.error('❌ [CALL] Backend response missing callSession');
        throw Exception('Invalid call response: missing callSession');
      }

      final roomId = callSession['hmsRoomId'] ?? callSession['roomId'];
      if (roomId == null || roomId.toString().isEmpty) {
        AppLogger.error('❌ [CALL] Backend response missing roomId');
        throw Exception('Invalid call response: missing roomId');
      }
      
      final tokens = response['tokens'];
      if (tokens == null) {
        AppLogger.error('❌ [CALL] Backend response missing tokens');
        throw Exception('Invalid call response: missing tokens');
      }

      final callerToken = tokens['caller'];
      if (callerToken == null) {
        AppLogger.error('❌ [CALL] Backend response missing caller token');
        throw Exception('Invalid call response: missing caller token');
      }

      // Handle both string and nested token structures
      final token = callerToken['token'] ?? callerToken;
      if (token == null || token.toString().isEmpty) {
        AppLogger.error('❌ [CALL] Backend response missing or empty token');
        throw Exception('Invalid call response: missing or empty token');
      }

      final receiver = response['receiver'];
      
      AppLogger.info('🔍 Initiate call response structure:');
      AppLogger.info('🔍 - receiver: $receiver');
      AppLogger.info('🔍 - callSession: $callSession');
      
      if (receiver == null) {
        AppLogger.warning('⚠️ [CALL] Backend response missing receiver data');
      }
      
      _isInCall = true;
      _currentRoomId = roomId;

      AppLogger.info('✅ [CALL] Call initiated successfully');

      // Navigate to call screen
      if (_context != null) {
        Navigator.of(_context!).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              roomId: roomId,
              authToken: token,
              isAudioCall: callType == 'audio',
              participantName: receiver?['name'] ?? receiverName,
              participantAvatar: receiver?['profilePicture'] ?? receiverAvatar,
              onCallEnded: () {
                endCall();
              },
            ),
          ),
        );
      }
      
    } catch (e) {
      // Close loading dialog on error
      if (_context != null && Navigator.canPop(_context!)) {
        Navigator.of(_context!).pop();
      }
      
      AppLogger.error('❌ [CALL] Failed to initiate: $e');
      rethrow;
    }
  }

  /// Accept an incoming call
  Future<void> acceptCall(String roomId) async {
    if (_isInCall) {
      AppLogger.warning('⚠️ [CALL] Already in a call');
      return;
    }

    try {
      AppLogger.info('✅ [CALL] Accepting call for room: $roomId');

      final response = await _callApiService!.acceptCall(roomId: roomId);

      // Validate response structure with null safety
      final callSession = response['callSession'];
      if (callSession == null) {
        AppLogger.error('❌ [CALL] Accept call response missing callSession');
        throw Exception('Invalid accept call response: missing callSession');
      }
      
      // Handle both nested and direct token structures
      String? token;
      if (response['token'] != null) {
        if (response['token'] is Map) {
          token = response['token']['token'] as String?;
        } else {
          token = response['token'] as String?;
        }
      }

      if (token == null || token.isEmpty) {
        AppLogger.error('❌ [CALL] Accept call response missing or empty token');
        throw Exception('Invalid accept call response: missing or empty token');
      }
      
      // After null check, token is guaranteed to be non-null (Dart flow analysis)
      final authToken = token;
      
      final caller = response['caller'];
      
      AppLogger.info('🔍 Accept call response structure:');
      AppLogger.info('🔍 - caller: $caller');
      AppLogger.info('🔍 - callSession: $callSession');
      
      if (caller == null) {
        AppLogger.warning('⚠️ [CALL] Backend response missing caller data');
      }
      
      _isInCall = true;
      _currentRoomId = roomId;

      AppLogger.info('✅ [CALL] Call accepted successfully');

      // Navigate to call screen
      if (_context != null) {
        Navigator.of(_context!).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              roomId: roomId,
              authToken: authToken,
              isAudioCall: callSession['callType'] == 'audio',
              participantName: caller?['name'] ?? 'Call Participant',
              participantAvatar: caller?['profilePicture'],
              onCallEnded: () {
                endCall();
              },
            ),
          ),
        );
      }
      
    } catch (e) {
      AppLogger.error('❌ [CALL] Failed to accept: $e');
      rethrow;
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall(String roomId) async {
    try {
      AppLogger.info('❌ [CALL] Rejecting call for room: $roomId');
      await _callApiService!.rejectCall(roomId: roomId);
      AppLogger.info('✅ [CALL] Call rejected successfully');
    } catch (e) {
      AppLogger.error('❌ [CALL] Failed to reject: $e');
      rethrow;
    }
  }

  /// End the current call
  Future<void> endCall() async {
    try {
      AppLogger.info('🔚 [CALL] Ending call via manager');
      await _callService?.endCall();
      _isInCall = false;
      _currentRoomId = null;
      
      AppLogger.info('✅ [CALL] Call ended successfully');
    } catch (e) {
      AppLogger.error('❌ [CALL] Failed to end call: $e');
      _isInCall = false;
      _currentRoomId = null;
      rethrow;
    }
  }

  /// Get call history
  Future<Map<String, dynamic>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    if (_callApiService == null) {
      throw Exception('CallApiService not initialized');
    }

    return await _callApiService!.getCallHistory(
      page: page,
      limit: limit,
    );
  }

  /// Get active call
  Future<Map<String, dynamic>> getActiveCall() async {
    if (_callApiService == null) {
      throw Exception('CallApiService not initialized');
    }

    return await _callApiService!.getActiveCall();
  }

  // Getters
  bool get isInCall => _isInCall;
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  HMSCallService get callService => _callService!;

  /// Dispose and cleanup
  /// 
  /// NOTE: Only removes CALL-specific socket listeners
  /// Does not affect game, chat, or other socket listeners
  void dispose() {
    if (!_isInitialized) return;

    AppLogger.info('🔚 [CALL] Disposing call manager...');
    
    // End call if active
    if (_isInCall) {
      try {
        _callService?.endCall();
      } catch (e) {
        AppLogger.warning('⚠️ [CALL] Error ending call during disposal: $e');
      }
    }
    
    // Remove ONLY call-specific socket listeners
    _removeSocketListeners();
    
    // Dispose call service
    try {
      _callService?.dispose();
    } catch (e) {
      AppLogger.warning('⚠️ [CALL] Error disposing call service: $e');
    }
    
    _isInCall = false;
    _currentRoomId = null;
    _context = null;
    _callApiService = null;
    _socketService = null;
    _currentUserId = null;
    _isInitialized = false;
    
    AppLogger.info('✅ [CALL] Call manager disposed (game/chat sockets preserved)');
  }
}

