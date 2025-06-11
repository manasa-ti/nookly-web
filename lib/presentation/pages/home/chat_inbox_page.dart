import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/core/di/injection_container.dart';
import 'package:hushmate/core/network/network_service.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/presentation/bloc/inbox/inbox_bloc.dart';
import 'package:hushmate/presentation/pages/chat/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:hushmate/core/network/socket_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hushmate/core/utils/logger.dart';
import 'package:hushmate/domain/entities/message.dart';

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
          
          // Create message from socket data
          final message = Message(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            sender: data['sender'] ?? '',
            receiver: data['receiver'] ?? '',
            content: data['content'] ?? '',
            timestamp: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
            type: MessageType.text,
            status: data['status'] ?? 'sent',
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

    // Reconnect socket and rejoin rooms when returning from chat page
    if (mounted) {
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
    final avatarUrl = conversation.participantAvatar;
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Icon(Icons.person, color: Colors.grey[600], size: 40)
                : (avatarUrl.toLowerCase().contains('dicebear') || avatarUrl.toLowerCase().endsWith('.svg'))
                    ? SvgPicture.network(
                        avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        // Optionally add errorBuilder if your flutter_svg version supports it
                      )
                    : Image.network(
                        avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, color: Colors.grey[600], size: 40);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
          ),
        ),
        if (conversation.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCurrentUser) {
      return const Center(child: CircularProgressIndicator());
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

    return BlocProvider.value(
      value: _inboxBloc!,
      child: BlocBuilder<InboxBloc, InboxState>(
        builder: (context, state) {
          if (state is InboxLoading || state is InboxInitial) {
            return const Center(child: CircularProgressIndicator());
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
                    Text('No conversations yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('When you match with someone, you can start chatting here', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                final hasUnread = conversation.unreadCount > 0;
                final lastMessage = conversation.messages.isNotEmpty ? conversation.messages.first : null;
                final isMe = lastMessage?.sender == _currentUser?.id;

                return ListTile(
                  onTap: () => _onConversationTap(conversation),
                  leading: _buildAvatar(conversation),
                  title: Text(conversation.participantName),
                  subtitle: conversation.isTyping == true
                      ? const Text(
                          'typing...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        )
                      : lastMessage != null
                          ? Text(
                              isMe ? 'You: ${lastMessage.content}' : lastMessage.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const Text('No messages yet'),
                  trailing: Text(
                    _formatTimestamp(conversation.lastMessageTime),
                    style: TextStyle(
                      color: hasUnread ? Colors.black : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Something went wrong.')); // Fallback for unhandled state
        },
      ),
    );
  }
} 