import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_event.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_state.dart';
import 'package:hushmate/presentation/widgets/message_bubble.dart';

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

  @override
  void initState() {
    super.initState();
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
    if (state is ConversationLoaded) {
      setState(() {
        _isLoadingMore = true;
      });
      
      // In a real app, this would load more messages from the repository
      // For now, we'll simulate loading more messages
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    context.read<ConversationBloc>().add(
      SendTextMessage(conversationId: widget.conversationId, content: content),
    );

    _scrollToBottom();
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
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (context, state) {
        if (state is ConversationLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ConversationError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${state.message}'),
            ),
          );
        }

        if (state is ConversationLoaded) {
          final conversation = state.conversation;
          final messages = state.messages;

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: conversation.participantAvatar != null
                        ? NetworkImage(conversation.participantAvatar!)
                        : null,
                    child: conversation.participantAvatar == null
                        ? Text(conversation.participantName[0])
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(conversation.participantName),
                      if (conversation.isOnline)
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
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
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final message = messages[index];
                          final isCurrentUser = message.senderId == 'currentUser';

                          return MessageBubble(
                            message: Message(
                              id: message.id,
                              senderId: message.senderId,
                              content: message.content,
                              timestamp: message.timestamp,
                              type: message.type,
                              metadata: message.metadata,
                            ),
                            isMe: isCurrentUser,
                            onTap: () {
                              if (message.type == MessageType.voice) {
                                _playVoiceMessage(message);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    _buildMessageInput(),
                  ],
                ),
                _buildSideMenu(conversation),
              ],
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: Text('Something went wrong'),
          ),
        );
      },
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
} 