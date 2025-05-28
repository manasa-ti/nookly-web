import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:hushmate/presentation/widgets/message_bubble.dart';
import 'package:hushmate/core/network/socket_service.dart';
import 'package:hushmate/core/network/network_service.dart';
import 'package:hushmate/core/di/injection_container.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/core/utils/logger.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String participantName;
  final String? participantAvatar;
  final bool isOnline;

  const ChatPage({
    Key? key,
    required this.conversationId,
    required this.participantName,
    this.participantAvatar,
    required this.isOnline,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachingFile = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 20;
  
  // Animation controller for the side menu
  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;
  bool _isMenuOpen = false;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  String? _currentUserId;
  String? _jwtToken;
  SocketService? _socketService;

  @override
  void initState() {
    super.initState();
    _initSocketAndUser();
    // Load conversation when the page is initialized
    context.read<ConversationBloc>().add(LoadConversation(
      participantId: widget.conversationId,
      participantName: widget.participantName,
      participantAvatar: widget.participantAvatar,
      isOnline: widget.isOnline,
    ));
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Initialize menu animation controller
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _menuAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _menuAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // Remove all socket listeners before disposing
    if (_socketService != null) {
      _socketService!.off('private_message');
      _socketService!.off('private_message_sent');
      _socketService!.off('message_delivered');
      _socketService!.off('message_read');
      _socketService!.off('typing');
      _socketService!.off('stop_typing');
      _socketService!.off('message_edited');
      _socketService!.off('message_deleted');
      _socketService!.off('error');
      
      // Leave the private chat room
      _socketService!.leavePrivateChat(widget.conversationId);
    }
    _messageController.dispose();
    _scrollController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuAnimationController.forward();
      } else {
        _menuAnimationController.reverse();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    final state = context.read<ConversationBloc>().state;
    if (state is ConversationLoaded && state.hasMoreMessages) {
      setState(() {
        _isLoadingMore = true;
      });
      
      context.read<ConversationBloc>().add(LoadMoreMessages());
      
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Since messages are now in chronological order, 0 is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initSocketAndUser() async {
    AppLogger.info('🔵 Initializing socket and user for chat page');
    AppLogger.info('🔵 Other user ID: ${widget.conversationId}');
    
    final authRepository = sl<AuthRepository>();
    final user = await authRepository.getCurrentUser();
    final token = await authRepository.getToken();
    
    AppLogger.info('🔵 User data: ${user?.toJson()}');
    AppLogger.info('🔵 Token available: ${token != null}');
    
    if (user != null && token != null) {
      AppLogger.info('✅ User authenticated, initializing socket connection');
      _currentUserId = user.id;
      _jwtToken = token;
      _socketService = sl<SocketService>();
      
      // Update the ConversationBloc with the current user ID
      if (mounted) {
        context.read<ConversationBloc>().add(UpdateCurrentUserId(user.id));
      }
      
      AppLogger.info('🔵 Connecting to socket with URL: ${SocketService.socketUrl}');
      AppLogger.info('🔵 User ID: $_currentUserId');
      AppLogger.info('🔵 Token: ${token.substring(0, 10)}...');
      
      _socketService!.connect(
        serverUrl: SocketService.socketUrl, 
        token: token,
        userId: user.id,
      );
      
      // Add a small delay to ensure socket is connected
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_socketService!.isConnected) {
        AppLogger.info('✅ Socket connected successfully');
        AppLogger.info('🔵 Joining private chat room with user: ${widget.conversationId}');
        // Join the private chat room
        _socketService!.joinPrivateChat(widget.conversationId);
      } else {
        AppLogger.error('❌ Socket failed to connect');
      }
      
      _registerSocketListeners();
    } else {
      AppLogger.error('❌ Failed to initialize socket: User or token is null');
      AppLogger.error('❌ User: ${user?.toJson()}');
      AppLogger.error('❌ Token available: ${token != null}');
    }
  }

  void _registerSocketListeners() {
    if (_socketService == null) {
      AppLogger.error('❌ Cannot register socket listeners: SocketService is null');
      return;
    }

    AppLogger.info('🔵 Registering socket listeners for chat page');
    
    // Add listener for all events
    _socketService!.on('connect', (data) {
      AppLogger.info('✅ Socket connected');
    });
    
    _socketService!.on('disconnect', (data) {
      AppLogger.warning('⚠️ Socket disconnected');
    });
    
    _socketService!.on('error', (data) {
      AppLogger.error('❌ Socket error: $data');
    });
    
    _socketService!.on('private_message', (data) {
      if (!mounted) return;
      AppLogger.info('🔵 Socket Event: private_message received');
      AppLogger.info('🔵 Message data: ${data.toString()}');
      try {
        final msg = Message.fromJson({
          '_id': data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'sender': data['sender'] ?? data['from'],
          'receiver': data['receiver'] ?? data['to'],
          'content': data['content'] ?? '',
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          'messageType': data['messageType'] ?? 'text',
          'status': data['status'] ?? 'sent',
        });
        AppLogger.info('🔵 Parsed message: id=${msg.id}, sender=${msg.sender}, content=${msg.content}');
        
        // Only process messages from the other participant
        if (msg.sender == widget.conversationId) {
          AppLogger.info('✅ Processing received message from other user: ${msg.content}');
          context.read<ConversationBloc>().add(MessageReceived(msg));
          
          // Update conversation with new message
          context.read<ConversationBloc>().add(ConversationUpdated(
            conversationId: widget.conversationId,
            lastMessage: msg,
            updatedAt: DateTime.now(),
          ));
          
          // Scroll to bottom when receiving a new message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          AppLogger.warning('⚠️ Received message from unknown sender: ${msg.sender}, expected: ${widget.conversationId}');
        }
      } catch (e) {
        AppLogger.error('❌ Error processing message: $e');
      }
    });

    // Add typing indicator listeners
    _socketService!.on('typing', (data) {
      if (!mounted) return;
      if (data['userId'] == widget.conversationId) {
        setState(() {
          _otherUserTyping = true;
        });
        // Update conversation typing status
        context.read<ConversationBloc>().add(ConversationUpdated(
          conversationId: widget.conversationId,
          isTyping: true,
          updatedAt: DateTime.now(),
        ));
      }
    });

    _socketService!.on('stop_typing', (data) {
      if (!mounted) return;
      if (data['userId'] == widget.conversationId) {
        setState(() {
          _otherUserTyping = false;
        });
        // Update conversation typing status
        context.read<ConversationBloc>().add(ConversationUpdated(
          conversationId: widget.conversationId,
          isTyping: false,
          updatedAt: DateTime.now(),
        ));
      }
    });

    // Add message status listeners
    _socketService!.on('message_delivered', (data) {
      if (!mounted) return;
      final messageId = data['messageId'];
      final deliveredAt = DateTime.parse(data['deliveredAt']);
      context.read<ConversationBloc>().add(MessageDelivered(
        messageId,
        deliveredAt,
      ));
    });

    _socketService!.on('message_read', (data) {
      if (!mounted) return;
      final messageId = data['messageId'];
      final readAt = DateTime.parse(data['readAt']);
      context.read<ConversationBloc>().add(MessageRead(
        messageId,
        readAt,
      ));
    });
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) {
      AppLogger.warning('Attempted to send empty message');
      return;
    }

    final content = _messageController.text.trim();
    AppLogger.info('🔵 Sending text message: $content');
    _messageController.clear();

    if (_socketService != null && _currentUserId != null) {
      try {
        AppLogger.info('🔵 Current user ID: $_currentUserId');
        AppLogger.info('🔵 Recipient ID (conversationId): ${widget.conversationId}');
        
        // Create message data
        final messageData = {
          'from': _currentUserId,
          'to': widget.conversationId,
          'content': content,
          'messageType': 'text',
          'status': 'sent',
          'createdAt': DateTime.now().toIso8601String(),
        };

        AppLogger.info('🔵 Emitting private_message with data: $messageData');
        // Send message through socket
        _socketService!.emit('private_message', messageData);
        
        // Add message to local state immediately
        final msg = Message.fromJson(messageData);
        AppLogger.info('✅ Added message to local state: ${msg.content}');
        context.read<ConversationBloc>().add(MessageSent(msg));
        
        // Scroll to bottom after sending message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } catch (e) {
        AppLogger.error('❌ Failed to send message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } else {
      AppLogger.error('❌ Cannot send message: SocketService or currentUserId is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please try again.')),
      );
    }

    setState(() => _isTyping = false);
    _socketService?.emit('stop_typing', {'to': widget.conversationId});
  }

  Future<void> _pickImage() async {
    // In a real app, this would use image_picker
    // For now, we'll just send a mock image URL
    context.read<ConversationBloc>().add(
      SendImageMessage(conversationId: widget.conversationId, imagePath: 'https://example.com/mock_image.jpg'),
    );
    
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    // In a real app, this would use file_picker
    // For now, we'll just send a mock file
    setState(() {
      _isAttachingFile = true;
    });
    
    // Simulate file picking delay
    await Future.delayed(const Duration(seconds: 1));
    
    context.read<ConversationBloc>().add(
      SendFileMessage(
        conversationId: widget.conversationId,
        filePath: 'https://example.com/mock_file.pdf',
        fileName: 'document.pdf',
        fileSize: 1024 * 1024, // 1MB
      ),
    );
    
    setState(() {
      _isAttachingFile = false;
    });
    
    _scrollToBottom();
  }

  Future<void> _recordVoiceMessage() async {
    // In a real app, this would use record package
    // For now, we'll just send a mock voice message
    context.read<ConversationBloc>().add(
      SendVoiceMessage(
        conversationId: widget.conversationId,
        audioPath: 'https://example.com/mock_voice.m4a',
        duration: const Duration(seconds: 30), // 30 seconds
      ),
    );
    
    _scrollToBottom();
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Send Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Send File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Record Voice Message'),
                onTap: () {
                  Navigator.pop(context);
                  _recordVoiceMessage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _playVoiceMessage(Message message) {
    // TODO: Implement voice message playback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing voice message: ${message.content}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.participantName),
                if (_otherUserTyping)
                  const Text(
                    'typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _toggleMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocListener<ConversationBloc, ConversationState>(
              listener: (context, state) {
                if (state is ConversationLoaded) {
                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              },
              child: BlocBuilder<ConversationBloc, ConversationState>(
                builder: (context, state) {
                  if (state is ConversationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ConversationError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  if (state is ConversationLoaded) {
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: state.messages.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final message = state.messages[index];
                        final isMe = message.sender == _currentUserId;
                        
                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          showAvatar: false,
                          avatarUrl: widget.participantAvatar,
                          statusWidget: isMe ? _buildMessageStatus(message) : null,
                        );
                      },
                    );
                  }
                  return const Center(child: Text('No messages yet'));
                },
              ),
            ),
          ),
          _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showOptionsMenu,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (text) {
                  if (!_isTyping && text.isNotEmpty) {
                    setState(() => _isTyping = true);
                    _socketService?.emit('typing', {'to': widget.conversationId});
                  } else if (_isTyping && text.isEmpty) {
                    setState(() => _isTyping = false);
                    _socketService?.emit('stop_typing', {'to': widget.conversationId});
                  }
                },
                onEditingComplete: () {
                  setState(() => _isTyping = false);
                  _socketService?.emit('stop_typing', {'to': widget.conversationId});
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendTextMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMenu(Conversation conversation) {
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          bottom: 0,
          right: _menuAnimation.value * -300,
          width: 300,
          child: Material(
            elevation: 8,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Chat Options',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.card_giftcard),
                    title: const Text('Buy Gift'),
                    onTap: () {
                      // Handle buy gift
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.games),
                    title: const Text('Start Ice Breaker Game'),
                    onTap: () {
                      // Handle start game
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.casino),
                    title: const Text('Start Fantasy Game'),
                    onTap: () {
                      // Handle start fantasy game
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Plan a Date'),
                    onTap: () {
                      // Handle plan date
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.psychology),
                    title: const Text('Get Inference'),
                    onTap: () {
                      // Handle get inference
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Block User'),
                    onTap: () {
                      context.read<ConversationBloc>().add(
                        BlockUser(userId: conversation.participantId),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_off),
                    title: const Text('Mute Conversation'),
                    onTap: () {
                      context.read<ConversationBloc>().add(
                        MuteConversation(conversationId: widget.conversationId),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Leave Conversation'),
                    onTap: () {
                      context.read<ConversationBloc>().add(
                        LeaveConversation(conversationId: widget.conversationId),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add typing indicator to the UI
  Widget _buildTypingIndicator() {
    if (!_otherUserTyping) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            '${widget.participantName} is typing...',
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Add message status indicator
  Widget _buildMessageStatus(Message message) {
    if (message.sender != _currentUserId) return const SizedBox.shrink();
    
    Widget statusIcon;
    switch (message.status) {
      case 'sent':
        statusIcon = const Icon(Icons.check, size: 16, color: Colors.grey);
        break;
      case 'delivered':
        statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.grey);
        break;
      case 'read':
        statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.blue);
        break;
      default:
        statusIcon = const Icon(Icons.check, size: 16, color: Colors.grey);
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: statusIcon,
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: (widget.participantAvatar == null || widget.participantAvatar!.isEmpty)
                ? Icon(Icons.person, color: Colors.grey[600], size: 40)
                : (widget.participantAvatar!.toLowerCase().contains('dicebear') || widget.participantAvatar!.toLowerCase().endsWith('.svg'))
                    ? SvgPicture.network(
                        widget.participantAvatar!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Image.network(
                        widget.participantAvatar!,
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
        if (widget.isOnline)
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
} 