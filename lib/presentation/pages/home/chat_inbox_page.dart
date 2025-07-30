import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/presentation/bloc/inbox/inbox_bloc.dart';
import 'package:nookly/presentation/pages/chat/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    _loadCurrentUserAndInitBloc();
    _initSocket();
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
    await _initSocket();
    if (_socketService?.isConnected == true && _inboxBloc?.state is InboxLoaded) {
      _joinAllChatRooms();
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

  Future<void> _loadCurrentUserAndInitBloc() async {
    try {
      final authRepository = sl<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      if (mounted) {
        if (user != null) {
          setState(() {
            _currentUser = user;
            _inboxBloc = sl<InboxBloc>(param1: _currentUser!.id);
            _inboxBloc!.add(LoadInbox());
            _isLoadingCurrentUser = false;
          });
        } else {
          setState(() {
            _initializationError = 'Failed to load user. Please try again.';
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

  Future<void> _initSocket() async {
    final authRepository = sl<AuthRepository>();
    final user = await authRepository.getCurrentUser();
    final token = await authRepository.getToken();
    if (user != null && token != null) {
      _socketService = sl<SocketService>();
      _socketService!.connect(
        serverUrl: SocketService.socketUrl, 
        token: token,
        userId: user.id,
      );
      _registerSocketListeners();
      _joinAllChatRooms();
    }
  }

  void _registerSocketListeners() {
    if (_socketService == null) return;
    
    _socketService!.on('private_message', (data) {
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
          );
          
          // Create updated conversation with incremented unread count and new last message
          final updatedConversation = conversation.copyWith(
            unreadCount: conversation.unreadCount + 1,
            lastMessage: message,
            lastMessageTime: message.timestamp,
            updatedAt: DateTime.now(),
            messages: [message, ...conversation.messages], // Add new message to the beginning of the list
          );
          
          // Update the conversations list
          final updatedConversations = conversations.map((c) => 
            c.id == conversation.id ? updatedConversation : c
          ).toList();
          
          // Sort conversations by last message time (newest first)
          updatedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          // Emit updated state immediately
          _inboxBloc?.emit(InboxLoaded(updatedConversations));
          
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