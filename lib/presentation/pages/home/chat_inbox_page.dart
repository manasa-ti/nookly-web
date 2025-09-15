import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/bloc/inbox/inbox_bloc.dart';
import 'package:nookly/presentation/pages/chat/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/services/api_cache_service.dart';
import 'package:nookly/core/services/user_cache_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> with WidgetsBindingObserver {
  InboxBloc? _inboxBloc;
  User? _currentUser;
  bool _isLoadingCurrentUser = true;
  String? _initializationError;
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChatInbox();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leaveAllChatRooms();
    _inboxBloc?.close();
    if (_socketService != null) {
      _socketService!.off('private_message');
      _socketService!.off('typing');
      _socketService!.off('stop_typing');
      _socketService!.off('conversation_updated');
      _socketService!.off('conversation_removed');
      _socketService!.off('error');
    }
    _socketService?.disconnect();
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
    if (_socketService != null && _socketService!.isConnected) {
      final state = _inboxBloc?.state;
      if (state is InboxLoaded) {
        for (final conversation in state.conversations) {
          AppLogger.info('Leaving private chat room for conversation with: ${conversation.participantId}');
          _socketService!.leavePrivateChat(conversation.participantId);
        }
      }
    }
  }

  void _joinAllChatRooms() {
    if (_socketService != null && _socketService!.isConnected) {
      final state = _inboxBloc?.state;
      if (state is InboxLoaded) {
        for (final conversation in state.conversations) {
          AppLogger.info('Joining private chat room for conversation with: ${conversation.participantId}');
          _socketService!.joinPrivateChat(conversation.participantId);
        }
      }
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
    
    _socketService = sl<SocketService>();
    _socketService!.connect(
      serverUrl: SocketService.socketUrl, 
      token: token,
      userId: user.id,
    );
    _registerSocketListeners();
    _joinAllChatRooms();
    
    socketStopwatch.stop();
    AppLogger.info('🔵 ChatInboxPage: Socket initialization completed in ${socketStopwatch.elapsedMilliseconds}ms');
  }

  void _registerSocketListeners() {
    if (_socketService == null) return;
    
    AppLogger.info('🔵 Registering socket listeners for chat inbox');
    
    _socketService!.on('private_message', (data) async {
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final conversation = conversations.where((c) => c.id == data['sender']).firstOrNull;
        
        if (conversation != null) {
          AppLogger.info('🔵 Processing new message in inbox from: ${conversation.participantName}');
          AppLogger.info('🔵 Current unread count: ${conversation.unreadCount}');
          AppLogger.info('🔵 Message data: $data');
          
          // Determine message type from socket data
          MessageType messageType = MessageType.text;
          if (data['messageType'] == 'image') {
            messageType = MessageType.image;
          } else if (data['messageType'] == 'voice') {
            messageType = MessageType.voice;
          } else if (data['messageType'] == 'file') {
            messageType = MessageType.file;
          }
          
          // Create message from socket data with proper type
          final message = Message(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            sender: data['sender'] ?? '',
            receiver: data['receiver'] ?? '',
            content: data['content'] ?? '',
            timestamp: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
            type: messageType, // ✅ Use proper message type
            status: data['status'] ?? 'sent',
            isDisappearing: messageType == MessageType.image ? (data['isDisappearing'] ?? false) : false,
            disappearingTime: messageType == MessageType.image ? data['disappearingTime'] : null,
            metadata: {
              if (data['isDisappearing'] != null && messageType == MessageType.image) 'isDisappearing': data['isDisappearing'].toString(),
              if (data['viewedAt'] != null) 'viewedAt': data['viewedAt'].toString(),
            },
            // Add encryption fields if present
            isEncrypted: data['encryptedContent'] != null,
            encryptedContent: data['encryptedContent'],
            encryptionMetadata: data['encryptionMetadata'],
          );
          
          // Decrypt message if it's encrypted
          Message decryptedMessage = message;
          if (message.isEncrypted && message.encryptionMetadata != null) {
            AppLogger.info('🔵 Decrypting new message in inbox from: ${conversation.participantName}');
            AppLogger.info('🔵 Message content before decryption: ${message.content}');
            AppLogger.info('🔵 Encrypted content to decrypt: ${message.encryptedContent}');
            try {
              // Get socket service to decrypt the message
              final socketService = sl<SocketService>();
              final decryptedData = await socketService.decryptMessage(data, data['sender'] ?? '');
              decryptedMessage = Message(
                id: message.id,
                sender: message.sender,
                receiver: message.receiver,
                content: decryptedData['content'] ?? message.content,
                timestamp: message.timestamp,
                type: message.type,
                status: message.status,
                isDisappearing: message.isDisappearing,
                disappearingTime: message.disappearingTime,
                metadata: message.metadata,
                isEncrypted: false, // Mark as decrypted
              );
              AppLogger.info('🔵 Message content after decryption: ${decryptedMessage.content}');
            } catch (e) {
              AppLogger.error('❌ Failed to decrypt message in inbox: $e');
              // Keep original message with decryption error
              decryptedMessage = message.copyWith(
                content: '[DECRYPTION FAILED]',
                decryptionError: true,
              );
            }
          }
          
          // Create updated conversation with incremented unread count and new last message
          final updatedConversation = conversation.copyWith(
            unreadCount: conversation.unreadCount + 1,
            lastMessage: decryptedMessage,
            lastMessageTime: decryptedMessage.timestamp,
            updatedAt: DateTime.now(),
            messages: [decryptedMessage, ...conversation.messages], // Add new message to the beginning of the list
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.id == conversation.id ? updatedConversation : c
          ).toList();
          
          // Sort conversations by last message time (newest first)
          updatedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          // Emit updated state immediately
          _inboxBloc?.emit(InboxLoaded(updatedConversations));
          
          // Invalidate cache since we have new message data
          if (_currentUser != null) {
            final apiCacheService = ApiCacheService();
            apiCacheService.invalidateCache('unified_conversations_${_currentUser!.id}');
            AppLogger.info('🔵 Unified cache invalidated due to new message received');
          }
          
          AppLogger.info('🔵 Updated unread count: ${updatedConversation.unreadCount}');
          AppLogger.info('🔵 Updated last message: ${updatedConversation.lastMessage?.content}');
          AppLogger.info('🔵 Message type: ${updatedConversation.lastMessage?.type}');
        }
      }
    });

    // Add typing indicator listeners
    _socketService!.on('typing', (data) {
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final conversation = conversations.where((c) => c.id == data['from']).firstOrNull;
        AppLogger.info('conversations on event typing: $conversations');
        if (conversation != null) {
          AppLogger.info('🔵 User is typing: ${conversation.participantName}');
          
          // Create updated conversation with typing status
          final updatedConversation = conversation.copyWith(
            isTyping: true,
            updatedAt: DateTime.now(),
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.id == conversation.id ? updatedConversation : c
          ).toList();
          
          // Emit updated state immediately
          _inboxBloc?.emit(InboxLoaded(updatedConversations));
        }
      }
    });

    _socketService!.on('stop_typing', (data) {
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final conversation = conversations.where((c) => c.id == data['from']).firstOrNull;
        AppLogger.info('conversations on event stop typing: $conversations');
        if (conversation != null) {
          AppLogger.info('🔵 User stopped typing: ${conversation.participantName}');
          
          // Create updated conversation with typing status
          final updatedConversation = conversation.copyWith(
            isTyping: false,
            updatedAt: DateTime.now(),
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.id == conversation.id ? updatedConversation : c
          ).toList();
          
          // Emit updated state immediately
          _inboxBloc?.emit(InboxLoaded(updatedConversations));
        }
      }
    });

    _socketService!.on('conversation_updated', (data) {
      AppLogger.info('🔵 Conversation updated event received: $data');
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final conversation = conversations.where((c) => c.id == data['conversationId']).firstOrNull;
        
        if (conversation != null) {
          AppLogger.info('🔵 Updating conversation: ${conversation.participantName}');
          AppLogger.info('🔵 Current unread count: ${conversation.unreadCount}');
          
          // Create updated conversation
          final updatedConversation = conversation.copyWith(
            unreadCount: data['unreadCount'] ?? conversation.unreadCount,
            lastMessage: data['lastMessage'] != null ? Message.fromJson(data['lastMessage']) : conversation.lastMessage,
            lastMessageTime: data['lastMessageTime'] != null ? DateTime.parse(data['lastMessageTime']) : conversation.lastMessageTime,
            updatedAt: DateTime.now(),
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.id == conversation.id ? updatedConversation : c
          ).toList();
          
          // Sort conversations by last message time (newest first)
          updatedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          // Emit updated state immediately
          _inboxBloc?.emit(InboxLoaded(updatedConversations));
          
          // Invalidate cache since conversation was updated
          if (_currentUser != null) {
            final apiCacheService = ApiCacheService();
            apiCacheService.invalidateCache('unified_conversations_${_currentUser!.id}');
            AppLogger.info('🔵 Unified cache invalidated due to conversation update');
          }
          
          AppLogger.info('🔵 Updated unread count: ${updatedConversation.unreadCount}');
        }
      }
    });

    _socketService!.on('conversation_removed', (data) {
      AppLogger.info('🔵 Conversation removed event received: $data');
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
          _inboxBloc?.emit(InboxLoaded(updatedConversations));
          
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
    });

    // Add online status event listeners
    AppLogger.info('🔵 Registering user_online listener');
    _socketService!.on('user_online', (data) {
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
          final conversation = conversations.where((c) => c.id == userId).firstOrNull;
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
              c.id == conversation.id ? updatedConversation : c
            ).toList();
            
            // Emit updated state immediately
            _inboxBloc?.emit(InboxLoaded(updatedConversations));
            
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
    });

    AppLogger.info('🔵 Registering user_offline listener');
    _socketService!.on('user_offline', (data) {
      AppLogger.info('🔴 User went offline in inbox: $data');
      if (_inboxBloc?.state is InboxLoaded) {
        final currentState = _inboxBloc?.state as InboxLoaded;
        final conversations = currentState.conversations;
        final userId = data['userId'] as String?;
        
        if (userId != null) {
          final conversation = conversations.where((c) => c.id == userId).firstOrNull;
          if (conversation != null) {
            AppLogger.info('🔵 Updating offline status for: ${conversation.participantName}');
            
            // Create updated conversation with offline status
            final updatedConversation = conversation.copyWith(
              isOnline: false,
              updatedAt: DateTime.now(),
            );
            
            // Update the conversations list
            final updatedConversations = conversations.map((c) => 
              c.id == conversation.id ? updatedConversation : c
            ).toList();
            
            // Emit updated state immediately
            _inboxBloc?.emit(InboxLoaded(updatedConversations));
            
            AppLogger.info('🔵 Updated offline status for: ${conversation.participantName}');
          }
        }
      }
    });

    _socketService!.on('error', (data) {
      AppLogger.error('❌ Socket error in inbox: $data');
    });
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
          conversationId: conversation.id,
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

  String _formatOnlineStatus(Conversation conversation) {
    if (conversation.isOnline) {
      return 'Online';
    } else if (conversation.lastSeen != null) {
      try {
        final lastSeenDate = DateTime.parse(conversation.lastSeen!);
        final now = DateTime.now();
        final difference = now.difference(lastSeenDate);
        
        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inMinutes < 60) {
          return '${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          return '${difference.inHours}h ago';
        } else if (difference.inDays < 7) {
          return '${difference.inDays}d ago';
        } else {
          return 'Last seen ${lastSeenDate.day}/${lastSeenDate.month}';
        }
      } catch (e) {
        return 'Offline';
      }
    } else {
      return 'Offline';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  Widget _buildAvatar(Conversation conversation) {
    print('🔵 Building avatar for ${conversation.participantName}: isOnline = ${conversation.isOnline}');
    return CustomAvatar(
      name: conversation.participantName,
      size: 46,
      isOnline: conversation.isOnline,
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

    return Container(
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
              // Join private chat rooms for each conversation
              if (_socketService != null && _socketService!.isConnected) {
                for (final conversation in state.conversations) {
                  AppLogger.info('Joining private chat room for conversation with: ${conversation.participantId}');
                  _socketService!.joinPrivateChat(conversation.participantId);
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
                    final lastMessage = conversation.messages.isNotEmpty ? conversation.messages.first : null;
                    final isMe = lastMessage?.sender == _currentUser?.id;

                    return Column(
                      children: [
                        ListTile(
                        onTap: () => _onConversationTap(conversation),
                        leading: _buildAvatar(conversation),
                        title: Text(
                          conversation.participantName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
                                    _getMessageDisplayText(lastMessage!, isMe),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 16.0 : null,
                                    ),
                                  )
                                : Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: isTablet ? 16.0 : null,
                                    ),
                                  ),
                        trailing: Text(
                          _formatTimestamp(conversation.lastMessageTime),
                          style: TextStyle(
                            color: hasUnread ? Colors.white : Colors.grey[400],
                            fontSize: isTablet ? 14.0 : (MediaQuery.of(context).size.width * 0.025).clamp(10.0, 12.0),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            fontFamily: 'Nunito',
                          ),
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
    );
  }
} 