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
import 'package:intl/intl.dart';
import 'package:hushmate/presentation/pages/call/call_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:hushmate/core/services/image_url_service.dart';

import 'package:hushmate/presentation/widgets/disappearing_time_selector.dart';
import 'package:hushmate/core/services/disappearing_image_manager.dart';

class DisappearingTimerNotifier extends ValueNotifier<int?> {
  DisappearingTimerNotifier(int initialValue) : super(initialValue);
  
  void updateTime(int newTime) {
    value = newTime;
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}



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
  final Set<String> _processedMessageIds = {}; // Track processed message IDs
  final Dio dio = Dio(); // Initialize Dio instance
  final ImagePicker _picker = ImagePicker();

  // Add state management for disappearing images
  late final DisappearingImageManager _disappearingImageManager;
  String? _currentlyOpenImageId; // Track which image is currently open in full-screen

  @override
  void initState() {
    super.initState();
    
    // Initialize DisappearingImageManager
    _disappearingImageManager = DisappearingImageManager(
      onImageExpired: _handleImageExpired,
    );
    
    _initSocketAndUser();
    // Load conversation when the page is initialized
    context.read<ConversationBloc>().add(LoadConversation(
      participantId: widget.conversationId,
      participantName: widget.participantName,
      participantAvatar: widget.participantAvatar,
      isOnline: widget.isOnline,
    ));
    
    // Initialize _processedMessageIds with existing messages
    final state = context.read<ConversationBloc>().state;
    if (state is ConversationLoaded) {
      for (final message in state.messages) {
        if (message.status == 'delivered') {
          _processedMessageIds.add(message.id);
        }
        if (message.status == 'read') {
          _processedMessageIds.add('${message.id}_read');
        }
      }
    }
    
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
    // Dispose DisappearingImageManager
    _disappearingImageManager.dispose();
    
    // Don't clear _processedMessageIds here anymore
    // _processedMessageIds.clear();
    
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
      _socketService!.off('conversation_removed');
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

  void _handleImageExpired(String messageId) {
    if (!mounted) return;
    AppLogger.info('🔵 DEBUGGING Disappearing Image: Handling disappearing image expired for message: $messageId');
    AppLogger.info('🔵 DEBUGGING Disappearing Image: Currently open image ID: $_currentlyOpenImageId');
    
    // Update message state
    AppLogger.info('🔵 DEBUGGING Disappearing Image: Sending MessageExpired event to bloc for message: $messageId');
    context.read<ConversationBloc>().add(MessageExpired(messageId));
    
    // Close full screen if open and it's the same image
    if (_currentlyOpenImageId == messageId) {
      AppLogger.info('🔵 DEBUGGING Disappearing Image: Closing full screen image dialog for image: $messageId');
      Navigator.of(context).pop();
      _currentlyOpenImageId = null;
    } else {
      AppLogger.info('🔵 DEBUGGING Disappearing Image: Not closing full screen - expired image ($messageId) is not the currently open image ($_currentlyOpenImageId)');
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
      AppLogger.info('🔵 Socket ID: ${_socketService!.socketId}');
      AppLogger.info('🔵 Current user ID: $_currentUserId');
      AppLogger.info('🔵 Conversation ID: ${widget.conversationId}');
    });
    
    _socketService!.on('disconnect', (data) {
      AppLogger.warning('⚠️ Socket disconnected');
      AppLogger.warning('⚠️ Disconnect reason: $data');
    });
    
    _socketService!.on('error', (data) {
      AppLogger.error('❌ Socket error: $data');
    });

    // Add listener for conversation removal (unmatch)
    _socketService!.on('conversation_removed', (data) {
      if (!mounted) return;
      AppLogger.info('🔵 Conversation removed event received in chat page: $data');
      
      // Extract user IDs from the event
      final sender = data['sender'] as String?;
      final receiver = data['receiver'] as String?;
      
      AppLogger.info('🔵 Unmatch event in chat - Sender: $sender, Receiver: $receiver, Current user: $_currentUserId');
      
      // Only navigate if current user is the receiver (not the sender)
      if (_currentUserId == receiver) {
        AppLogger.info('🔵 Current user is receiver, navigating back');
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation ended by the other user'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        AppLogger.info('🔵 Current user is sender, skipping navigation (already handled by bloc)');
      }
    });

    // Modify image_viewed event handler
    _socketService!.on('image_viewed', (data) {
      if (!mounted) return;
      AppLogger.info('🔵 Received image_viewed event: $data');
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Processing image_viewed event');
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Raw event data: $data');
      
      try {
        final messageId = data['messageId'];
        final viewedAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        final disappearingTime = data['disappearingTime'];
        final isDisappearing = data['isDisappearing'] ?? false;
        
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Parsed event data:');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Received messageId: $messageId');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Viewed at: $viewedAt');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Disappearing time: $disappearingTime');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Is disappearing: $isDisappearing');
        
        // Debug: Check if message exists in state when image_viewed is received
        final state = context.read<ConversationBloc>().state;
        if (state is ConversationLoaded) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Current state has ${state.messages.length} messages');
          
          // Log all messages in state for debugging
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: All messages in state:');
          for (final msg in state.messages) {
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: - ID: ${msg.id}, Type: ${msg.type}, Content: ${msg.content.substring(0, msg.content.length > 50 ? 50 : msg.content.length)}...');
          }
          
          final messageExists = state.messages.any((msg) => msg.id == messageId);
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message exists in state when image_viewed received: $messageExists');
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Looking for message with ID: $messageId');
          
          if (!messageExists) {
            AppLogger.warning('⚠️ DEBUGGING MESSAGE ID: Message not found in state when image_viewed received!');
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: Available message IDs: ${state.messages.map((m) => m.id).join(', ')}');
            
            // Try to find the message by content (image URL) instead of ID
            final messageByContent = state.messages.where((msg) => 
                msg.type == MessageType.image && 
                msg.isDisappearing && 
                msg.disappearingTime == disappearingTime
            ).toList();
            
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found ${messageByContent.length} messages by content matching criteria');
            for (final msg in messageByContent) {
              AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Potential match: ID=${msg.id}, Content=${msg.content}');
            }
            
            if (messageByContent.isNotEmpty) {
              final localMessage = messageByContent.first;
              AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found message by content with local ID: ${localMessage.id}');
              AppLogger.info('🔵 DEBUGGING MESSAGE ID: Updating message ID from ${localMessage.id} to $messageId');
              
              // Update the message ID in the state
              context.read<ConversationBloc>().add(UpdateMessageId(
                oldMessageId: localMessage.id,
                newMessageId: messageId,
              ));
            } else {
              AppLogger.error('🔵 DEBUGGING MESSAGE ID: No matching message found by content either!');
            }
          } else {
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message found successfully in state');
          }
        } else {
          AppLogger.error('🔵 DEBUGGING MESSAGE ID: State is not ConversationLoaded: ${state.runtimeType}');
        }
        
        // Update the message state with viewed timestamp
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Dispatching MessageViewed event with ID: $messageId');
        context.read<ConversationBloc>().add(MessageViewed(
          messageId,
          viewedAt,
        ));

        // Start the disappearing timer (for sender only)
        if (isDisappearing && disappearingTime != null) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Starting sender timer for message: $messageId');
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Sender disappearing time: $disappearingTime seconds');
          _startDisappearingImageTimer(messageId, disappearingTime);
        }
        
        AppLogger.info('✅ Successfully processed image_viewed event');
        AppLogger.info('🔵 MessageBubble widgets will handle their own timers based on viewedAt metadata');
      } catch (e) {
        AppLogger.error('❌ Error processing image_viewed event: $e');
        AppLogger.error('🔵 DEBUGGING MESSAGE ID: Exception details: $e');
      }
    });

    // Add listener for room joining confirmation
    _socketService!.on('joined_room', (data) {
      AppLogger.info('✅ Joined room: $data');
      AppLogger.info('🔵 Room details: ${data.toString()}');
    });

    // Add listener for room joining error
    _socketService!.on('join_error', (data) {
      AppLogger.error('❌ Failed to join room: $data');
    });

    // Add bulk message status listeners
    _socketService!.on('bulk_message_delivered', (data) {
      if (!mounted) return;
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Received bulk_message_delivered event: $data');
      try {
        final messageIds = List<String>.from(data['messageIds'] ?? []);
        final deliveredAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Delivered at: $deliveredAt');
        
        if (messageIds.isNotEmpty) {
          AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Adding BulkMessageDelivered event to bloc');
          context.read<ConversationBloc>().add(BulkMessageDelivered(
            messageIds: messageIds,
            deliveredAt: deliveredAt,
          ));
          AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Successfully processed bulk_message_delivered event');
        }
      } catch (e) {
        AppLogger.error('❌ DEBUGGING MESSAGE DELIVERY: Error processing bulk_message_delivered event: $e');
      }
    });

    _socketService!.on('bulk_message_read', (data) {
      if (!mounted) return;
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Received bulk_message_read event: $data');
      try {
        final messageIds = List<String>.from(data['messageIds'] ?? []);
        final readAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Read at: $readAt');
        
        if (messageIds.isNotEmpty) {
          AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Adding BulkMessageRead event to bloc');
          context.read<ConversationBloc>().add(BulkMessageRead(
            messageIds: messageIds,
            readAt: readAt,
          ));
          AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Successfully processed bulk_message_read event');
        }
      } catch (e) {
        AppLogger.error('❌ DEBUGGING MESSAGE DELIVERY: Error processing message_read event: $e');
      }
    });

    // Debounce timer for typing events
    Timer? _typingDebounce;
    
    _socketService!.on('private_message', (data) {
      if (!mounted) return;
      AppLogger.info('debug disappearing: Received private_message event');
      AppLogger.info('debug disappearing: Message data: ${data.toString()}');
      AppLogger.info('🔵 DEBUGGING EXPIRATION: Full socket data received: $data');
      AppLogger.info('🔵 DEBUGGING EXPIRATION: Socket data type: ${data.runtimeType}');
      AppLogger.info('🔵 DEBUGGING EXPIRATION: Socket data keys: ${(data as Map<String, dynamic>).keys.toList()}');
      try {
        // Store the server's message ID
        final serverMessageId = data['_id']?.toString() ?? data['id']?.toString();
        AppLogger.info('debug disappearing: Server message ID: $serverMessageId');
        // Parse the server's timestamp
        final serverTimestamp = data['createdAt']?.toString() ?? data['timestamp']?.toString();
        AppLogger.info('debug disappearing: Server timestamp: $serverTimestamp');
        // Convert dynamic map to Map<String, dynamic>
        final Map<String, dynamic> messageData = {
          '_id': serverMessageId,
          'sender': data['sender']?.toString() ?? data['from']?.toString(),
          'receiver': data['receiver']?.toString() ?? data['to']?.toString(),
          'content': data['content']?.toString() ?? '',
          'createdAt': serverTimestamp, // Use server's timestamp
          'messageType': data['messageType']?.toString() ?? 'text',
          'status': data['status']?.toString() ?? 'sent',
          'isDisappearing': data['isDisappearing'],
          'disappearingTime': data['disappearingTime'],
        };
        
        // Handle metadata conversion properly
        if (data['metadata'] != null) {
          if (data['metadata'] is Map) {
            messageData['metadata'] = Map<String, dynamic>.from(data['metadata']);
          } else {
            // If metadata is not a Map, try to convert it
            AppLogger.warning('🔵 DEBUGGING SOCKET MESSAGE: Metadata is not a Map, type: ${data['metadata'].runtimeType}');
            messageData['metadata'] = {'raw': data['metadata'].toString()};
          }
        }
        AppLogger.info('debug disappearing: Constructed messageData: $messageData');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: Raw socket data structure');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - Raw isDisappearing: ${data['isDisappearing']}');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - Raw disappearingTime: ${data['disappearingTime']}');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - Raw metadata: ${data['metadata']}');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - Metadata type: ${data['metadata']?.runtimeType}');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - Metadata keys: ${(data['metadata'] as Map<String, dynamic>?)?.keys.toList()}');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - expiresAt in metadata: ${data['metadata']?['expiresAt']}');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - Final messageData metadata: ${messageData['metadata']}');
        AppLogger.info('🔵 DEBUGGING SOCKET MESSAGE: - Final messageData metadata type: ${messageData['metadata']?.runtimeType}');
        
        final msg = Message.fromJson(messageData);
        AppLogger.info('debug disappearing: Parsed message: id=${msg.id}, sender=${msg.sender}, content=${msg.content}, status=${msg.status}, timestamp=${msg.timestamp}, isDisappearing=${msg.isDisappearing}, disappearingTime=${msg.disappearingTime}');
        
        // Debug: Log if this is a disappearing image message
        if (msg.type == MessageType.image && msg.isDisappearing) {
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Received disappearing image message from server');
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Server message ID: ${msg.id}');
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Message sender: ${msg.sender}');
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Current user ID: $_currentUserId');
        }
        
        // Only process messages from the other participant
        if (msg.sender == widget.conversationId) {
          if (msg.isDisappearing) {
            AppLogger.info('debug disappearing: This is a disappearing message with time: ${msg.disappearingTime}');
          }
          AppLogger.info('debug disappearing: Adding MessageReceived and ConversationUpdated events to bloc');
          context.read<ConversationBloc>().add(MessageReceived(msg));
          context.read<ConversationBloc>().add(ConversationUpdated(
            conversationId: widget.conversationId,
            lastMessage: msg,
            updatedAt: DateTime.now(),
          ));
          // Mark message as delivered immediately after receiving
          AppLogger.info('debug disappearing: on_private_message processedIds contains? ${_processedMessageIds.contains(msg.id)}');
          if (_socketService != null && !_processedMessageIds.contains(msg.id)) {
            AppLogger.info('debug disappearing: Marking message as delivered: $serverMessageId');
            _socketService!.emit('message_delivered', {
              'messageId': serverMessageId,
              'conversationId': widget.conversationId,
              'timestamp': DateTime.now().toIso8601String(),
            });
            _processedMessageIds.add(msg.id);
          }
          // Scroll to bottom when receiving a new message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              AppLogger.info('debug disappearing: Scrolled to bottom after receiving message');
            }
          });
        }
      } catch (e) {
        AppLogger.error('debug disappearing: Error processing received message: $e');
        AppLogger.error('debug disappearing: Message data: $data');
      }
    });

    // Add typing indicator listeners with debounce
    _socketService!.on('typing', (data) {
      if (!mounted) return;
      if (data['from'] == widget.conversationId) {
        _typingDebounce?.cancel();
        _typingDebounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _otherUserTyping = true;
            });
            context.read<ConversationBloc>().add(ConversationUpdated(
              conversationId: widget.conversationId,
              isTyping: true,
              updatedAt: DateTime.now(),
            ));
          }
        });
      }
    });

    _socketService!.on('stop_typing', (data) {
      if (!mounted) return;
      if (data['from'] == widget.conversationId) {
        _typingDebounce?.cancel();
        _typingDebounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _otherUserTyping = false;
            });
            context.read<ConversationBloc>().add(ConversationUpdated(
              conversationId: widget.conversationId,
              isTyping: false,
              updatedAt: DateTime.now(),
            ));
          }
        });
      }
    });

    // Add individual message status listeners for backward compatibility
    _socketService!.on('message_delivered', (data) {
      if (!mounted) return;
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Received message_delivered event: $data');
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Current socket ID: ${_socketService!.socketId}');
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Current user ID: $_currentUserId');
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Conversation ID: ${widget.conversationId}');
      try {
        final messageId = data['messageId'];
        final deliveredAt = data['deliveredAt'] != null 
            ? DateTime.parse(data['deliveredAt']) 
            : DateTime.now();
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Delivered at: $deliveredAt');
        
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Adding MessageDelivered event to bloc');
        context.read<ConversationBloc>().add(MessageDelivered(
          messageId,
          deliveredAt,
        ));
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Successfully processed message_delivered event');
      } catch (e) {
        AppLogger.error('❌ DEBUGGING MESSAGE DELIVERY: Error processing message_delivered event: $e');
      }
    });

    _socketService!.on('message_read', (data) {
      if (!mounted) return;
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Received message_read event: $data');
      try {
        final messageId = data['messageId'];
        final readAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Read at: $readAt');
        
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Adding MessageRead event to bloc');
        context.read<ConversationBloc>().add(MessageRead(
          messageId,
          readAt,
        ));
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Successfully processed message_read event');
      } catch (e) {
        AppLogger.error('❌ DEBUGGING MESSAGE DELIVERY: Error processing message_read event: $e');
      }
    });

    _socketService!.on('new_message', (data) {
      AppLogger.info('🔵 DEBUGGING TIMESTAMP: Raw timestamp from socket: ${data['timestamp']}');
      final timestamp = DateTime.parse(data['timestamp'] as String);
      AppLogger.info('🔵 DEBUGGING TIMESTAMP: Parsed timestamp: $timestamp');
      AppLogger.info('🔵 DEBUGGING TIMESTAMP: Local timezone: ${DateTime.now().timeZoneName}');
      AppLogger.info('🔵 DEBUGGING TIMESTAMP: Local time: ${DateTime.now()}');
      
      final message = Message.fromJson({
        ...data,
        'timestamp': timestamp.toIso8601String(),
      });
      AppLogger.info('🔵 DEBUGGING TIMESTAMP: Message timestamp after fromJson: ${message.timestamp}');
      
      if (message.sender == widget.conversationId) {
        context.read<ConversationBloc>().add(MessageReceived(message));
      }
    });
  }

  void _showImagePicker() {
    AppLogger.info('debug disappearing: Opening image picker modal');
    showModalBottomSheet(
        context: context,
      builder: (context) {
        int selectedTime = 5; // Default disappearing time
        AppLogger.info('debug disappearing: Default disappearing time set to 5 seconds');
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  DisappearingTimeSelector(
                    selectedTime: selectedTime,
                    onTimeSelected: (time) {
                      AppLogger.info('debug disappearing: Disappearing time selected: $time seconds');
                      setState(() {
                        selectedTime = time;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            AppLogger.info('debug disappearing: Gallery button pressed');
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80, // Compress image to reduce size
                              maxWidth: 1920, // Limit max width
                              maxHeight: 1920, // Limit max height
                            );
                            
                            if (image != null) {
                              AppLogger.info('debug disappearing: Image selected from gallery: ${image.path}');
                              AppLogger.info('debug disappearing: Image name: ${image.name}');
                              AppLogger.info('debug disappearing: Image size: ${image.length} bytes');
                              
                              // Verify file exists and check format
                              final file = File(image.path);
                              if (await file.exists()) {
                                AppLogger.info('debug disappearing: File exists and is readable');
                                final fileSize = await file.length();
                                AppLogger.info('debug disappearing: File size: $fileSize bytes');
                                
                                // Check file extension
                                final extension = image.path.split('.').last.toLowerCase();
                                if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
                                  throw Exception('Only JPEG, PNG and GIF images are allowed');
                                }
                                
                                Navigator.pop(context);
                                await _sendImageMessage(
                                  image.path,
                                  isDisappearing: true,
                                  disappearingTime: selectedTime,
                                );
                              } else {
                                AppLogger.error('debug disappearing: File does not exist at path: ${image.path}');
                                throw Exception('Selected image file does not exist');
                              }
                            } else {
                              AppLogger.info('debug disappearing: No image selected from gallery');
                            }
                          } catch (e) {
                            AppLogger.error('debug disappearing: Error picking image: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error selecting image: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            AppLogger.info('debug disappearing: Camera button pressed');
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 80, // Compress image to reduce size
                              maxWidth: 1920, // Limit max width
                              maxHeight: 1920, // Limit max height
                            );
                            
                            if (image != null) {
                              AppLogger.info('debug disappearing: Image captured from camera: ${image.path}');
                              AppLogger.info('debug disappearing: Image name: ${image.name}');
                              AppLogger.info('debug disappearing: Image size: ${image.length} bytes');
                              
                              // Verify file exists and check format
                              final file = File(image.path);
                              if (await file.exists()) {
                                AppLogger.info('debug disappearing: File exists and is readable');
                                final fileSize = await file.length();
                                AppLogger.info('debug disappearing: File size: $fileSize bytes');
                                
                                // Check file extension
                                final extension = image.path.split('.').last.toLowerCase();
                                if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
                                  throw Exception('Only JPEG, PNG and GIF images are allowed');
                                }
                                
                                Navigator.pop(context);
                                await _sendImageMessage(
                                  image.path,
                                  isDisappearing: true,
                                  disappearingTime: selectedTime,
                                );
                              } else {
                                AppLogger.error('debug disappearing: File does not exist at path: ${image.path}');
                                throw Exception('Captured image file does not exist');
                              }
                            } else {
                              AppLogger.info('debug disappearing: No image captured from camera');
                            }
                          } catch (e) {
                            AppLogger.error('debug disappearing: Error capturing image: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error capturing image: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ],
                ),
              ],
            ),
          );
        },
      );
      },
    );
  }

  Future<void> _sendImageMessage(String imagePath, {bool isDisappearing = true, int disappearingTime = 5}) async {
    AppLogger.info('debug disappearing: Starting _sendImageMessage with imagePath: $imagePath, isDisappearing: $isDisappearing, disappearingTime: $disappearingTime');
    if (_socketService != null && _currentUserId != null) {
      try {
        AppLogger.info('debug disappearing: Preparing to upload image');
        final extension = imagePath.split('.').last.toLowerCase();
        final contentType = switch (extension) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'gif' => 'image/gif',
          _ => throw Exception('Unsupported image format: $extension')
        };
        
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
            contentType: MediaType.parse(contentType),
          ),
          'isDisappearing': isDisappearing,
          'disappearingTime': disappearingTime,
        });
        AppLogger.info('debug disappearing: Sending POST request to /messages/upload-image');
        final response = await NetworkService.dio.post(
          '/messages/upload-image',
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
            validateStatus: (status) => true, // Accept all status codes for debugging
          ),
        );
        AppLogger.info('debug disappearing: Received response from upload-image: statusCode=${response.statusCode}, data=${response.data}');
        if (response.statusCode == 200) {
          // Log the complete response structure to understand what fields are available
          AppLogger.info('debug disappearing: Upload response data structure:');
          AppLogger.info('debug disappearing: - Response data type: ${response.data.runtimeType}');
          AppLogger.info('debug disappearing: - Response data keys: ${response.data.keys.toList()}');
          AppLogger.info('debug disappearing: - Full response data: ${response.data}');
          
          final imageUrl = response.data['imageUrl'];
          final imageKey = response.data['imageKey'] ?? response.data['key'] ?? response.data['s3Key'];
          final imageSize = response.data['imageSize'] ?? response.data['size'] ?? response.data['fileSize'];
          final imageType = response.data['imageType'] ?? response.data['type'] ?? response.data['mimeType'] ?? response.data['contentType'];
          
          AppLogger.info('debug disappearing: Extracted values:');
          AppLogger.info('debug disappearing: - imageUrl: $imageUrl');
          AppLogger.info('debug disappearing: - imageKey: $imageKey');
          AppLogger.info('debug disappearing: - imageSize: $imageSize');
          AppLogger.info('debug disappearing: - imageType: $imageType');
          
          // Validate that we have the required values
          if (imageUrl == null) {
            throw Exception('No imageUrl in upload response');
          }
          
          // Provide fallback values if not provided by upload response
          final finalImageKey = imageKey ?? _extractImageKeyFromUrl(imageUrl);
          final finalImageSize = imageSize ?? await _getFileSize(imagePath);
          final finalImageType = imageType ?? _getMimeTypeFromExtension(imagePath);
          
          AppLogger.info('debug disappearing: Final values for POST /messages:');
          AppLogger.info('debug disappearing: - imageUrl: $imageUrl');
          AppLogger.info('debug disappearing: - imageKey: $finalImageKey');
          AppLogger.info('debug disappearing: - imageSize: $finalImageSize');
          AppLogger.info('debug disappearing: - imageType: $finalImageType');
          
          // Make POST /api/messages call with complete payload
          AppLogger.info('debug disappearing: Making POST /api/messages call');
          final messageResponse = await NetworkService.dio.post(
            '/messages',
            data: {
              'receiver': widget.conversationId, // API expects 'receiver' field
              'content': '', // Can be empty for image messages
              'messageType': 'image',
              'imageUrl': imageUrl,
              'imageKey': finalImageKey,
              'imageSize': finalImageSize,
              'imageType': finalImageType,
              'isDisappearing': isDisappearing,
              'disappearingTime': disappearingTime,
            },
            options: Options(
              validateStatus: (status) => true, // Accept all status codes for debugging
            ),
          );
          
          AppLogger.info('debug disappearing: POST /api/messages response: statusCode=${messageResponse.statusCode}, data=${messageResponse.data}');
          
          // Extract expiresAt from API response metadata
          String? expiresAt;
          if (messageResponse.statusCode == 200 || messageResponse.statusCode == 201) {
            final responseData = messageResponse.data;
            AppLogger.info('🔵 DEBUGGING EXPIRATION: Full API response data: $responseData');
            AppLogger.info('🔵 DEBUGGING EXPIRATION: Response data type: ${responseData.runtimeType}');
            AppLogger.info('🔵 DEBUGGING EXPIRATION: Response data keys: ${responseData.keys.toList()}');
            
            if (responseData['metadata'] != null) {
              AppLogger.info('🔵 DEBUGGING EXPIRATION: Metadata exists: ${responseData['metadata']}');
              AppLogger.info('🔵 DEBUGGING EXPIRATION: Metadata type: ${responseData['metadata'].runtimeType}');
              AppLogger.info('🔵 DEBUGGING EXPIRATION: Metadata keys: ${responseData['metadata'].keys.toList()}');
              
              if (responseData['metadata']['expiresAt'] != null) {
                expiresAt = responseData['metadata']['expiresAt'] as String;
                AppLogger.info('🔵 DEBUGGING EXPIRATION: Successfully extracted expiresAt: $expiresAt');
              } else {
                AppLogger.warning('🔵 DEBUGGING EXPIRATION: expiresAt is null in metadata');
              }
            } else {
              AppLogger.warning('🔵 DEBUGGING EXPIRATION: No metadata in API response');
            }
          } else {
            AppLogger.warning('🔵 DEBUGGING EXPIRATION: API call failed, status code: ${messageResponse.statusCode}');
          }
          
          // Fallback: Extract expiration time from S3 URL if not provided by API
          if (expiresAt == null && imageUrl.contains('X-Amz-Expires=')) {
            try {
              final uri = Uri.parse(imageUrl);
              final expiresParam = uri.queryParameters['X-Amz-Expires'];
              if (expiresParam != null) {
                final expiresSeconds = int.parse(expiresParam);
                final expirationTime = DateTime.now().add(Duration(seconds: expiresSeconds));
                expiresAt = expirationTime.toIso8601String();
                AppLogger.info('🔵 DEBUGGING EXPIRATION: Extracted expiration from S3 URL: $expiresAt (${expiresSeconds}s from now)');
              }
            } catch (e) {
              AppLogger.error('🔵 DEBUGGING EXPIRATION: Failed to extract expiration from S3 URL: $e');
            }
          }
          
          if (messageResponse.statusCode != 200 && messageResponse.statusCode != 201) {
            AppLogger.error('debug disappearing: Failed to create message record: ${messageResponse.statusCode}');
            AppLogger.error('debug disappearing: Error response data: ${messageResponse.data}');
            AppLogger.error('debug disappearing: Request payload was: ${messageResponse.requestOptions.data}');
            
            // Continue with socket event even if API call fails
            AppLogger.info('debug disappearing: Continuing with socket event despite API failure');
          } else {
            AppLogger.info('debug disappearing: Message record created successfully');
          }
          
          // Get the message ID from the response if available, otherwise use local ID
          final messageId = messageResponse.statusCode == 200 || messageResponse.statusCode == 201
              ? (messageResponse.data['_id'] ?? messageResponse.data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
              : DateTime.now().millisecondsSinceEpoch.toString();
          
          final messageData = {
            '_id': messageId,  // Use '_id' to match API response format
            'from': _currentUserId,
            'to': widget.conversationId,
            'content': imageUrl,
            'messageType': 'image',
            'status': 'sent',
            'createdAt': DateTime.now().toIso8601String(),
            'isDisappearing': isDisappearing,
            'disappearingTime': disappearingTime,
            'metadata': expiresAt != null ? {'expiresAt': expiresAt} : null,
          };
          AppLogger.info('debug disappearing: Constructed messageData: $messageData');
          AppLogger.info('🔵 DEBUGGING EXPIRATION: MessageData metadata: ${messageData['metadata']}');
          AppLogger.info('🔵 DEBUGGING EXPIRATION: expiresAt value: $expiresAt');
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Full socket payload being sent: $messageData');
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Sender sending image with server ID: ${messageData['_id']}');
          _socketService!.emit('private_message', messageData);
          AppLogger.info('debug disappearing: Emitted private_message event via socket');
          
          // Create message for local state with metadata
          final messageJson = {
            '_id': messageData['_id'],
            'sender': messageData['from'],
            'receiver': messageData['to'],
            'content': messageData['content'],
            'createdAt': messageData['createdAt'],
            'messageType': messageData['messageType'],
            'status': 'sent',
            'isDisappearing': isDisappearing,
            'disappearingTime': disappearingTime,
            'metadata': messageData['metadata'], // Include metadata in Message.fromJson
          };
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Message JSON for fromJson: $messageJson');
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Message JSON metadata: ${messageJson['metadata']}');
          
          final msg = Message.fromJson(messageJson);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Created Message object');
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Message urlExpirationTime: ${msg.urlExpirationTime}');
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Message metadata: ${msg.metadata}');
          AppLogger.info('debug disappearing: Created Message object for local state: id=${msg.id}, content=${msg.content}');
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Sender adding message to local state with ID: ${msg.id}');
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Message ID consistency check - Socket ID: ${messageData['_id']}, Local ID: ${msg.id}');
          context.read<ConversationBloc>().add(MessageSent(msg));
          AppLogger.info('debug disappearing: Added message to local state via ConversationBloc');
          WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
            AppLogger.info('debug disappearing: Scrolled to bottom after sending image message');
          });
      } else {
          AppLogger.error('debug disappearing: Failed to upload image, statusCode: ${response.statusCode}, data: ${response.data}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send image. Please try again.')),
          );
        }
      } catch (e) {
        AppLogger.error('debug disappearing: Exception occurred while sending image message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send image. Please try again.')),
        );
      }
    } else {
      AppLogger.error('debug disappearing: Cannot send image message: SocketService or currentUserId is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please try again.')),
      );
    }
  }

  // Helper method to extract image key from URL
  String _extractImageKeyFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.path.split('/');
      // Extract the last two segments (messages/filename) as the image key
      if (pathSegments.length >= 2) {
        return pathSegments.sublist(pathSegments.length - 2).join('/');
      }
      return pathSegments.last;
    } catch (e) {
      AppLogger.warning('debug disappearing: Failed to extract image key from URL: $e');
      return 'unknown';
    }
  }

  // Helper method to get file size
  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      AppLogger.warning('debug disappearing: Failed to get file size: $e');
      return 0;
    }
  }

  // Helper method to get MIME type from file extension
  String _getMimeTypeFromExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
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
    AppLogger.info('🔵 Opening options menu');
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
                  AppLogger.info('🔵 Send Image option tapped');
                  Navigator.pop(context);
                  _showImagePicker();
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

  void _showFullScreenImage(String imageUrl, bool isSender) async {
    try {
      AppLogger.info('🔵 Opening full screen image');
      AppLogger.info('🔵 Original image URL: $imageUrl');
      AppLogger.info('🔵 Is sender: $isSender');
      
      // Find the message that contains this image URL
      final state = context.read<ConversationBloc>().state;
      Message? message;
      if (state is ConversationLoaded) {
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Current state has ${state.messages.length} messages');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Looking for message with content: $imageUrl');
        
        // Log all image messages in state for debugging
        final imageMessages = state.messages.where((msg) => msg.type == MessageType.image).toList();
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found ${imageMessages.length} image messages in state:');
        for (final imgMsg in imageMessages) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: - ID: ${imgMsg.id}, Content: ${imgMsg.content}, IsDisappearing: ${imgMsg.isDisappearing}');
        }
        
        // First try to find by exact content match
        try {
          message = state.messages.firstWhere(
            (msg) => msg.content == imageUrl && msg.type == MessageType.image,
            orElse: () => throw Exception('Exact content match not found'),
          );
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found message by exact content match: ${message.id}');
        } catch (e) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Exact content match failed, trying pattern matching');
          // Fallback: try to find by image key pattern if exact match fails
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.path.split('/');
          if (pathSegments.length >= 2) {
            final imageKey = pathSegments.sublist(pathSegments.length - 2).join('/');
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: Looking for message with image key pattern: $imageKey');
            
            final matchingMessages = state.messages.where((msg) => 
                msg.type == MessageType.image && 
                msg.content.contains(imageKey)
            ).toList();
            
            if (matchingMessages.isNotEmpty) {
              // If multiple matches, prefer the most recent one
              message = matchingMessages.first;
              AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found message by pattern match: ${message.id}');
            } else {
              throw Exception('No message found with image key pattern: $imageKey');
            }
          } else {
            throw Exception('Invalid image URL format: $imageUrl');
          }
        }

        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found message to open:');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Message ID: ${message.id}');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Content: ${message.content}');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Is disappearing: ${message.isDisappearing}');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Disappearing time: ${message.disappearingTime}');

        // Emit image_viewed event
        if (_socketService != null && !isSender) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Emitting image_viewed event');
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Message ID to emit: ${message.id}');
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Conversation ID: ${widget.conversationId}');
          _socketService!.sendImageViewed(message.id, widget.conversationId);
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: image_viewed event emitted successfully');
        } else {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Not emitting image_viewed event (isSender: $isSender, socketService: ${_socketService != null})');
        }
      } else {
        AppLogger.error('🔵 DEBUGGING MESSAGE ID: State is not ConversationLoaded: ${state.runtimeType}');
      }
      
      // Use the original URL directly - refresh will be called only if we get 403 error
      AppLogger.info('🔵 Using original image URL for full-screen: $imageUrl');
      _showFullScreenImageWithUrl(imageUrl, isSender, message);
    } catch (e) {
      AppLogger.error('❌ Failed to show full screen image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load image. Please try again.')),
      );
    }
  }

  void _showFullScreenImageWithUrl(String imageUrl, bool isSender, Message? message) {
    if (!mounted) return;
    
    // If we don't have the message from the previous step, try to find it
    if (message == null) {
      final state = context.read<ConversationBloc>().state;
      if (state is ConversationLoaded) {
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message not provided, searching in state');
        // Try to find by the original content URL pattern
        try {
          message = state.messages.firstWhere(
            (msg) => msg.type == MessageType.image && 
                     (msg.content.contains('messages/') || imageUrl.contains('messages/')),
            orElse: () => throw Exception('Pattern match not found'),
          );
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found message by pattern match: ${message.id}');
        } catch (e) {
          AppLogger.error('🔵 DEBUGGING MESSAGE ID: Failed to find message by pattern: $e');
          // Last resort: try to find any image message
          final imageMessages = state.messages.where((msg) => msg.type == MessageType.image).toList();
          if (imageMessages.isNotEmpty) {
            message = imageMessages.first;
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: Using first available image message: ${message.id}');
          } else {
            throw Exception('No image messages found in state');
          }
        }
      }
    }

    if (message == null) {
      AppLogger.error('❌ Could not find message for image');
      return;
    }



    // Emit image_viewed event for receiver when opening full screen
    if (!isSender && message.isDisappearing && message.disappearingTime != null) {
      AppLogger.info('🔵 DEBUGGING Disappearing Image: Receiver opening image, emitting image_viewed event');
      _socketService?.sendImageViewed(message.id, widget.conversationId);
    }

    _currentlyOpenImageId = message.id; // Set which image is currently open in full-screen
    AppLogger.info('🔵 DEBUGGING Disappearing Image: Opening full-screen for image ID: ${message.id}');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async {
              _currentlyOpenImageId = null; // Reset when closing
              AppLogger.info('🔵 DEBUGGING Disappearing Image: Full-screen closed via back button');
              return true;
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          AppLogger.error('❌ Failed to load image: $error');
                          
                          // Check if it's a 403 error (expired URL)
                          if (error.toString().contains('403')) {
                            AppLogger.info('🔵 Got 403 error, showing retry option');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.refresh, size: 40, color: Colors.white),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final uri = Uri.parse(imageUrl);
                                        final pathSegments = uri.path.split('/');
                                        final imageKey = pathSegments.sublist(pathSegments.length - 2).join('/');
                                        final refreshedUrl = await ImageUrlService().getValidImageUrl(imageKey);
                                        
                                        AppLogger.info('🔵 Got refreshed URL: $refreshedUrl');
                                        
                                        // Close current dialog and reopen with refreshed URL
                                        Navigator.of(context).pop();
                                        _showFullScreenImageWithUrl(refreshedUrl, isSender, message);
                                      } catch (refreshError) {
                                        AppLogger.error('❌ Failed to refresh image URL: $refreshError');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to refresh image URL')),
                                        );
                                      }
                                    },
                                    child: const Text('Retry with refreshed URL'),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return const Center(
                            child: Icon(Icons.error_outline, size: 40, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_disappearingImageManager.hasTimer(message!.id))
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: 16,
                      child: _disappearingImageManager.getTimerState(message!.id)?.timerNotifier != null
                          ? ValueListenableBuilder<int>(
                              valueListenable: _disappearingImageManager.getTimerState(message!.id)!.timerNotifier,
                              builder: (context, time, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$time s',
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${message!.disappearingTime}s',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _currentlyOpenImageId = null; // Reset when closing
                        AppLogger.info('🔵 DEBUGGING Disappearing Image: Full-screen closed via close button');
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startDisappearingImageTimer(String messageId, int disappearingTime) {
    AppLogger.info('🔵 DEBUGGING Disappearing Image: Starting timer for message: $messageId');
    AppLogger.info('🔵 DEBUGGING Disappearing Image: Disappearing time: $disappearingTime seconds');
    
    // Validate message ID
    if (messageId.isEmpty) {
      AppLogger.error('🔵 DEBUGGING Disappearing Image: Cannot start timer with empty message ID');
      return;
    }
    
    // Use DisappearingImageManager to handle timer
    if (_disappearingImageManager.hasTimer(messageId)) {
      _disappearingImageManager.convertToActiveTimer(messageId, disappearingTime);
    } else {
      _disappearingImageManager.startTimer(messageId, disappearingTime);
    }
  }



  @override
  Widget build(BuildContext context) {
    AppLogger.info('🔵 Building ChatPage');
    AppLogger.info('🔵 Current state: ${context.read<ConversationBloc>().state}');
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    widget.participantName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.isOnline)
                  const Text(
                      'Online',
                    style: TextStyle(
                        color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
              ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.black),
            onPressed: () => _startCall(true), // Audio call
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black),
            onPressed: () => _startCall(false), // Video call
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _toggleMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: BlocListener<ConversationBloc, ConversationState>(
              listener: (context, state) {
                if (state is ConversationLoaded) {
                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  // Debug: Log message count changes
                  AppLogger.info('🔵 DEBUGGING Disappearing Image: State updated, message count: ${state.messages.length}');

                  // Initialize display timers for disappearing image messages
                  for (final message in state.messages) {
                    if (message.isDisappearing && 
                        message.disappearingTime != null && 
                        message.type == MessageType.image &&
                        !_disappearingImageManager.hasTimer(message.id)) {
                      AppLogger.info('🔵 DEBUGGING Disappearing Image: Initializing display timer for message: ${message.id}');
                      AppLogger.info('🔵 DEBUGGING Disappearing Image: Disappearing time: ${message.disappearingTime} seconds');
                      _disappearingImageManager.initializeDisplayTimer(message.id, message.disappearingTime!);
                    }
                  }

                  // Collect messages that need to be marked as delivered
                  final messagesToDeliver = state.messages
                      .where((message) => 
                          message.sender == widget.conversationId && 
                          message.status == 'sent' && 
                          !_processedMessageIds.contains(message.id))
                      .map((m) => m.id)
                      .toList();

                  AppLogger.info('🔵 Messages to deliver: ${messagesToDeliver.length}');
                  AppLogger.info('🔵 Processed message IDs: $_processedMessageIds');

                  // Collect messages that need to be marked as read
                  final messagesToRead = state.messages
                      .where((message) => 
                          message.sender == widget.conversationId && 
                          message.status == 'delivered' && 
                          !_processedMessageIds.contains('${message.id}_read'))
                      .map((m) => m.id)
                      .toList();

                  AppLogger.info('🔵 Messages to read: ${messagesToRead.length}');

                  // Emit bulk events if there are messages to update
                  if (_socketService != null) {
                    if (messagesToDeliver.isNotEmpty) {
                      final timestamp = DateTime.now().toIso8601String();
                      AppLogger.info('🔵 Emitting bulk_message_delivered for messages: ${messagesToDeliver.join(', ')}');
                      try {
                        _socketService!.emit('bulk_message_delivered', {
                          'messageIds': messagesToDeliver,
                          'conversationId': widget.conversationId,
                          'timestamp': timestamp,
                        });
                        // Add to processed set
                        for (final id in messagesToDeliver) {
                          _processedMessageIds.add(id);
                          AppLogger.info('✅ Added to processed IDs: $id');
                        }
                        AppLogger.info('✅ Successfully emitted bulk_message_delivered event');
                      } catch (e) {
                        AppLogger.error('❌ Failed to emit bulk_message_delivered event: $e');
                      }
                    }

                    if (messagesToRead.isNotEmpty) {
                      final timestamp = DateTime.now().toIso8601String();
                      AppLogger.info('🔵 Emitting bulk_message_read for messages: ${messagesToRead.join(', ')}');
                      try {
                        _socketService!.emit('bulk_message_read', {
                          'messageIds': messagesToRead,
                          'conversationId': widget.conversationId,
                          'timestamp': timestamp,
                          'readBy': _currentUserId,
                        });
                        // Add to processed set
                        for (final id in messagesToRead) {
                          final readId = '${id}_read';
                          _processedMessageIds.add(readId);
                          AppLogger.info('✅ Added to processed IDs: $readId');
                        }
                        AppLogger.info('✅ Successfully emitted bulk_message_read event');
                      } catch (e) {
                        AppLogger.error('❌ Failed to emit bulk_message_read event: $e');
                      }
                    }
                  }
                } else if (state is ConversationLeft) {
                  // Navigate back when conversation is left (for initiator)
                  AppLogger.info('🔵 Conversation left, navigating back (initiator)');
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conversation ended')),
                    );
                  }
                } else if (state is ConversationError) {
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.message}')),
                    );
                  }
                } else if (state is ConversationLoaded) {
                  // Check if this is a response to block or report action
                  final currentState = state as ConversationLoaded;
                  if (currentState.conversation.isBlocked) {
                    // User was blocked successfully
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User blocked successfully')),
                      );
                    }
                  } else if (currentState.conversation.isMuted) {
                    // User was reported successfully (using mute as report)
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User reported successfully')),
                      );
                    }
                  }
                }
              },
              child: Column(
                children: [
                  // Message List - Only rebuilds when messages change
                  Expanded(
                    child: BlocSelector<ConversationBloc, ConversationState, List<Message>>(
                      selector: (state) => state is ConversationLoaded ? state.messages : [],
                      builder: (context, messages) {
                        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Rendering messages list. Total messages: ${messages.length}');
                        
                        return NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification) {
                              AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Scroll ended at position: ${_scrollController.position.pixels}');
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length) {
                                if (_isLoadingMore) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }
                              
                              final message = messages[index];
                              final isMe = message.sender == _currentUserId;
                              
                              // Emit message_read when message is visible and from other user
                              if (!isMe && 
                                  message.status == 'delivered' && 
                                  _socketService != null &&
                                  !_processedMessageIds.contains('${message.id}_read')) {
                                AppLogger.info('🔵 Emitting message_read for message: ${message.id}');
                                try {
                                  _socketService!.emit('message_read', {
                                    'messageId': message.id,
                                    'conversationId': widget.conversationId,
                                    'timestamp': DateTime.now().toIso8601String(),
                                    'readBy': _currentUserId,
                                  });
                                  _processedMessageIds.add('${message.id}_read');
                                  AppLogger.info('✅ Successfully emitted message_read event');
                                } catch (e) {
                                  AppLogger.error('❌ Failed to emit message status events: $e');
                                }
                              }
                              
                              // Only pass timer parameters for disappearing image messages
                              final timerState = _disappearingImageManager.getTimerState(message.id);
                              final shouldShowTimer = message.isDisappearing && 
                                                   message.disappearingTime != null && 
                                                   message.type == MessageType.image;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: MessageBubble(
                                  key: ValueKey(message.id),
                                  message: message,
                                  isMe: isMe,
                                  showAvatar: false,
                                  avatarUrl: widget.participantAvatar,
                                  statusWidget: isMe ? _buildMessageStatus(message) : null,
                                  timestamp: _formatMessageTimestamp(message),
                                  onImageTap: () {
                                    if (message.type == MessageType.image) {
                                      AppLogger.info('🔵 MessageBubble requested full screen image');
                                      AppLogger.info('🔵 Message content: ${message.content}');
                                      _showFullScreenImage(message.content, isMe);
                                    }
                                  },
                                  disappearingTime: shouldShowTimer ? timerState?.remainingTime : null,
                                  timerNotifier: shouldShowTimer ? timerState?.timerNotifier : null,
                                  onImageUrlRefreshed: (messageId, newImageUrl, newExpirationTime, additionalData) {
                                    AppLogger.info('🔵 MessageBubble requested image URL refresh for message: $messageId');
                                    context.read<ConversationBloc>().add(UpdateMessageImageData(
                                      messageId: messageId,
                                      newImageUrl: newImageUrl,
                                      newExpirationTime: newExpirationTime,
                                      additionalData: additionalData,
                                    ));
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Typing Indicator - Only rebuilds when typing status changes
                  BlocSelector<ConversationBloc, ConversationState, bool>(
                    selector: (state) => _otherUserTyping,
                    builder: (context, isTyping) {
                      if (!isTyping) return const SizedBox.shrink();
                      
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
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      // Add side menu overlay
      if (_isMenuOpen) _buildSideMenu(Conversation(
        id: widget.conversationId,
        participantId: widget.conversationId,
        participantName: widget.participantName,
        participantAvatar: widget.participantAvatar,
        messages: [],
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        userId: _currentUserId ?? '',
        lastMessage: null,
        updatedAt: DateTime.now(),
        isOnline: widget.isOnline,
      )),
    ],
    )
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
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _showImagePicker,
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
                    leading: const Icon(Icons.report),
                    title: const Text('Report'),
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

  String _formatMessageTimestamp(Message message) {
    // Convert UTC timestamps to local time before formatting
    DateTime localTime;
    
    // Use the most appropriate timestamp based on message status
    if (message.status == 'read' && message.readAt != null) {
      localTime = message.readAt!.toLocal();
    } else if (message.status == 'delivered' && message.deliveredAt != null) {
      localTime = message.deliveredAt!.toLocal();
    } else {
      // Default to message timestamp
      localTime = message.timestamp.toLocal();
    }
    
    return DateFormat('HH:mm').format(localTime);
  }

  // Add message status indicator
  Widget _buildMessageStatus(Message message) {
    if (message.sender != _currentUserId) return const SizedBox.shrink();
    
    AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Building message status for message: ${message.id}');
    AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Message status: ${message.status}');
    AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Message deliveredAt: ${message.deliveredAt}');
    AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Message readAt: ${message.readAt}');
    
    Widget statusIcon;
    
    // Properly handle status progression - only show status icons, not timestamps
    if (message.status == 'read' && message.readAt != null) {
      statusIcon = Opacity(
        opacity: 0, // Hide the icon
        child: const Icon(Icons.done_all, size: 16, color: Colors.blue),
      );
    } else if (message.status == 'delivered' && message.deliveredAt != null) {
      statusIcon = Opacity(
        opacity: 0, // Hide the icon
        child: const Icon(Icons.done_all, size: 16, color: Colors.grey),
      );
    } else {
      // Default to sent status
      statusIcon = Opacity(
        opacity: 0, // Hide the icon
        child: const Icon(Icons.check, size: 16, color: Colors.grey),
      );
    }
    
    AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Selected status icon: ${message.status}');
    
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

  void _startCall(bool isAudioCall) {
    final channelName = '${widget.conversationId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Show call screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          isAudioCall: isAudioCall,
          participantName: widget.participantName,
          participantAvatar: widget.participantAvatar,
          onCallEnded: () {
            context.read<ConversationBloc>().add(EndCall(conversationId: widget.conversationId));
          },
        ),
      ),
    );

    // Notify bloc
    context.read<ConversationBloc>().add(
      isAudioCall
          ? StartAudioCall(conversationId: widget.conversationId)
          : StartVideoCall(conversationId: widget.conversationId),
    );
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) {
      AppLogger.warning('Attempted to send empty message');
      return;
    }

    final content = _messageController.text.trim();
    AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Starting to send text message: $content');
    _messageController.clear();

    if (_socketService != null && _currentUserId != null) {
      try {
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Current user ID: $_currentUserId');
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Recipient ID: ${widget.conversationId}');
        
        // Create message data with initial 'sent' status
        final messageData = {
          '_id': DateTime.now().millisecondsSinceEpoch.toString(),  // Use '_id' to match API response format
          'from': _currentUserId,
          'to': widget.conversationId,
          'content': content,
          'messageType': 'text',
          'status': 'sent', // Start with 'sent' status
          'createdAt': DateTime.now().toIso8601String(),
        };

        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Emitting private_message with data: $messageData');
        // Send message through socket
        _socketService!.emit('private_message', messageData);
        
        // Add message to local state immediately with 'sent' status
        final msg = Message.fromJson({
          '_id': messageData['id'],
          'sender': messageData['from'],
          'receiver': messageData['to'],
          'content': messageData['content'],
          'createdAt': messageData['createdAt'],
          'messageType': messageData['messageType'],
          'status': 'sent', // Start with 'sent' status
          'timestamp': DateTime.now(), // Add timestamp for sent status
        });
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Added message to local state: ${msg.content}');
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Message status in local state: ${msg.status}');
        context.read<ConversationBloc>().add(MessageSent(msg));
        
        // Scroll to bottom after sending message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } catch (e) {
        AppLogger.error('❌ DEBUGGING MESSAGE DELIVERY: Failed to send message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } else {
      AppLogger.error('❌ DEBUGGING MESSAGE DELIVERY: Cannot send message: SocketService or currentUserId is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please try again.')),
      );
    }

    setState(() => _isTyping = false);
    _socketService?.emit('stop_typing', {'to': widget.conversationId});
  }
} 