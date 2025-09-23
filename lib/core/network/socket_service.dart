import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/config/environment_manager.dart';
import 'package:nookly/core/utils/e2ee_utils.dart';
import 'package:nookly/core/services/key_management_service.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/core/di/injection_container.dart';

class SocketService {
  factory SocketService({KeyManagementService? keyManagementService}) => 
    SocketService._internal(keyManagementService: keyManagementService);
  SocketService._internal({KeyManagementService? keyManagementService}) 
    : _keyManagementService = keyManagementService;

  IO.Socket? _socket;
  String? _userId;
  KeyManagementService? _keyManagementService;
  
  // Track listeners to avoid removing all listeners for an event
  final Map<String, List<Function(dynamic)>> _listeners = {};

  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;

    static String get socketUrl {
    return EnvironmentManager.socketUrl;
  }

  void connect({required String serverUrl, required String token, required String userId}) {
    AppLogger.info('🔵 SocketService: Starting connection process');
    AppLogger.info('🔵 Server URL: $serverUrl');
    AppLogger.info('🔵 User ID: $userId');
    AppLogger.info('🔵 Token available: ${token.isNotEmpty}');
    AppLogger.info('🔵 Key management service: ${_keyManagementService != null}');
    
    if (_socket != null && _socket!.connected) {
      AppLogger.info('Socket already connected, skipping connection');
      return;
    }

    AppLogger.info('Initializing socket connection to $serverUrl');
    _userId = userId;
    
    try {
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token, 'userId': userId})
          .disableAutoConnect()
          .build(),
      );
      AppLogger.info('✅ Socket instance created successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to create socket instance: $e');
      return;
    }

    _setupSocketListeners();
    AppLogger.info('Attempting to connect socket...');
    _socket!.connect();
  }

  void joinPrivateChat(String otherUserId) {
    AppLogger.info('🔵 Attempting to join private chat room with user: $otherUserId');
    AppLogger.info('🔵 Current user ID: $_userId');
    AppLogger.info('🔵 Socket connected: ${_socket?.connected}');
    AppLogger.info('🔵 Socket ID: ${_socket?.id}');
    
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot join private chat: Socket not connected');
      return;
    }
    
    if (_userId == null) {
      AppLogger.error('Cannot join private chat: Current user ID is null');
      return;
    }
    
    AppLogger.info('Joining private chat room with other user: $otherUserId');
    _socket!.emit('join_private_chat', {
      'otherUserId': otherUserId,
      'currentUserId': _userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void leavePrivateChat(String otherUserId) {
    AppLogger.info('🔵 Leaving private chat room with user: $otherUserId');
    
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot leave private chat: Socket not connected');
      return;
    }
    
    if (_userId == null) {
      AppLogger.error('Cannot leave private chat: Current user ID is null');
      return;
    }
    
    AppLogger.info('Leaving private chat room with other user: $otherUserId');
    _socket!.emit('leave_private_chat', {'otherUserId': otherUserId});
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot send message: Socket not connected');
      return;
    }
    
    if (!message.containsKey('to')) {
      AppLogger.error('Cannot send message: Recipient ID (to) is required');
      return;
    }
    
    if (_userId == null) {
      AppLogger.error('Cannot send message: Current user ID is null');
      return;
    }
    
    // Ensure the message has the correct format
    final messageData = {
      ...message,
      'from': _userId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    AppLogger.info('Sending private message: ${messageData.toString()}');
    _socket!.emit('private_message', messageData);
  }

  /// Send encrypted message
  Future<void> sendEncryptedMessage(String receiverId, String messageContent, String messageType) async {
    AppLogger.info('🔵 sendEncryptedMessage called');
    AppLogger.info('🔵 Receiver ID: $receiverId');
    AppLogger.info('🔵 Message content: $messageContent');
    AppLogger.info('🔵 Message type: $messageType');
    AppLogger.info('🔵 Socket connected: ${_socket?.connected}');
    AppLogger.info('🔵 Current user ID: $_userId');
    AppLogger.info('🔵 Key management service: ${_keyManagementService != null}');
    
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('❌ Cannot send encrypted message: Socket not connected');
      throw Exception('Socket not connected');
    }
    
    if (_userId == null) {
      AppLogger.error('❌ Cannot send encrypted message: Current user ID is null');
      throw Exception('Current user ID is null');
    }

    if (_keyManagementService == null) {
      AppLogger.error('❌ Cannot send encrypted message: Key management service not available');
      throw Exception('Key management service not available');
    }

    try {
      AppLogger.info('🔵 Getting conversation key for: $receiverId');
      AppLogger.info('🔵 [ENCRYPTION] Requesting key for conversation with: $receiverId');
      // Get conversation key
      final encryptionKey = await _keyManagementService!.getConversationKey(receiverId);
      AppLogger.info('🔵 [ENCRYPTION] Got encryption key: ${encryptionKey.substring(0, 10)}...');
      
      AppLogger.info('🔵 Encrypting message');
      // Encrypt the message
      final encryptedData = E2EEUtils.encryptMessage(messageContent, encryptionKey);
      AppLogger.info('🔵 Message encrypted successfully');
      
      // Create message data with encrypted content
      final messageData = {
        'from': _userId,
        'to': receiverId,
        'content': '[ENCRYPTED]', // Placeholder for backward compatibility
        'messageType': messageType,
        'timestamp': DateTime.now().toIso8601String(),
        'encryptedContent': encryptedData['encryptedContent'],
        'encryptionMetadata': {
          'iv': encryptedData['iv'],
          'authTag': encryptedData['authTag'],
          'algorithm': encryptedData['algorithm']
        }
      };
      
      AppLogger.info('🔵 Sending encrypted message to: $receiverId');
      AppLogger.info('🔵 Message data: ${messageData.toString()}');
      _socket!.emit('private_message', messageData);
      AppLogger.info('✅ Encrypted message emitted successfully');
    } catch (error) {
      AppLogger.error('❌ Error sending encrypted message: $error');
      AppLogger.error('❌ Error stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Decrypt received message
  Future<Map<String, dynamic>> decryptMessage(Map<String, dynamic> message, String senderId) async {
    AppLogger.info('🔵 decryptMessage called');
    AppLogger.info('🔵 Sender ID: $senderId');
    AppLogger.info('🔵 Message has encryptedContent: ${message['encryptedContent'] != null}');
    AppLogger.info('🔵 Message has encryptionMetadata: ${message['encryptionMetadata'] != null}');
    AppLogger.info('🔵 Key management service available: ${_keyManagementService != null}');
    
    try {
      // Check if message is encrypted
      if (message['encryptedContent'] != null && message['encryptionMetadata'] != null) {
        if (_keyManagementService == null) {
          AppLogger.error('❌ Key management service not available');
          throw Exception('Key management service not available');
        }

        AppLogger.info('🔵 Getting conversation key for sender: $senderId');
        AppLogger.info('🔵 [DECRYPTION] Requesting key for conversation with: $senderId');
        // Get conversation key
        final encryptionKey = await _keyManagementService!.getConversationKey(senderId);
        AppLogger.info('🔵 [DECRYPTION] Got encryption key: ${encryptionKey.substring(0, 10)}...');
        
        AppLogger.info('🔵 Decrypting message with E2EEUtils');
        // Create the proper encrypted data structure
        final encryptedData = {
          'iv': message['encryptionMetadata']['iv'],
          'encryptedContent': message['encryptedContent'],
          'authTag': message['encryptionMetadata']['authTag'],
        };
        AppLogger.info('🔵 Encrypted data structure: $encryptedData');
        
        // Try to decrypt with server key first
        String decryptedContent;
        try {
          decryptedContent = E2EEUtils.decryptMessage(
            encryptedData,
            encryptionKey
          );
          AppLogger.info('✅ Message decrypted successfully with SERVER key');
        } catch (e) {
          AppLogger.warning('⚠️ Failed to decrypt with server key, trying deterministic key: $e');
          
          // Fallback: try with deterministic key for backward compatibility
          final authRepository = sl<AuthRepository>();
          final currentUser = await authRepository.getCurrentUser();
          final currentUserId = currentUser?.id ?? 'current_user';
          final deterministicKey = E2EEUtils.generateDeterministicKey(senderId, currentUserId);
          
          AppLogger.info('🔵 [DECRYPTION] Trying deterministic key: ${deterministicKey.substring(0, 10)}...');
          decryptedContent = E2EEUtils.decryptMessage(
            encryptedData,
            deterministicKey
          );
          AppLogger.info('✅ Message decrypted successfully with DETERMINISTIC key (backward compatibility)');
        }
        
        AppLogger.info('✅ Message decrypted successfully');
        AppLogger.info('🔵 Decrypted content: $decryptedContent');
        
        return {
          ...message,
          'content': decryptedContent,
          'isEncrypted': true
        };
      } else {
        AppLogger.info('🔵 Message is not encrypted, returning as-is');
        // Handle non-encrypted messages (backward compatibility)
        return {
          ...message,
          'isEncrypted': false
        };
      }
    } catch (error) {
      AppLogger.error('❌ Error decrypting message: $error');
      AppLogger.error('❌ Error stack trace: ${StackTrace.current}');
      return {
        ...message,
        'content': '[DECRYPTION FAILED]',
        'isEncrypted': true,
        'decryptionError': true
      };
    }
  }

  void sendImageViewed(String messageId, String conversationId) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot send image viewed event: Socket not connected');
      return;
    }

    AppLogger.info('Sending image viewed event for message: $messageId');
    _socket!.emit('image_viewed', {
      'messageId': messageId,
      'conversationId': conversationId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendImageExpired(String messageId, String conversationId) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot send image expired event: Socket not connected');
      return;
    }

    AppLogger.info('Sending image expired event for message: $messageId');
    _socket!.emit('image_expired', {
      'messageId': messageId,
      'conversationId': conversationId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _setupSocketListeners() {
    if (_socket == null) {
      AppLogger.error('Cannot setup listeners: Socket is null');
      return;
    }

    AppLogger.info('🔵 Setting up socket listeners');

    _socket!.onConnect((_) {
      AppLogger.info('✅ Socket connected successfully');
      AppLogger.info('🔵 Socket ID: ${_socket!.id}');
      AppLogger.info('🔵 Current user ID: $_userId');
      AppLogger.info('🔵 Emitting join event with userId: $_userId');
      _socket!.emit('join', _userId);
    });

    _socket!.on('roomJoined', (data) {
      AppLogger.info('✅ Joined room: $data');
      AppLogger.info('🔵 Room details: ${data.toString()}');
    });

    _socket!.on('private_chat_joined', (data) {
      AppLogger.info('✅ Joined private chat room: $data');
      AppLogger.info('🔵 Room details: ${data.toString()}');
      AppLogger.info('🔵 Socket ID: ${_socket!.id}');
      AppLogger.info('🔵 Current user ID: $_userId');
    });

    _socket!.on('private_chat_left', (data) {
      AppLogger.info('✅ Left private chat room: $data');
      AppLogger.info('🔵 Room details: ${data.toString()}');
    });

    _socket!.on('message_delivered', (data) {
      AppLogger.info('🔵 Received message_delivered event: $data');
      AppLogger.info('🔵 Socket ID: ${_socket!.id}');
      AppLogger.info('🔵 Current user ID: $_userId');
      AppLogger.info('🔵 Event details: ${data.toString()}');
    });

    _socket!.onDisconnect((_) {
      AppLogger.warning('⚠️ Socket disconnected');
      AppLogger.warning('⚠️ Socket ID: ${_socket?.id}');
      AppLogger.warning('⚠️ Current user ID: $_userId');
    });

    _socket!.on('error', (data) {
      AppLogger.error('❌ Socket error: $data');
      AppLogger.error('❌ Socket ID: ${_socket?.id}');
      AppLogger.error('❌ Current user ID: $_userId');
    });

    _socket!.on('connect_error', (data) {
      AppLogger.error('❌ Socket connection error: $data');
      AppLogger.error('❌ Socket ID: ${_socket?.id}');
      AppLogger.error('❌ Current user ID: $_userId');
    });

    _socket!.on('connect_timeout', (data) {
      AppLogger.error('❌ Socket connection timeout: $data');
      AppLogger.error('❌ Socket ID: ${_socket?.id}');
      AppLogger.error('❌ Current user ID: $_userId');
    });

    _socket!.on('reconnect', (data) {
      AppLogger.info('✅ Socket reconnected: $data');
      AppLogger.info('🔵 Socket ID: ${_socket!.id}');
      AppLogger.info('🔵 Current user ID: $_userId');
    });

    _socket!.on('reconnect_attempt', (data) {
      AppLogger.info('🔵 Socket reconnection attempt: $data');
      AppLogger.info('🔵 Socket ID: ${_socket?.id}');
      AppLogger.info('🔵 Current user ID: $_userId');
    });

    _socket!.on('reconnect_error', (data) {
      AppLogger.error('❌ Socket reconnection error: $data');
      AppLogger.error('❌ Socket ID: ${_socket?.id}');
      AppLogger.error('❌ Current user ID: $_userId');
    });

    _socket!.on('reconnect_failed', (data) {
      AppLogger.error('❌ Socket reconnection failed: $data');
      AppLogger.error('❌ Socket ID: ${_socket?.id}');
      AppLogger.error('❌ Current user ID: $_userId');
    });

    // Online status event handlers
    _socket!.on('user_online', (data) {
      AppLogger.info('🟢 User came online: $data');
      _handleUserOnlineStatus(data, true);
    });

    _socket!.on('user_offline', (data) {
      AppLogger.info('🔴 User went offline: $data');
      _handleUserOnlineStatus(data, false);
    });
    
    AppLogger.info('✅ Socket listeners setup complete');
  }

  void disconnect() {
    if (_socket != null) {
      AppLogger.info('Disconnecting socket...');
      _socket!.disconnect();
      _socket = null;
      AppLogger.info('Socket disconnected and cleaned up');
    }
  }

  void emit(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('❌ Cannot emit $event: Socket not connected');
      AppLogger.error('❌ Socket instance: $_socket');
      AppLogger.error('❌ Socket connected: ${_socket?.connected}');
      return;
    }
    AppLogger.info('📤 EMITTING EVENT: $event');
    AppLogger.info('📤 Event data: ${data.toString()}');
    AppLogger.info('📤 Socket ID: ${_socket!.id}');
    AppLogger.info('📤 Current user ID: $_userId');
    AppLogger.info('📤 Timestamp: ${DateTime.now().toIso8601String()}');
    _socket!.emit(event, data);
    AppLogger.info('✅ Event $event emitted successfully');
  }

  void on(String event, Function(dynamic) handler) {
    if (_socket == null) {
      AppLogger.error('❌ Cannot add listener for $event: Socket not initialized');
      return;
    }
    AppLogger.info('📥 REGISTERING LISTENER: $event');
    AppLogger.info('📥 Socket ID: ${_socket!.id}');
    AppLogger.info('📥 Current user ID: $_userId');
    AppLogger.info('📥 Timestamp: ${DateTime.now().toIso8601String()}');
    
    // Track the listener
    _listeners.putIfAbsent(event, () => []).add(handler);
    AppLogger.info('📥 Total listeners for $event: ${_listeners[event]?.length ?? 0}');
    
    _socket!.on(event, (data) {
      AppLogger.info('📥 RECEIVED EVENT: $event');
      AppLogger.info('📥 Event data: ${data.toString()}');
      AppLogger.info('📥 Socket ID: ${_socket!.id}');
      AppLogger.info('📥 Current user ID: $_userId');
      AppLogger.info('📥 Timestamp: ${DateTime.now().toIso8601String()}');
      AppLogger.info('📥 Handler count for $event: ${_listeners[event]?.length ?? 0}');
      handler(data);
      AppLogger.info('✅ Event $event processed successfully');
    });
  }

  void off(String event) {
    if (_socket == null) {
      AppLogger.error('Cannot remove listener for $event: Socket not initialized');
      return;
    }
    AppLogger.info('Removing ALL listeners for event: $event');
    _socket!.off(event);
    _listeners.remove(event);
  }
  
  void offSpecific(String event, Function(dynamic) handler) {
    if (_socket == null) {
      AppLogger.error('Cannot remove specific listener for $event: Socket not initialized');
      return;
    }
    
    final listeners = _listeners[event];
    if (listeners != null) {
      listeners.remove(handler);
      if (listeners.isEmpty) {
        _listeners.remove(event);
        _socket!.off(event);
        AppLogger.info('Removed last listener for event: $event');
      } else {
        AppLogger.info('Removed specific listener for event: $event, ${listeners.length} remaining');
      }
    }
  }

  bool get isSocketConnected => _socket?.connected ?? false;

  /// Handle user online/offline status changes
  void _handleUserOnlineStatus(dynamic data, bool isOnline) {
    try {
      if (data is Map<String, dynamic> && data.containsKey('userId')) {
        final userId = data['userId'] as String;
        AppLogger.info('🔄 Updating online status for user $userId: $isOnline');
        
        // TODO: Update user status in local state management
        // This would typically involve updating a bloc or state management system
        // For now, we'll just log the status change
        AppLogger.info('📱 User $userId is now ${isOnline ? 'online' : 'offline'}');
      } else {
        AppLogger.warning('⚠️ Invalid user status data received: $data');
      }
    } catch (e) {
      AppLogger.error('❌ Error handling user online status: $e');
    }
  }

  // Game event methods
  void sendGameInvite({required String gameType, required String otherUserId}) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot send game invite: Socket not connected');
      return;
    }
    
    if (_userId == null) {
      AppLogger.error('Cannot send game invite: Current user ID is null');
      return;
    }
    
    final gameInviteData = {
      'gameType': gameType,
      'otherUserId': otherUserId,
    };
    
    AppLogger.info('🎮 Sending game invite: ${gameInviteData.toString()}');
    _socket!.emit('game_invite', gameInviteData);
  }

  void acceptGameInvite({required String gameType, required String otherUserId}) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot accept game invite: Socket not connected');
      return;
    }
    
    if (_userId == null) {
      AppLogger.error('Cannot accept game invite: Current user ID is null');
      return;
    }
    
    final acceptData = {
      'gameType': gameType,
      'otherUserId': otherUserId,
    };
    
    AppLogger.info('🎮 Accepting game invite: ${acceptData.toString()}');
    _socket!.emit('game_invite_accepted', acceptData);
  }

  void rejectGameInvite({required String gameType, required String fromUserId, String? reason}) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot reject game invite: Socket not connected');
      return;
    }
    
    if (_userId == null) {
      AppLogger.error('Cannot reject game invite: Current user ID is null');
      return;
    }
    
    final rejectData = {
      'gameType': gameType,
      'fromUserId': fromUserId,
      'reason': reason ?? 'declined',
    };
    
    AppLogger.info('🎮 Rejecting game invite: ${rejectData.toString()}');
    _socket!.emit('game_invite_rejected', rejectData);
  }

  void completeGameTurn({
    required String sessionId,
    String? selectedChoice,
    required Map<String, dynamic> selectedPrompt,
  }) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot complete game turn: Socket not connected');
      return;
    }
    
    final turnData = {
      'sessionId': sessionId,
      'selectedChoice': selectedChoice,
      'selectedPrompt': selectedPrompt,
    };
    
    AppLogger.info('🎮 Completing game turn: ${turnData.toString()}');
    _socket!.emit('game_turn_completed', turnData);
  }

  void endGame({required String sessionId, required String reason}) {
    if (_socket == null || !_socket!.connected) {
      AppLogger.error('Cannot end game: Socket not connected');
      return;
    }
    
    final endData = {
      'sessionId': sessionId,
      'reason': reason,
    };
    
    AppLogger.info('🎮 Ending game: ${endData.toString()}');
    _socket!.emit('game_ended', endData);
  }

  /// Send heartbeat to maintain online status
  void sendHeartbeat() {
    if (_socket != null && _socket!.connected) {
      AppLogger.info('💓 Sending heartbeat');
      _socket!.emit('heartbeat');
    } else {
      AppLogger.warning('⚠️ Cannot send heartbeat: Socket not connected');
    }
  }

  /// Start heartbeat timer (call this when app becomes active)
  Timer? _heartbeatTimer;
  void startHeartbeat({Duration interval = const Duration(seconds: 30)}) {
    // Stop existing timer if any
    _heartbeatTimer?.cancel();
    
    AppLogger.info('💓 Starting heartbeat with interval: ${interval.inSeconds}s');
    _heartbeatTimer = Timer.periodic(interval, (timer) {
      if (_socket?.connected == true) {
        sendHeartbeat();
      } else {
        AppLogger.warning('⚠️ Stopping heartbeat: Socket disconnected');
        timer.cancel();
      }
    });
  }

  /// Stop heartbeat timer (call this when app goes to background)
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    AppLogger.info('💓 Heartbeat stopped');
  }

  /// Debug method to log all registered listeners
  void logRegisteredListeners() {
    AppLogger.info('🔍 REGISTERED LISTENERS DEBUG:');
    AppLogger.info('🔍 Socket connected: ${_socket?.connected}');
    AppLogger.info('🔍 Socket ID: ${_socket?.id}');
    AppLogger.info('🔍 Current user ID: $_userId');
    AppLogger.info('🔍 Total event types with listeners: ${_listeners.length}');
    
    _listeners.forEach((event, handlers) {
      AppLogger.info('🔍 Event: $event - Handler count: ${handlers.length}');
    });
    
    if (_listeners.isEmpty) {
      AppLogger.warning('⚠️ No listeners registered!');
    }
  }
} 