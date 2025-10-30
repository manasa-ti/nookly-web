import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/bloc/inbox/inbox_bloc.dart';
import 'package:nookly/presentation/pages/chat/chat_page.dart';
import 'package:nookly/presentation/pages/profile/profile_view_page.dart';
import 'package:intl/intl.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/services/api_cache_service.dart';
import 'package:nookly/core/services/user_cache_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/presentation/widgets/game_invite_indicator.dart';
import 'package:nookly/presentation/widgets/messaging_tutorial_overlay.dart';
import 'package:nookly/core/services/onboarding_service.dart';
import 'package:nookly/presentation/bloc/games/games_bloc.dart';
import 'package:nookly/presentation/bloc/games/games_event.dart';
import 'package:nookly/core/services/games_service.dart';
import 'package:nookly/data/repositories/games_repository_impl.dart';
import 'package:nookly/domain/entities/game_invite.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> with WidgetsBindingObserver {
  InboxBloc? _inboxBloc;
  GamesBloc? _gamesBloc;
  User? _currentUser;
  bool _isLoadingCurrentUser = true;
  String? _initializationError;
  SocketService? _socketService;
  bool _showMessagingTutorial = false;
  // REMOVED: _pendingGameInvites - not needed for notification-based architecture
  
  // Store listener references for proper cleanup
  Function(dynamic)? _messageNotificationListener;
  Function(dynamic)? _typingListener;
  Function(dynamic)? _conversationUpdatedListener;
  Function(dynamic)? _conversationRemovedListener;
  Function(dynamic)? _userOnlineListener;
  Function(dynamic)? _userOfflineListener;
  Function(dynamic)? _gameNotificationListener;
  Function(dynamic)? _errorListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChatInbox();
    _checkMessagingTutorial();
  }

  void _checkMessagingTutorial() async {
    final shouldShow = await OnboardingService.shouldShowMessagingTutorial();
    if (shouldShow && mounted) {
      setState(() {
        _showMessagingTutorial = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leaveAllChatRooms();
    _inboxBloc?.close();
    _gamesBloc?.close();
    if (_socketService != null) {
      // Remove specific listeners to avoid affecting other pages
      if (_messageNotificationListener != null) {
        _socketService!.offSpecific('message_notification', _messageNotificationListener!);
      }
      if (_typingListener != null) {
        _socketService!.offSpecific('typing', _typingListener!);
      }
      if (_conversationUpdatedListener != null) {
        _socketService!.offSpecific('conversation_updated', _conversationUpdatedListener!);
      }
      if (_conversationRemovedListener != null) {
        _socketService!.offSpecific('conversation_removed', _conversationRemovedListener!);
      }
      if (_userOnlineListener != null) {
        _socketService!.offSpecific('user_online', _userOnlineListener!);
      }
      if (_userOfflineListener != null) {
        _socketService!.offSpecific('user_offline', _userOfflineListener!);
      }
      if (_gameNotificationListener != null) {
        _socketService!.offSpecific('game_notification', _gameNotificationListener!);
      }
      if (_errorListener != null) {
        _socketService!.offSpecific('error', _errorListener!);
      }
    }
    // ❌ REMOVED: _socketService?.disconnect();
    // Don't disconnect the shared socket service - let it stay connected for other pages
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconnectSocket();
    }
  }

  Future<void> _reconnectSocket() async {
    AppLogger.info('🔄 Reconnecting socket in inbox page');
    
    // Use existing user data if available, otherwise fetch fresh data
    if (_currentUser != null) {
      final authRepository = sl<AuthRepository>();
      final token = await authRepository.getToken();
      if (token != null) {
        _initSocketWithData(_currentUser!, token);
        if (_socketService?.isConnected == true && _inboxBloc?.state is InboxLoaded) {
          _joinAllChatRooms();
        }
      }
    } else {
      // Fallback to full initialization if no user data
      await _initializeChatInbox();
    }
  }

  void _leaveAllChatRooms() {
    // REMOVED: ChatInboxPage no longer leaves conversation rooms
    // This follows WhatsApp/Telegram architecture where inbox only receives notifications
    AppLogger.info('🔵 ChatInboxPage: Not leaving conversation rooms (notification-only mode)');
  }

  void _joinAllChatRooms() {
    if (_socketService == null || !_socketService!.isConnected) {
      AppLogger.warning('🔵 ChatInboxPage: Cannot join rooms - socket not connected');
      return;
    }
    
    AppLogger.info('🔵 ChatInboxPage: Joining all conversation rooms for event bus approach');
    
    if (_inboxBloc?.state is InboxLoaded) {
      final currentState = _inboxBloc!.state as InboxLoaded;
      final conversations = currentState.conversations;
      
      AppLogger.info('🔵 ChatInboxPage: Found ${conversations.length} conversations to join');
      
      for (final conversation in conversations) {
        // Room management removed - using direct socket listeners with filtering
        AppLogger.info('🔵 ChatInboxPage: Current user: ${_currentUser?.id}, Participant: ${conversation.participantId}');
      }
    } else {
      AppLogger.warning('🔵 ChatInboxPage: No conversations loaded yet, cannot join rooms');
    }
  }

  /// Optimized initialization method that reuses cached user data when possible
  Future<void> _initializeChatInbox() async {
    try {
      AppLogger.info('🔵 ChatInboxPage: Starting optimized chat inbox initialization');
      final totalStopwatch = Stopwatch()..start();
      
      final authRepository = sl<AuthRepository>();
      
      AppLogger.info('🔵 ChatInboxPage: Checking for cached user data first');
      final authStopwatch = Stopwatch()..start();
      
      // Try to get cached user data first (much faster)
      final userCacheService = sl<UserCacheService>();
      User? user = userCacheService.getCachedUser();
      
      if (user != null) {
        AppLogger.info('🔵 ChatInboxPage: Using cached user data for user: ${user.id}');
        // Only fetch token since we have cached user data
        final token = await authRepository.getToken();
        
        authStopwatch.stop();
        AppLogger.info('🔵 ChatInboxPage: Cached user data + token fetched in ${authStopwatch.elapsedMilliseconds}ms');
        
        if (mounted && token != null) {
          setState(() {
            _currentUser = user;
            _isLoadingCurrentUser = false;
          });
          
          // Initialize bloc with cached user data
          _inboxBloc = sl<InboxBloc>(param1: user.id);
          _inboxBloc!.add(LoadInbox());
          
          // Join conversation rooms after loading conversations
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _joinAllChatRooms();
          });
          
          // Initialize socket with cached user data and token
          _initSocketWithData(user, token);
          
          totalStopwatch.stop();
          AppLogger.info('🔵 ChatInboxPage: Optimized initialization completed in ${totalStopwatch.elapsedMilliseconds}ms');
          AppLogger.info('🔵 ChatInboxPage: Initialized with cached user ${user.id}');
          return;
        }
      }
      
      // Fallback: Fetch user data and token if no cache available
      AppLogger.info('🔵 ChatInboxPage: No cached user data, fetching fresh data');
      final userFuture = authRepository.getCurrentUser();
      final tokenFuture = authRepository.getToken();
      
      // Wait for both to complete
      final results = await Future.wait([userFuture, tokenFuture]);
      user = results[0] as User?;
      final token = results[1] as String?;
      
      authStopwatch.stop();
      AppLogger.info('🔵 ChatInboxPage: Fresh auth data fetched in ${authStopwatch.elapsedMilliseconds}ms');
      
      if (mounted) {
        if (user != null && token != null) {
          setState(() {
            _currentUser = user;
            _isLoadingCurrentUser = false;
          });
          
          // Initialize bloc with fresh user data
          _inboxBloc = sl<InboxBloc>(param1: user.id);
          _inboxBloc!.add(LoadInbox());
          
          // Join conversation rooms after loading conversations
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _joinAllChatRooms();
          });
          
          // Initialize socket with fresh user data and token
          _initSocketWithData(user, token);
          
          totalStopwatch.stop();
          AppLogger.info('🔵 ChatInboxPage: Fresh initialization completed in ${totalStopwatch.elapsedMilliseconds}ms');
          AppLogger.info('🔵 ChatInboxPage: Initialized with fresh user ${user.id}');
        } else {
          setState(() {
            _initializationError = 'Failed to load user or token. Please try again.';
            _isLoadingCurrentUser = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = 'Error initializing: ${e.toString()}';
          _isLoadingCurrentUser = false;
        });
      }
    }
  }

  /// Initialize socket with pre-fetched user data and token
  void _initSocketWithData(User user, String token) {
    AppLogger.info('🔵 ChatInboxPage: Initializing socket connection');
    final socketStopwatch = Stopwatch()..start();
    
    _socketService = sl<SocketService>(); // This should be the same singleton instance
    
    // Only connect if not already connected
    if (!_socketService!.isConnected) {
      AppLogger.info('🔵 Socket not connected, establishing connection...');
      _socketService!.connect(
        serverUrl: SocketService.socketUrl, 
        token: token,
        userId: user.id,
      );
    } else {
      AppLogger.info('🔵 Socket already connected, reusing existing connection');
    }
    
    // Initialize GamesBloc after socket service is created
    final gamesRepository = GamesRepositoryImpl(socketService: _socketService!);
    final timeoutManager = GameTimeoutManager(
      onInviteTimeout: (sessionId) {
        if (_gamesBloc != null) {
          _gamesBloc!.add(GameInviteTimeout(sessionId: sessionId));
        }
      },
      onTurnTimeout: (sessionId) {
        if (_gamesBloc != null) {
          _gamesBloc!.add(GameTurnTimeout(sessionId: sessionId));
        }
      },
      onSessionTimeout: (sessionId) {
        if (_gamesBloc != null) {
          _gamesBloc!.add(GameSessionTimeout(sessionId: sessionId));
        }
      },
    );
    
    _gamesBloc = GamesBloc(
      gamesService: GamesService(
        gamesRepository: gamesRepository,
        timeoutManager: timeoutManager,
      ),
      timeoutManager: timeoutManager,
    );
    
    _registerSocketListeners();
    _joinAllChatRooms();
    
    socketStopwatch.stop();
    AppLogger.info('🔵 ChatInboxPage: Socket initialization completed in ${socketStopwatch.elapsedMilliseconds}ms');
  }

  void _registerSocketListeners() {
    if (_socketService == null) return;
    
    AppLogger.info('🔵 Registering direct socket listeners for chat inbox');
    AppLogger.info('🔵 Using direct socket listeners - both inbox and chat receive same events');
    
    // Test socket functionality
    AppLogger.info('🔵 Testing socket functionality...');
    _socketService!.emit('test_inbox_event', {'message': 'Socket is working in inbox'});
    
    // Test listener to verify socket is working
    _socketService!.on('test_inbox_event', (data) {
      AppLogger.info('🔵 Inbox: Test event received: $data');
    });
    
    // Listen for private_message events via direct socket listener
    _socketService!.on('private_message', (data) async {
      AppLogger.info('📥 [INBOX] private_message event received via direct socket listener');
      AppLogger.info('📥 [INBOX] Current user ID: ${_currentUser?.id}');
      AppLogger.info('📥 [INBOX] From: ${data['from'] ?? data['sender']}');
      AppLogger.info('📥 [INBOX] To: ${data['to'] ?? data['receiver']}');
      AppLogger.info('📥 [INBOX] Message type: ${data['messageType'] ?? data['type'] ?? 'text'}');
      AppLogger.info('📥 [INBOX] Content: ${data['content']}');
      AppLogger.info('📥 [INBOX] Is encrypted: ${data['encryptedContent'] != null}');
      AppLogger.info('📥 [INBOX] Is disappearing: ${data['isDisappearing']}');
      AppLogger.info('📥 [INBOX] Disappearing time: ${data['disappearingTime']}');
      AppLogger.info('📥 [INBOX] Message ID: ${data['_id'] ?? data['id']}');
      AppLogger.info('📥 [INBOX] Timestamp: ${data['timestamp'] ?? data['createdAt']}');
      AppLogger.info('📥 [INBOX] Full event data: $data');
      AppLogger.info('📥 [INBOX] Available fields: ${data.keys.toList()}');
      AppLogger.info('📥 [INBOX] Event timestamp: ${DateTime.now().toIso8601String()}');
      
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        
        // Try multiple possible field names for conversation ID
        final eventConversationId = data['conversationId'] as String? ?? 
                                   data['conversation_id'] as String? ?? 
                                   data['roomId'] as String? ?? 
                                   data['room_id'] as String?;
        
        AppLogger.info('🔵 Inbox: Event Conversation ID: $eventConversationId');
        AppLogger.info('🔵 Inbox: Available conversations: ${conversations.map((c) => c.id).toList()}');
        
        // Try to match by constructed conversation ID first
        Conversation? conversation;
        if (eventConversationId != null) {
          conversation = conversations.where((c) {
            final userIds = [_currentUser?.id ?? '', c.participantId];
            userIds.sort();
            final sortedConversationId = '${userIds[0]}_${userIds[1]}';
            return sortedConversationId == eventConversationId;
          }).firstOrNull;
        }
        
        // Fallback: If no conversation found by ID, try to match by participant ID
        if (conversation == null && eventConversationId == null) {
          final fromUserId = data['from'] as String? ?? data['sender'] as String?;
          if (fromUserId != null) {
            conversation = conversations.where((c) => c.participantId == fromUserId).firstOrNull;
            AppLogger.info('🔵 Inbox: Fallback - matched conversation by participant ID: $fromUserId');
          }
        }
        
        if (conversation != null) {
          AppLogger.info('🔵 Processing private_message in inbox from: ${conversation.participantName}');
          AppLogger.info('🔵 Conversation ID: $eventConversationId');
          AppLogger.info('🔵 Message content: ${data['content']}');
          AppLogger.info('🔵 Message is encrypted: ${data['isEncrypted']}');
          AppLogger.info('🔵 Encrypted content: ${data['encryptedContent']}');
          AppLogger.info('🔵 Encryption metadata: ${data['encryptionMetadata']}');
          AppLogger.info('🔵 Full socket event data keys: ${data.keys.toList()}');
          AppLogger.info('🔵 Full socket event data: $data');
          AppLogger.info('🔵 Current unread count: ${conversation.unreadCount}');
          
          // Check if this message is already part of the conversation (already loaded)
          final messageId = data['_id'] ?? data['id'];
          final messageTimestamp = DateTime.parse(data['createdAt'] ?? data['timestamp'] ?? DateTime.now().toIso8601String());
          
          // Skip if this message is older than the last message time (already processed)
          // Only process messages that are NEWER than what we already have
          if (messageTimestamp.isBefore(conversation.lastMessageTime)) {
            AppLogger.info('⏭️ Skipping old message - already in conversation');
            AppLogger.info('⏭️ Message timestamp: $messageTimestamp');
            AppLogger.info('⏭️ Last message time: ${conversation.lastMessageTime}');
            return; // Skip processing this message
          }
          
          // Skip if this is the exact same message
          if (conversation.lastMessage?.id == messageId) {
            AppLogger.info('⏭️ Skipping duplicate message - same ID');
            AppLogger.info('⏭️ Message ID: $messageId');
            return; // Skip processing this message
          }
          
          // Create message from full private_message data
          final message = Message(
            id: data['_id'] ?? data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            sender: data['from'] ?? data['sender'] ?? '',
            receiver: _currentUser?.id ?? '',
            content: data['content'] ?? '',
            timestamp: DateTime.parse(data['createdAt'] ?? data['timestamp'] ?? DateTime.now().toIso8601String()),
            type: _getMessageTypeFromString(data['messageType'] ?? data['type'] ?? 'text'),
            status: data['status'] ?? 'sent',
            metadata: data['metadata'] != null ? MessageMetadata.fromJson(data['metadata'] as Map<String, dynamic>) : null,
            isEncrypted: data['isEncrypted'] ?? false,
            encryptedContent: data['encryptedContent'],
            encryptionMetadata: data['encryptionMetadata'],
          );
          
          // Decrypt message if it's encrypted
          Message decryptedMessage = message;
          AppLogger.info('🔍 DECRYPTION CHECK:');
          AppLogger.info('  - message.isEncrypted: ${message.isEncrypted}');
          AppLogger.info('  - message.content: "${message.content}"');
          AppLogger.info('  - message.encryptedContent != null: ${message.encryptedContent != null}');
          AppLogger.info('  - Should decrypt: ${(message.isEncrypted || message.content == '[ENCRYPTED]') && message.encryptedContent != null}');
          
          if ((message.isEncrypted || message.content == '[ENCRYPTED]') && message.encryptedContent != null) {
            try {
              AppLogger.info('🔵 Attempting to decrypt message for inbox preview');
              AppLogger.info('🔵 Decryption data: ${data.toString()}');
              AppLogger.info('🔵 Sender: ${message.sender}');
              final decryptedData = await _socketService!.decryptMessage(data, message.sender);
              AppLogger.info('🔵 Decryption result: ${decryptedData.toString()}');
              AppLogger.info('🔵 Decrypted content: "${decryptedData['content']}"');
              
              decryptedMessage = Message(
                id: message.id,
                sender: message.sender,
                receiver: message.receiver,
                content: decryptedData['content'] ?? message.content,
                timestamp: message.timestamp,
                type: message.type,
                status: message.status,
                metadata: message.metadata,
                isEncrypted: false,
                encryptedContent: null,
                encryptionMetadata: null,
              );
              AppLogger.info('🔵 Message decrypted successfully for inbox: "${decryptedMessage.content}"');
            } catch (e) {
              AppLogger.error('❌ Failed to decrypt message for inbox: $e');
              AppLogger.error('❌ Error stack trace: ${StackTrace.current}');
              // Use original message with encrypted indicator
              decryptedMessage = message.copyWith(
                content: '[Encrypted Message]',
              );
            }
          } else {
            AppLogger.info('🔵 Message not encrypted or no encrypted content available');
            AppLogger.info('🔵 isEncrypted: ${message.isEncrypted}');
            AppLogger.info('🔵 content: ${message.content}');
            AppLogger.info('🔵 encryptedContent: ${message.encryptedContent}');
            
            // If content is "[ENCRYPTED]" but no encrypted content is available,
            // this means the socket event didn't include encryption data
            // Clear encryption fields to prevent false positives in decryption checks
            if (message.content == '[ENCRYPTED]' && message.encryptedContent == null) {
              AppLogger.warning('⚠️ Message content is [ENCRYPTED] but no encryptedContent available in socket event');
              AppLogger.warning('⚠️ This might indicate the socket event is missing encryption data');
              // Clear encryption fields to prevent the message from being treated as encrypted
              decryptedMessage = message.copyWith(
                isEncrypted: false,
                encryptedContent: null,
                encryptionMetadata: null,
              );
            } else {
              // Ensure encryption fields are cleared for non-encrypted messages
              decryptedMessage = message.copyWith(
                isEncrypted: false,
                encryptedContent: null,
                encryptionMetadata: null,
              );
            }
          }
          
          // Check if the message is from the current user
          final isMessageFromCurrentUser = message.sender == _currentUser?.id;
          AppLogger.info('🔵 Message sender: ${message.sender}, Current user: ${_currentUser?.id}');
          AppLogger.info('🔵 Is message from current user: $isMessageFromCurrentUser');
          
          // Create updated conversation with new unread count and last message
          // Only increment unread count if the message is NOT from the current user
          final updatedConversation = conversation.copyWith(
            unreadCount: isMessageFromCurrentUser ? conversation.unreadCount : conversation.unreadCount + 1,
            lastMessage: decryptedMessage,
            lastMessageTime: decryptedMessage.timestamp,
            updatedAt: DateTime.now(),
            // Don't add to messages list - this is just a preview
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.participantId == conversation?.participantId ? updatedConversation : c
          ).toList();
          
          // Sort conversations by last message time (newest first)
          updatedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          // Emit updated state immediately
          AppLogger.info('🔵 Emitting InboxUpdated event with ${updatedConversations.length} conversations');
          _inboxBloc?.add(InboxUpdated(conversations: updatedConversations));
          
          // Invalidate cache since we have new message data
          if (_currentUser != null) {
            final apiCacheService = ApiCacheService();
            apiCacheService.invalidateCache('unified_conversations_${_currentUser!.id}');
            AppLogger.info('🔵 Unified cache invalidated due to new message received');
            
            // Note: Conversation key cache is NOT invalidated here because
            // the same conversation is being updated, not a new conversation created
          }
          
          AppLogger.info('🔵 Updated unread count: ${updatedConversation.unreadCount}');
          AppLogger.info('🔵 Updated last message: ${updatedConversation.lastMessage?.content}');
          AppLogger.info('🔵 Message type: ${updatedConversation.lastMessage?.type}');
          AppLogger.info('🔵 Updated conversation participant: ${updatedConversation.participantName}');
        }
      }
    });

    // Listen for typing events via direct socket listener
    _typingListener = (data) {
      // COMPREHENSIVE LOGGING - Let's see exactly what we receive
      AppLogger.info('====== INBOX: TYPING EVENT RECEIVED ======');
      AppLogger.info('📥 Full event data: $data');
      AppLogger.info('📥 Event keys: ${data.keys.toList()}');
      AppLogger.info('📥 Raw isTyping value: ${data['isTyping']} (type: ${data['isTyping']?.runtimeType})');
      AppLogger.info('📥 Raw from value: ${data['from']} (type: ${data['from']?.runtimeType})');
      AppLogger.info('📥 Raw to value: ${data['to']} (type: ${data['to']?.runtimeType})');
      AppLogger.info('📥 Raw conversationId: ${data['conversationId']}');
      
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        
        final fromUserId = data['from'] as String? ?? data['sender'] as String?;
        final isTyping = data['isTyping'] as bool?;
        final eventConversationId = data['conversationId'] as String? ?? 
                                   data['conversation_id'] as String? ?? 
                                   data['roomId'] as String? ?? 
                                   data['room_id'] as String?;
        
        AppLogger.info('🔍 Parsed values:');
        AppLogger.info('  - fromUserId: $fromUserId');
        AppLogger.info('  - isTyping: $isTyping (null means field missing)');
        AppLogger.info('  - eventConversationId: $eventConversationId');
        AppLogger.info('  - _currentUser?.id: ${_currentUser?.id}');
        AppLogger.info('  - Available conversations: ${conversations.map((c) => '${c.participantName} (${c.participantId})').toList()}');
        
        // Ignore typing events from the current user
        if (fromUserId == _currentUser?.id) {
          AppLogger.info('❌ IGNORING: This is our own typing event');
          return;
        }
        
        // Try to match conversation by conversation ID first
        Conversation? conversation;
        if (eventConversationId != null) {
          conversation = conversations.where((c) {
            final userIds = [_currentUser?.id ?? '', c.participantId];
            userIds.sort();
            final sortedConversationId = '${userIds[0]}_${userIds[1]}';
            AppLogger.info('  Checking conversation: ${c.participantName}, sortedId: $sortedConversationId vs eventId: $eventConversationId');
            return sortedConversationId == eventConversationId;
          }).firstOrNull;
        }
        
        // Fallback: Match by participant ID (from field)
        if (conversation == null && fromUserId != null) {
          conversation = conversations.where((c) => c.participantId == fromUserId).firstOrNull;
          if (conversation != null) {
            AppLogger.info('🔍 Matched conversation by participant ID: ${conversation.participantName}');
          }
        }
        
        if (conversation != null) {
          AppLogger.info('✅ VALID TYPING EVENT in inbox from: ${conversation.participantName}');
          
          if (isTyping == true) {
            AppLogger.info('🟢 ${conversation.participantName} STARTED TYPING - will show "typing..." in inbox');
          } else if (isTyping == false) {
            AppLogger.info('🔴 ${conversation.participantName} STOPPED TYPING - will hide "typing..."');
          } else {
            AppLogger.warning('⚠️ isTyping field is null or missing!');
          }
          
          // Update conversation with typing status
          final updatedConversation = conversation.copyWith(
            isTyping: isTyping ?? false,
            updatedAt: DateTime.now(),
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.participantId == conversation?.participantId ? updatedConversation : c
          ).toList();
          
          // Emit updated state immediately
          _inboxBloc?.add(InboxUpdated(conversations: updatedConversations));
          
          AppLogger.info('💚 Updated typing status for ${conversation.participantName}: ${isTyping ?? false}');
        } else {
          AppLogger.warning('❌ Could not find conversation for typing event from user: $fromUserId');
        }
      }
      
      AppLogger.info('====== END INBOX TYPING EVENT ======');
    };
    _socketService!.on('typing', _typingListener!);

    // REMOVED: stop_typing listener - typing_notification handles both start and stop

    _conversationUpdatedListener = (data) async {
      // Pretty-print the full payload in chunks to avoid truncation
      Map<String, dynamic> _asStringKeyedMap(dynamic v) {
        if (v is Map<String, dynamic>) return v;
        if (v is Map) {
          return v.map((key, value) => MapEntry(key.toString(), value));
        }
        return <String, dynamic>{};
      }
      String _prettyJson(dynamic any) {
        try {
          // Avoid imports by delegating to toString if encoder not available
          // but prefer JSON-like formatting when possible
          final map = _asStringKeyedMap(any);
          // Lightweight pretty format
          return map.toString();
        } catch (_) {
          return any.toString();
        }
      }
      void _logLarge(String title, String text, {int chunk = 800}) {
        AppLogger.info('🔍 $title (len=${text.length})');
        for (int i = 0; i < text.length; i += chunk) {
          final end = (i + chunk < text.length) ? i + chunk : text.length;
          AppLogger.info(text.substring(i, end));
        }
      }

      try {
        final full = _prettyJson(data);
        _logLarge('conversation_updated FULL', full);
        final lastMsg = _asStringKeyedMap((data as Map)['lastMessage'] ?? {});
        _logLarge('conversation_updated lastMessage', _prettyJson(lastMsg));
        final metadata = _asStringKeyedMap(lastMsg['metadata'] ?? {});
        _logLarge('conversation_updated lastMessage.metadata', _prettyJson(metadata));
      } catch (e) {
        AppLogger.warning('⚠️ Pretty logging failed for conversation_updated: $e');
        AppLogger.info('🔍 Debugging received event: conversation_updated - Data: $data');
      }
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final conversation = conversations.where((c) => c.participantId == data['_id']).firstOrNull;
        
        if (conversation != null) {
          AppLogger.info('🔵 Updating conversation: ${conversation.participantName}');
          AppLogger.info('🔵 Current unread count: ${conversation.unreadCount}');
          AppLogger.info('🔵 Event unread count: ${data['unreadCount']}');
          AppLogger.info('🔵 Event last message: ${data['lastMessage']}');
          
          // Process the last message with decryption if needed
          Message? lastMessage;
          if (data['lastMessage'] != null) {
            final message = Message.fromJson(data['lastMessage']);
            AppLogger.info('🔍 CONVERSATION_UPDATED - Created message:');
            AppLogger.info('  - Message ID: ${message.id}');
            AppLogger.info('  - Message type: ${message.type}');
            AppLogger.info('  - Message metadata: ${message.metadata}');
            AppLogger.info('  - Message isDisappearing: ${message.metadata?.isDisappearing}');
            AppLogger.info('  - Message disappearingTime: ${message.metadata?.disappearingTime}');
            
            AppLogger.info('🔍 CONVERSATION_UPDATED DECRYPTION CHECK:');
            AppLogger.info('  - message.isEncrypted: ${message.isEncrypted}');
            AppLogger.info('  - message.content: "${message.content}"');
            AppLogger.info('  - message.encryptedContent != null: ${message.encryptedContent != null}');
            AppLogger.info('  - Should decrypt: ${(message.isEncrypted || message.content == '[ENCRYPTED]') && message.encryptedContent != null}');
            
            if ((message.isEncrypted || message.content == '[ENCRYPTED]') && message.encryptedContent != null) {
              try {
                AppLogger.info('🔵 Attempting to decrypt message from conversation_updated event');
                AppLogger.info('🔵 Decryption data: ${data['lastMessage'].toString()}');
                AppLogger.info('🔵 Sender: ${message.sender}');
                final decryptedData = await _socketService!.decryptMessage(data['lastMessage'], message.sender);
                AppLogger.info('🔵 Decryption result: ${decryptedData.toString()}');
                AppLogger.info('🔵 Decrypted content: "${decryptedData['content']}"');
                
                // Create decrypted message
                lastMessage = message.copyWith(
                  content: decryptedData['content'] as String? ?? '[Decryption Error]',
                  isEncrypted: false,
                  encryptedContent: null,
                  encryptionMetadata: null,
                );
                AppLogger.info('🔵 Message decrypted successfully from conversation_updated: "${lastMessage.content}"');
              } catch (e) {
                AppLogger.error('❌ Failed to decrypt message from conversation_updated: $e');
                AppLogger.error('❌ Error stack trace: ${StackTrace.current}');
                lastMessage = message.copyWith(content: '[Encrypted Message]');
              }
            } else {
              AppLogger.info('🔵 Message not encrypted or no encrypted content available in conversation_updated');
              lastMessage = message.copyWith(
                isEncrypted: false,
                encryptedContent: null,
                encryptionMetadata: null,
              );
            }
          }
          
          // Create updated conversation
          final updatedConversation = conversation.copyWith(
            unreadCount: data['unreadCount'] ?? conversation.unreadCount,
            lastMessage: lastMessage ?? conversation.lastMessage,
            lastMessageTime: data['lastMessageTime'] != null ? DateTime.parse(data['lastMessageTime']) : conversation.lastMessageTime,
            updatedAt: DateTime.now(),
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.participantId == conversation?.participantId ? updatedConversation : c
          ).toList();
          
          // Sort conversations by last message time (newest first)
          updatedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          // Emit updated state immediately
          _inboxBloc?.add(InboxUpdated(conversations: updatedConversations));
          
          
          // Invalidate cache since conversation was updated
          if (_currentUser != null) {
            final apiCacheService = ApiCacheService();
            apiCacheService.invalidateCache('unified_conversations_${_currentUser!.id}');
            AppLogger.info('🔵 Unified cache invalidated due to conversation update');
          }
          
          AppLogger.info('🔵 Updated unread count: ${updatedConversation.unreadCount}');
        } else {
          AppLogger.info('🔵 Conversation not found for participant ID: ${data['_id']}');
          AppLogger.info('🔵 Available conversations: ${conversations.map((c) => c.participantId).toList()}');
        }
      }
    };
    _socketService!.on('conversation_updated', _conversationUpdatedListener!);

    _conversationRemovedListener = (data) {
      AppLogger.info('🔍 Debugging received event: conversation_removed - Data: $data');
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        
        // Extract user IDs from the event
        final sender = data['sender'] as String?;
        final receiver = data['receiver'] as String?;
        
        AppLogger.info('🔵 Unmatch event - Sender: $sender, Receiver: $receiver, Current user: ${_currentUser?.id}');
        
        // Determine which conversation to remove based on current user
        String? conversationToRemove;
        if (_currentUser?.id == sender) {
          // Current user initiated the unmatch, remove the receiver's conversation
          conversationToRemove = receiver;
        } else if (_currentUser?.id == receiver) {
          // Current user was unmatched, remove the sender's conversation
          conversationToRemove = sender;
        }
        
        if (conversationToRemove != null) {
          AppLogger.info('🔵 Removing conversation with user: $conversationToRemove');
          
          // Remove the conversation from the list
          final updatedConversations = conversations.where((c) => c.id != conversationToRemove).toList();
          
          // Emit updated state immediately
          _inboxBloc?.add(InboxUpdated(conversations: updatedConversations));
          
          AppLogger.info('🔵 Conversation removed successfully. Remaining conversations: ${updatedConversations.length}');
          
          // Show feedback to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Conversation ended'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    };
    _socketService!.on('conversation_removed', _conversationRemovedListener!);

    // Add online status event listeners
    AppLogger.info('🔵 Registering user_online listener');
    _userOnlineListener = (data) {
      AppLogger.info('🟢 User came online in inbox: $data');
      AppLogger.info('🟢 Current inbox state: ${_inboxBloc?.state.runtimeType}');
      AppLogger.info('🟢 Available conversations: ${(_inboxBloc?.state as InboxLoaded?)?.conversations.length ?? 0}');
      
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final userId = data['userId'] as String?;
        
        AppLogger.info('🟢 Looking for user ID: $userId');
        AppLogger.info('🟢 Available conversation IDs: ${conversations.map((c) => c.id).toList()}');
        
        if (userId != null) {
          final conversation = conversations.where((c) => c.participantId == userId).firstOrNull;
          if (conversation != null) {
            AppLogger.info('🔵 Found conversation for: ${conversation.participantName}');
            AppLogger.info('🔵 Current online status: ${conversation.isOnline}');
            
            // Create updated conversation with online status
            final updatedConversation = conversation.copyWith(
              isOnline: true,
              updatedAt: DateTime.now(),
            );
            
            AppLogger.info('🔵 New online status: ${updatedConversation.isOnline}');
            
            // Update the conversations list
            final updatedConversations = conversations.map((c) => 
              c.participantId == conversation?.participantId ? updatedConversation : c
            ).toList();
            
            // Emit updated state immediately
            _inboxBloc?.add(InboxUpdated(conversations: updatedConversations));
            
            AppLogger.info('🔵 Updated online status for: ${conversation.participantName}');
            AppLogger.info('🔵 State emitted successfully');
          } else {
            AppLogger.warning('⚠️ No conversation found for user ID: $userId');
          }
        } else {
          AppLogger.warning('⚠️ User ID is null in user_online event');
        }
      } else {
        AppLogger.warning('⚠️ Inbox state is not InboxLoaded: ${_inboxBloc?.state.runtimeType}');
      }
    };
    _socketService!.on('user_online', _userOnlineListener!);

    AppLogger.info('🔵 Registering user_offline listener');
    _userOfflineListener = (data) {
      AppLogger.info('🔴 User went offline in inbox: $data');
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final userId = data['userId'] as String?;
        
        if (userId != null) {
          final conversation = conversations.where((c) => c.participantId == userId).firstOrNull;
          if (conversation != null) {
            AppLogger.info('🔵 Updating offline status for: ${conversation.participantName}');
            
            // Create updated conversation with offline status
            final updatedConversation = conversation.copyWith(
              isOnline: false,
              updatedAt: DateTime.now(),
            );
            
            // Update the conversations list
            final updatedConversations = conversations.map((c) => 
              c.participantId == conversation?.participantId ? updatedConversation : c
            ).toList();
            
            // Emit updated state immediately
            _inboxBloc?.add(InboxUpdated(conversations: updatedConversations));
            
            AppLogger.info('🔵 Updated offline status for: ${conversation.participantName}');
          }
        }
      }
    };
    _socketService!.on('user_offline', _userOfflineListener!);

    // Listen for game_invite events via direct socket listener
    _socketService!.on('game_invite', (data) {
      AppLogger.info('🎮 Game invite received in inbox via direct socket listener: $data');
      
      final eventConversationId = data['conversationId'] as String?;
      final gameType = data['gameType'] as String?;
      
      if (eventConversationId != null && gameType != null) {
        // Update conversation to show game invite
        if (_inboxBloc?.state is InboxLoaded) {
          final currentState = _inboxBloc?.state as InboxLoaded;
          final conversations = currentState.conversations;
          
          // Try to match by constructed conversation ID
          Conversation? conversation;
          conversation = conversations.where((c) {
            final userIds = [_currentUser?.id ?? '', c.participantId];
            userIds.sort();
            final sortedConversationId = '${userIds[0]}_${userIds[1]}';
            return sortedConversationId == eventConversationId;
          }).firstOrNull;
          
          if (conversation != null) {
            // Create a game invite from the event data
            final gameInvite = GameInvite(
              gameType: gameType,
              fromUserId: data['fromUserId'] as String? ?? data['from'] as String? ?? '',
              fromUserName: data['fromUserName'] as String?,
              status: GameInviteStatus.pending,
              createdAt: DateTime.now(),
            );
            
            final updatedConversation = conversation.copyWith(
              pendingGameInvite: gameInvite,
              updatedAt: DateTime.now(),
            );
            
            final updatedConversations = conversations.map((c) => 
              c.participantId == conversation?.participantId ? updatedConversation : c
            ).toList();
            
            _inboxBloc?.add(InboxUpdated(conversations: updatedConversations));
          }
        }
      }
    });

    _errorListener = (data) {
      AppLogger.error('❌ Socket error in inbox: $data');
    };
    _socketService!.on('error', _errorListener!);
  }

  void _onGameInviteTap(Conversation conversation) {
    // Navigate to chat page with the game invite
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversation.participantId,
          participantName: conversation.participantName,
          participantAvatar: conversation.participantAvatar,
          isOnline: conversation.isOnline,
          lastSeen: conversation.lastSeen,
          connectionStatus: conversation.connectionStatus,
        ),
      ),
    );
  }

  void _onConversationTap(Conversation conversation) async {
    // Mark messages as read when opening the conversation
    if (conversation.unreadCount > 0) {
      _inboxBloc?.add(MarkConversationAsRead(conversation.id));
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversation.participantId, // ✅ FIXED: Use participantId (other user's ID)
          participantName: conversation.participantName,
          participantAvatar: conversation.participantAvatar,
          isOnline: conversation.isOnline,
          lastSeen: conversation.lastSeen,
          connectionStatus: conversation.connectionStatus,
        ),
      ),
    );

    // Refresh conversations when returning from chat page
    if (mounted) {
      AppLogger.info('🔵 Returning from chat page, refreshing conversations');
      _inboxBloc?.add(RefreshInbox());
      
      // Also reconnect socket and rejoin rooms
      await _reconnectSocket();
    }
  }

  // REMOVED: _formatOnlineStatus method - not being used

  String _formatTimestamp(DateTime timestamp) {
    // Convert UTC timestamp to local time (like chat page does)
    final localTimestamp = timestamp.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localTimestamp.year, localTimestamp.month, localTimestamp.day);

    if (messageDate == today) {
      // Use 24-hour format to match chat page format
      return DateFormat('HH:mm').format(localTimestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(localTimestamp).inDays < 7) {
      return DateFormat('EEEE').format(localTimestamp);
    } else {
      return DateFormat('MMM d').format(localTimestamp);
    }
  }

  Widget _buildAvatar(Conversation conversation) {
    AppLogger.info('🔵 Building avatar for ${conversation.participantName}: isOnline = ${conversation.isOnline}');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileViewPage(userId: conversation.participantId),
          ),
        );
      },
      child: CustomAvatar(
        name: conversation.participantName,
        size: 46,
        isOnline: conversation.isOnline,
      ),
    );
  }

  String _getMessageDisplayText(Message message, bool isMe) {
    String displayText;
    
    if (message.type == MessageType.image) {
      displayText = '📷 Photo';
    } else if (message.type == MessageType.voice) {
      displayText = '🎤 Voice message';
    } else if (message.type == MessageType.file) {
      displayText = '📎 File';
    } else {
      displayText = message.content;
    }
    
    // Add "You:" prefix for messages sent by current user
    if (isMe) {
      displayText = 'You: $displayText';
    }
    
    return displayText;
  }

  // Helper function to convert message type string to enum
  MessageType _getMessageTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCurrentUser) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_initializationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_initializationError', textAlign: TextAlign.center),
        ),
      );
    }

    if (_inboxBloc == null) {
      // This case should ideally not be hit if _loadCurrentUserAndInitBloc completes
      return const Center(child: Text('Bloc not initialized.'));
    }

    return Stack(
      children: [
        Container(
          color: const Color(0xFF234481),
      child: BlocProvider.value(
        value: _inboxBloc!,
        child: BlocBuilder<InboxBloc, InboxState>(
          builder: (context, state) {
            if (state is InboxLoading || state is InboxInitial) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }
            if (state is InboxError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load conversations: ${state.message}', textAlign: TextAlign.center),
              ));
            }
            if (state is InboxLoaded) {
              AppLogger.info('🔵 BlocBuilder: Rebuilding UI with ${state.conversations.length} conversations');
              // Join conversation rooms for each conversation to receive events
              if (_socketService != null && _socketService!.isConnected) {
                for (final conversation in state.conversations) {
                  // Room management removed - using direct socket listeners with filtering
                  AppLogger.info('🔵 Room management removed - using direct socket listeners with filtering');
                }
              }

              if (state.conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No conversations yet', style: TextStyle(fontSize: (MediaQuery.of(context).size.width * 0.05).clamp(18.0, 22.0), fontWeight: FontWeight.w500, color: Colors.white, fontFamily: 'Nunito')),
                      const SizedBox(height: 8),
                      Text('When you match with someone, you can start chatting here', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                );
              }
              
              // Adaptive padding for different screen sizes
              final isTablet = MediaQuery.of(context).size.width > 600;
              final listPadding = isTablet ? const EdgeInsets.only(top: 16.0, left: 32.0, right: 32.0) : const EdgeInsets.only(top: 16.0);
              
              return RefreshIndicator(
                onRefresh: () async {
                  AppLogger.info('🔵 Pull to refresh triggered');
                  _inboxBloc?.add(RefreshInbox());
                },
                child: ListView.builder(
                  padding: listPadding,
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    final hasUnread = conversation.unreadCount > 0;
                    final lastMessage = conversation.lastMessage;
                    final isMe = lastMessage?.sender == _currentUser?.id;
                    
                    AppLogger.info('🔵 UI: Building conversation for ${conversation.participantName}');
                    AppLogger.info('🔵 UI: Last message content: ${lastMessage?.content}');
                    AppLogger.info('🔵 UI: Unread count: ${conversation.unreadCount}');

                    return Column(
                      children: [
                        ListTile(
                        onTap: () => _onConversationTap(conversation),
                        leading: _buildAvatar(conversation),
                        title: Text(
                          conversation.participantName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                            fontSize: isTablet ? 18.0 : null,
                          ),
                        ),
                        subtitle: conversation.isTyping == true
                            ? Text(
                                'typing...',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[400],
                                  fontSize: isTablet ? 16.0 : null,
                                ),
                              )
                            : lastMessage != null
                                ? Text(
                                    _getMessageDisplayText(lastMessage, isMe),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: hasUnread ? Colors.white : Colors.grey[400],
                                      fontSize: isTablet ? 16.0 : null,
                                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  )
                                : Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: isTablet ? 16.0 : null,
                                    ),
                                  ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (conversation.pendingGameInvite != null) ...[
                              GameInviteIndicator(
                                gameInvite: conversation.pendingGameInvite!,
                                onTap: () => _onGameInviteTap(conversation),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              _formatTimestamp(conversation.lastMessageTime),
                              style: TextStyle(
                                color: hasUnread ? Colors.white : Colors.grey[400],
                                fontSize: isTablet ? 14.0 : (MediaQuery.of(context).size.width * 0.025).clamp(10.0, 12.0),
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                        ),
                        // Add separator between conversations
                        if (index < state.conversations.length - 1)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.white.withOpacity(0.1),
                            indent: 80, // Align with avatar
                          ),
                      ],
                    );
                  },
                ),
              );
            }
            return const Center(child: Text('Something went wrong.')); // Fallback for unhandled state
          },
        ),
          ),
        ),
        
        // Messaging tutorial overlay
        if (_showMessagingTutorial)
          MessagingTutorialOverlay(
            onComplete: () {
              setState(() {
                _showMessagingTutorial = false;
              });
            },
            onSkip: () {
              setState(() {
                _showMessagingTutorial = false;
              });
            },
          ),
      ],
    );
  }
} 