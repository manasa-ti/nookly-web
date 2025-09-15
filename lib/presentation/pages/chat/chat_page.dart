import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:nookly/presentation/widgets/message_bubble.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:nookly/core/services/image_url_service.dart';

import 'package:nookly/presentation/widgets/disappearing_time_selector.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/core/services/disappearing_image_manager.dart';
import 'package:nookly/presentation/pages/report/report_page.dart';
import 'package:nookly/core/services/content_moderation_service.dart';
import 'package:nookly/core/services/key_management_service.dart';
import 'package:nookly/core/services/scam_alert_service.dart';
import 'package:nookly/core/services/api_cache_service.dart';
import 'package:nookly/presentation/widgets/scam_alert_popup.dart';
import 'package:nookly/presentation/widgets/conversation_starter_widget.dart';

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
  final String? lastSeen;
  final String? connectionStatus;

  const ChatPage({
    Key? key,
    required this.conversationId,
    required this.participantName,
    this.participantAvatar,
    required this.isOnline,
    this.lastSeen,
    this.connectionStatus,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachingFile = false;
  bool _isLoadingMore = false;
  bool _isUploadingImage = false;
  String _uploadStatus = '';
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

  // Scam alert state management
  ScamAlertType? _currentScamAlert;
  bool _showScamAlert = false;
  final Map<String, DateTime> _lastAlertShown = {};
  int _messageCount = 0;

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
      lastSeen: widget.lastSeen,
      connectionStatus: widget.connectionStatus,
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
    
    // Update message state
    context.read<ConversationBloc>().add(MessageExpired(messageId));
    
    // Close full screen if open and it's the same image
    if (_currentlyOpenImageId == messageId) {
      Navigator.of(context).pop();
      _currentlyOpenImageId = null;
    }
  }

  // Scam detection and alert methods
  void _checkForScamAlert(String message, bool isFromOtherUser) {
    if (!isFromOtherUser) return; // Only check messages from other users
    
    AppLogger.info('🔍 Checking for scam alert in message: "$message"');
    AppLogger.info('🔍 Message count: $_messageCount');
    
    final scamAlertService = ScamAlertService();
    final alertType = scamAlertService.analyzeMessage(message, messageCount: _messageCount);
    
    AppLogger.info('🔍 Alert type detected: ${alertType?.name ?? 'None'}');
    
    if (alertType != null) {
      final alertKey = '${widget.conversationId}_${alertType.name}';
      final lastShown = _lastAlertShown[alertKey] ?? DateTime.now().subtract(const Duration(hours: 2));
      
      AppLogger.info('🔍 Last shown: $lastShown');
      AppLogger.info('🔍 Should show alert: ${scamAlertService.shouldShowAlert(alertType, widget.conversationId, lastShown)}');
      
      if (scamAlertService.shouldShowAlert(alertType, widget.conversationId, lastShown)) {
        AppLogger.info('🚨 Showing scam alert: ${alertType.name}');
        setState(() {
          _currentScamAlert = alertType;
          _showScamAlert = true;
          _lastAlertShown[alertKey] = DateTime.now();
        });
      }
    }
  }

  void _dismissScamAlert() {
    setState(() {
      _showScamAlert = false;
      _currentScamAlert = null;
    });
  }

  // Debug: Test scam detection
  void _testScamDetection() {
    print('🧪 Testing scam detection...');
    final testMessages = [
      'Emergency has happened',  // Should trigger romanceFinancial
      'I need help with my bills',
      'I have an investment opportunity',
      'Can you send me money?',
      'Let\'s move to WhatsApp',
    ];
    
    for (final message in testMessages) {
      print('🧪 Testing: "$message"');
      _checkForScamAlert(message, true);
    }
  }

  void _reportScamAlert() {
    // Navigate to report page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          reportedUserId: widget.conversationId,
          reportedUserName: widget.participantName,
        ),
      ),
    );
    _dismissScamAlert();
  }

  void _learnMoreAboutScam() {
    // Show detailed information about the scam type
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF35548b),
        title: Text(
          _currentScamAlert != null 
              ? ScamAlertService().getAlertTitle(_currentScamAlert!)
              : 'Safety Information',
          style: const TextStyle(color: Colors.white, fontFamily: 'Nunito'),
        ),
        content: Text(
          _currentScamAlert != null 
              ? ScamAlertService().getAlertMessage(_currentScamAlert!)
              : 'Learn more about staying safe online.',
          style: const TextStyle(color: Colors.white, fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
            ),
          ),
        ],
      ),
    );
    _dismissScamAlert();
  }

  Future<void> _initSocketAndUser() async {
    AppLogger.info('🔵 Initializing socket and user');
    final authRepository = sl<AuthRepository>();
    final user = await authRepository.getCurrentUser();
    final token = await authRepository.getToken();
    
    AppLogger.info('🔵 User: ${user?.id}');
    AppLogger.info('🔵 Token available: ${token != null}');
    
    if (user != null && token != null) {
      _currentUserId = user.id;
      _jwtToken = token;
      _socketService = sl<SocketService>();
      
      AppLogger.info('🔵 Socket service created');
      
      // Update the ConversationBloc with the current user ID
      if (mounted) {
        context.read<ConversationBloc>().add(UpdateCurrentUserId(user.id));
      }
      
      AppLogger.info('🔵 Connecting to socket: ${SocketService.socketUrl}');
      _socketService!.connect(
        serverUrl: SocketService.socketUrl, 
        token: token,
        userId: user.id,
      );
      
      // Add a small delay to ensure socket is connected
      await Future.delayed(const Duration(milliseconds: 1000));
      
      AppLogger.info('🔵 Socket connected: ${_socketService!.isConnected}');
      AppLogger.info('🔵 Socket ID: ${_socketService!.socketId}');
      
      if (_socketService!.isConnected) {
        // Join the private chat room
        AppLogger.info('🔵 Joining private chat room: ${widget.conversationId}');
        _socketService!.joinPrivateChat(widget.conversationId);
      } else {
        AppLogger.error('❌ Socket not connected after initialization');
      }
      
      _registerSocketListeners();
      AppLogger.info('🔵 Socket listeners registered');
    } else {
      AppLogger.error('❌ User or token is null');
      AppLogger.error('❌ User: $user');
      AppLogger.error('❌ Token: ${token != null}');
    }
  }

  void _registerSocketListeners() {
    if (_socketService == null) {
      return;
    }
    
    // Add listener for all events
    _socketService!.on('connect', (data) {
      // Socket connected
    });
    
    _socketService!.on('disconnect', (data) {
      // Socket disconnected
    });
    
    _socketService!.on('error', (data) {
      // Socket error
    });

    // Add online status event listeners
    _socketService!.on('user_online', (data) {
      if (!mounted) return;
      AppLogger.info('🟢 User came online in chat: $data');
      final userId = data['userId'] as String?;
      
      if (userId == widget.conversationId) {
        AppLogger.info('🔵 Updating online status for current chat participant');
        setState(() {
          // Update the widget's isOnline state
          // Note: This will require a widget rebuild to reflect the change
        });
      }
    });

    _socketService!.on('user_offline', (data) {
      if (!mounted) return;
      AppLogger.info('🔴 User went offline in chat: $data');
      final userId = data['userId'] as String?;
      
      if (userId == widget.conversationId) {
        AppLogger.info('🔵 Updating offline status for current chat participant');
        setState(() {
          // Update the widget's isOnline state
          // Note: This will require a widget rebuild to reflect the change
        });
      }
    });

    // Add listener for conversation removal (unmatch)
    _socketService!.on('conversation_removed', (data) {
      if (!mounted) return;
      
      // Extract user IDs from the event
      final sender = data['sender'] as String?;
      final receiver = data['receiver'] as String?;
      
      // Only navigate if current user is the receiver (not the sender)
      if (_currentUserId == receiver) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation ended by the other user'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    // Modify image_viewed event handler
    _socketService!.on('image_viewed', (data) {
      if (!mounted) return;
      
      try {
        final messageId = data['messageId'];
        final viewedAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        final disappearingTime = data['disappearingTime'];
        final isDisappearing = data['isDisappearing'] ?? false;
        
        // Check if message exists in state when image_viewed is received
        final state = context.read<ConversationBloc>().state;
        if (state is ConversationLoaded) {
          final messageExists = state.messages.any((msg) => msg.id == messageId);
          
          if (!messageExists) {
            // Try to find the message by content (image URL) instead of ID
            final messageByContent = state.messages.where((msg) => 
                msg.type == MessageType.image && 
                msg.isDisappearing && 
                msg.disappearingTime == disappearingTime
            ).toList();
            
            if (messageByContent.isNotEmpty) {
              final localMessage = messageByContent.first;
              
              // Update the message ID in the state
              context.read<ConversationBloc>().add(UpdateMessageId(
                oldMessageId: localMessage.id,
                newMessageId: messageId,
              ));
            }
          }
        }
        
        // Update the message state with viewed timestamp
        context.read<ConversationBloc>().add(MessageViewed(
          messageId,
          viewedAt,
        ));

        // Start the disappearing timer (for sender only)
        if (isDisappearing && disappearingTime != null) {
          _startDisappearingImageTimer(messageId, disappearingTime);
        }
      } catch (e) {
        // Error processing image_viewed event
      }
    });

    // Add listener for room joining confirmation
    _socketService!.on('joined_room', (data) {
      // Joined room
    });

    // Add listener for room joining error
    _socketService!.on('join_error', (data) {
      // Failed to join room
    });

    // Add bulk message status listeners
    _socketService!.on('bulk_message_delivered', (data) {
      if (!mounted) return;
      try {
        final messageIds = List<String>.from(data['messageIds'] ?? []);
        final deliveredAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        
        if (messageIds.isNotEmpty) {
          context.read<ConversationBloc>().add(BulkMessageDelivered(
            messageIds: messageIds,
            deliveredAt: deliveredAt,
          ));
        }
      } catch (e) {
        // Error processing bulk_message_delivered event
      }
    });

    _socketService!.on('bulk_message_read', (data) {
      if (!mounted) return;
      try {
        final messageIds = List<String>.from(data['messageIds'] ?? []);
        final readAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        
        if (messageIds.isNotEmpty) {
          context.read<ConversationBloc>().add(BulkMessageRead(
            messageIds: messageIds,
            readAt: readAt,
          ));
        }
      } catch (e) {
        // Error processing bulk_message_read event
      }
    });

    // Debounce timer for typing events
    Timer? _typingDebounce;
    
    _socketService!.on('private_message', (data) async {
      if (!mounted) return;
      try {
        // Decrypt message if it's encrypted
        Map<String, dynamic> decryptedData = data;
        if (data['encryptedContent'] != null && data['encryptionMetadata'] != null) {
          AppLogger.info('🔵 Attempting to decrypt encrypted message');
          AppLogger.info('🔵 Message data: $data');
          
          try {
            final senderId = data['sender']?.toString() ?? data['from']?.toString() ?? '';
            AppLogger.info('🔵 Sender ID: $senderId');
            AppLogger.info('🔵 Current user ID: $_currentUserId');
            AppLogger.info('🔵 Conversation ID: ${widget.conversationId}');
            
            if (senderId.isNotEmpty) {
              AppLogger.info('🔵 Calling decryptMessage with senderId: $senderId');
              decryptedData = await _socketService!.decryptMessage(data, senderId);
              AppLogger.info('✅ Successfully decrypted message');
              AppLogger.info('🔵 Decrypted content: ${decryptedData['content']}');
            } else {
              AppLogger.error('❌ Sender ID is empty, cannot decrypt');
            }
          } catch (e) {
            AppLogger.error('❌ Failed to decrypt message: $e');
            AppLogger.error('❌ Error stack trace: ${StackTrace.current}');
            // Continue with encrypted data, will show decryption error
          }
        } else {
          AppLogger.info('🔵 Message is not encrypted, processing normally');
        }
        
        // Store the server's message ID
        final serverMessageId = decryptedData['_id']?.toString() ?? decryptedData['id']?.toString();
        // Parse the server's timestamp
        final serverTimestamp = decryptedData['createdAt']?.toString() ?? decryptedData['timestamp']?.toString();
        // Convert dynamic map to Map<String, dynamic>
        final Map<String, dynamic> messageData = {
          '_id': serverMessageId,
          'sender': decryptedData['sender']?.toString() ?? decryptedData['from']?.toString(),
          'receiver': decryptedData['receiver']?.toString() ?? decryptedData['to']?.toString(),
          'content': decryptedData['content']?.toString() ?? '',
          'createdAt': serverTimestamp, // Use server's timestamp
          'messageType': decryptedData['messageType']?.toString() ?? 'text',
          'status': decryptedData['status']?.toString() ?? 'sent',
        };
        
        // Add encryption fields if present
        if (data['encryptedContent'] != null) {
          messageData['encryptedContent'] = data['encryptedContent'];
        }
        if (data['encryptionMetadata'] != null) {
          messageData['encryptionMetadata'] = data['encryptionMetadata'];
        }
        if (decryptedData['decryptionError'] == true) {
          messageData['decryptionError'] = true;
        }
        
        // Only set disappearing properties for image messages
        final messageType = decryptedData['messageType']?.toString() ?? 'text';
        if (messageType == 'image') {
          messageData['isDisappearing'] = decryptedData['isDisappearing'];
          messageData['disappearingTime'] = decryptedData['disappearingTime'];
        }
        
        // Handle metadata conversion properly
        if (decryptedData['metadata'] != null) {
          if (decryptedData['metadata'] is Map) {
            messageData['metadata'] = Map<String, dynamic>.from(decryptedData['metadata']);
          } else {
            // If metadata is not a Map, try to convert it
            messageData['metadata'] = {'raw': decryptedData['metadata'].toString()};
          }
        }
        
        final msg = Message.fromJson(messageData);
        
        // Only process messages from the other participant
        if (msg.sender != _currentUserId) {
          // Check for scam alerts in text messages
          if (msg.type == MessageType.text && msg.content.isNotEmpty) {
            _messageCount++;
            _checkForScamAlert(msg.content, true);
          }
          
          context.read<ConversationBloc>().add(MessageReceived(msg));
          context.read<ConversationBloc>().add(ConversationUpdated(
            conversationId: widget.conversationId,
            lastMessage: msg,
            updatedAt: DateTime.now(),
          ));
          // Mark message as delivered immediately after receiving
          if (_socketService != null && !_processedMessageIds.contains(msg.id)) {
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
            }
          });
        }
      } catch (e) {
        // Error processing received message
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
      try {
        final messageId = data['messageId'];
        final deliveredAt = data['deliveredAt'] != null 
            ? DateTime.parse(data['deliveredAt']) 
            : DateTime.now();
        
        context.read<ConversationBloc>().add(MessageDelivered(
          messageId,
          deliveredAt,
        ));
      } catch (e) {
        // Error processing message_delivered event
      }
    });

    _socketService!.on('message_read', (data) {
      if (!mounted) return;
      try {
        final messageId = data['messageId'];
        final readAt = data['timestamp'] != null 
            ? DateTime.parse(data['timestamp']) 
            : DateTime.now();
        
        context.read<ConversationBloc>().add(MessageRead(
          messageId,
          readAt,
        ));
      } catch (e) {
        // Error processing message_read event
      }
    });

    // Removed redundant new_message handler - private_message handler already processes all messages
  }

  void _showImagePicker() {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF234481),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      builder: (context) {
        int selectedTime = 5; // Default disappearing time
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  const Text(
                    'Send Disappearing Image',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DisappearingTimeSelector(
                    selectedTime: selectedTime,
                    onTimeSelected: (time) {
                      setState(() {
                        selectedTime = time;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80, // Compress image to reduce size
                                maxWidth: 1920, // Limit max width
                                maxHeight: 1920, // Limit max height
                              );
                              
                              if (image != null) {
                                // Verify file exists and check format
                                final file = File(image.path);
                                if (await file.exists()) {
                                  final fileSize = await file.length();
                                  
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
                                  throw Exception('Selected image file does not exist');
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error selecting image: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF35548b),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_library, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Gallery',
                                style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 80, // Compress image to reduce size
                                maxWidth: 1920, // Limit max width
                                maxHeight: 1920, // Limit max height
                              );
                              
                              if (image != null) {
                                // Verify file exists and check format
                                final file = File(image.path);
                                if (await file.exists()) {
                                  final fileSize = await file.length();
                                  
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
                                  throw Exception('Captured image file does not exist');
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error capturing image: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C5C8A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Camera',
                                style: TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
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
    if (_socketService != null && _currentUserId != null) {
      try {
        // Show upload status
        setState(() {
          _isUploadingImage = true;
          _uploadStatus = 'Uploading image...';
        });
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
        if (response.statusCode == 200) {
          // Update status to sending message
          setState(() {
            _uploadStatus = 'Sending message...';
          });
          
          final imageUrl = response.data['imageUrl'];
          final imageKey = response.data['imageKey'] ?? response.data['key'] ?? response.data['s3Key'];
          final imageSize = response.data['imageSize'] ?? response.data['size'] ?? response.data['fileSize'];
          final imageType = response.data['imageType'] ?? response.data['type'] ?? response.data['mimeType'] ?? response.data['contentType'];
          
          // Validate that we have the required values
          if (imageUrl == null) {
            throw Exception('No imageUrl in upload response');
          }
          
          // Provide fallback values if not provided by upload response
          final finalImageKey = imageKey ?? _extractImageKeyFromUrl(imageUrl);
          final finalImageSize = imageSize ?? await _getFileSize(imagePath);
          final finalImageType = imageType ?? _getMimeTypeFromExtension(imagePath);
          
          // Make POST /api/messages call with complete payload
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
          
          // Extract expiresAt from API response metadata
          String? expiresAt;
          if (messageResponse.statusCode == 200 || messageResponse.statusCode == 201) {
            final responseData = messageResponse.data;
            
            if (responseData['metadata'] != null) {
              if (responseData['metadata']['expiresAt'] != null) {
                expiresAt = responseData['metadata']['expiresAt'] as String;
              }
            }
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
              }
            } catch (e) {
              // Failed to extract expiration from S3 URL
            }
          }
          
          if (messageResponse.statusCode != 200 && messageResponse.statusCode != 201) {
            // Continue with socket event even if API call fails
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
          _socketService!.emit('private_message', messageData);
          
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
          
          final msg = Message.fromJson(messageJson);
          context.read<ConversationBloc>().add(MessageSent(msg));
          
          // Invalidate inbox cache since we sent an image message
          final apiCacheService = ApiCacheService();
          if (_currentUserId != null) {
            apiCacheService.invalidateCache('unified_conversations_$_currentUserId');
            AppLogger.info('🔵 Unified cache invalidated due to image message sent');
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
          
          // Clear upload status on success
          setState(() {
            _isUploadingImage = false;
            _uploadStatus = '';
          });
        } else {
          // Clear upload status on failure
          setState(() {
            _isUploadingImage = false;
            _uploadStatus = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send image. Please try again.')),
          );
        }
      } catch (e) {
        // Clear upload status on error
        setState(() {
          _isUploadingImage = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send image. Please try again.')),
        );
      }
    } else {
      // Clear upload status on connection error
      setState(() {
        _isUploadingImage = false;
        _uploadStatus = '';
      });
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
                title: const Text('Image'),
                onTap: () {
                  AppLogger.info('🔵 Image option tapped');
                  Navigator.pop(context);
                  _showImagePicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Voice Message'),
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
        // First try to find by exact content match
        try {
          message = state.messages.firstWhere(
            (msg) => msg.content == imageUrl && msg.type == MessageType.image,
            orElse: () => throw Exception('Exact content match not found'),
          );
        } catch (e) {
          // Fallback: try to find by image key pattern if exact match fails
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.path.split('/');
          if (pathSegments.length >= 2) {
            final imageKey = pathSegments.sublist(pathSegments.length - 2).join('/');
            
            final matchingMessages = state.messages.where((msg) => 
                msg.type == MessageType.image && 
                msg.content.contains(imageKey)
            ).toList();
            
            if (matchingMessages.isNotEmpty) {
              // If multiple matches, prefer the most recent one
              message = matchingMessages.first;
            } else {
              throw Exception('No message found with image key pattern: $imageKey');
            }
          } else {
            throw Exception('Invalid image URL format: $imageUrl');
          }
        }

        // Emit image_viewed event
        if (_socketService != null && !isSender) {
          _socketService!.sendImageViewed(message.id, widget.conversationId);
        }
      }
      
      // Use the original URL directly - refresh will be called only if we get 403 error
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
        // Try to find by the original content URL pattern
        try {
          message = state.messages.firstWhere(
            (msg) => msg.type == MessageType.image && 
                     (msg.content.contains('messages/') || imageUrl.contains('messages/')),
            orElse: () => throw Exception('Pattern match not found'),
          );
        } catch (e) {
          // Last resort: try to find any image message
          final imageMessages = state.messages.where((msg) => msg.type == MessageType.image).toList();
          if (imageMessages.isNotEmpty) {
            message = imageMessages.first;
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
      _socketService?.sendImageViewed(message.id, widget.conversationId);
    }

    _currentlyOpenImageId = message.id; // Set which image is currently open in full-screen

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async {
              _currentlyOpenImageId = null; // Reset when closing
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
    // Validate message ID
    if (messageId.isEmpty) {
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
    
    return Scaffold(
      backgroundColor: const Color(0xFF234481),
      appBar: AppBar(
        backgroundColor: const Color(0xFF234481),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 18.0),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    _formatOnlineStatus(),
                    style: TextStyle(
                      color: widget.isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Nunito',
                    ),
                  ),
              ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _toggleMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Conversation Starter Widget
              ConversationStarterWidget(
                matchUserId: widget.conversationId,
                priorMessages: _getRecentMessages(),
                onSuggestionSelected: _onConversationStarterSelected,
              ),
              Expanded(
                child: BlocListener<ConversationBloc, ConversationState>(
              listener: (context, state) {
                if (state is ConversationLoaded) {
                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  // Initialize display timers for disappearing image messages
                  for (final message in state.messages) {
                    if (message.isDisappearing && 
                        message.disappearingTime != null && 
                        message.type == MessageType.image &&
                        !_disappearingImageManager.hasTimer(message.id)) {
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
                    // Close side menu if open
                    if (_isMenuOpen) {
                      setState(() {
                        _isMenuOpen = false;
                        _menuAnimationController.reverse();
                      });
                    }
                    
                    // Navigate after ensuring menu is closed
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Conversation ended')),
                        );
                      }
                    });
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
                  // Message List with Loading Overlay - Only rebuilds when messages change
                  Expanded(
                    child: Stack(
                      children: [
                        // Existing BlocSelector (unchanged for performance)
                        BlocSelector<ConversationBloc, ConversationState, List<Message>>(
                          selector: (state) => state is ConversationLoaded ? state.messages : [],
                          builder: (context, messages) {
                            return NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
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
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final message = messages[index];
                                  final isMe = message.sender == _currentUserId;
                                  
                                  // TODO: Temporarily commented out message read processing
                                  // Emit message_read when message is visible and from other user
                                  /*
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
                                  */
                                  
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
                        
                        // Loading indicator overlay
                        BlocSelector<ConversationBloc, ConversationState, bool>(
                          selector: (state) => state is ConversationLoading,
                          builder: (context, isLoading) {
                            if (!isLoading) return const SizedBox.shrink();
                            
                            return Container(
                              color: const Color(0xFF234481).withOpacity(0.8),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Nunito',
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
      // Add side menu overlay with backdrop
      if (_isMenuOpen) _buildSideMenuWithBackdrop(Conversation(
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
    final size = MediaQuery.of(context).size;
    final buttonSize = (size.width * 0.08).clamp(32.0, 36.0); // Smaller, more compact buttons
    final inputPadding = (size.width * 0.015).clamp(6.0, 12.0); // Reduced padding
    
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload status indicator
          if (_isUploadingImage)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uploadStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Main input container
          Container(
            padding: EdgeInsets.all(inputPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF234481),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Plus button - smaller and more subtle
                  IconButton(
                    icon: Icon(
                      Icons.add, 
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    onPressed: _showOptionsMenu,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  // Text input - takes most space
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: Colors.white60,
                          fontFamily: 'Nunito',
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      maxLines: null, // Allow unlimited lines
                      minLines: 1, // Start with single line
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                        if (!_isTyping && text.isNotEmpty) {
                          setState(() => _isTyping = true);
                          _socketService?.emit('typing', {'to': widget.conversationId});
                        } else if (_isTyping && text.isEmpty) {
                              setState(() => _isTyping = false);
    _socketService?.emit('stop_typing', {'to': widget.conversationId});
  }

  // Test function to send a simple message without E2EE
  void _sendTestMessage() {
    if (_socketService != null && _currentUserId != null) {
      AppLogger.info('🔵 Sending test message');
      final messageData = {
        '_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'from': _currentUserId,
        'to': widget.conversationId,
        'content': 'Test message ${DateTime.now()}',
        'messageType': 'text',
        'status': 'sent',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      AppLogger.info('🔵 Test message data: ${messageData.toString()}');
      _socketService!.emit('private_message', messageData);
      AppLogger.info('✅ Test message emitted');
    } else {
      AppLogger.error('❌ Cannot send test message: Socket or user ID is null');
    }
  }
},
                      onEditingComplete: () {
                        setState(() => _isTyping = false);
                        _socketService?.emit('stop_typing', {'to': widget.conversationId});
                      },
                    ),
                  ),
                  // Send button - smaller and more subtle
                  IconButton(
                    icon: Icon(
                      Icons.send, 
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    onPressed: _sendTextMessage,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scam Alert Popup
          if (_showScamAlert && _currentScamAlert != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: ScamAlertPopup(
                alertType: _currentScamAlert!,
                onDismiss: _dismissScamAlert,
                onReport: _reportScamAlert,
                onLearnMore: _learnMoreAboutScam,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSideMenuWithBackdrop(Conversation conversation) {
    return Stack(
      children: [
        // Invisible layer for touch outside to close (no visual backdrop)
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        // Side menu
        _buildSideMenu(conversation),
      ],
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
              color: const Color(0xFF234481),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chat Options',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _toggleMenu,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // TODO: Uncomment these features when implemented
                  // ListTile(
                  //   leading: const Icon(Icons.card_giftcard, color: Colors.white),
                  //   title: const Text(
                  //     'Buy Gift',
                  //     style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                  //   ),
                  //   onTap: () {
                  //     // Handle buy gift
                  //   },
                  // ),
                  // ListTile(
                  //   leading: const Icon(Icons.games, color: Colors.white),
                  //   title: const Text(
                  //     'Start Ice Breaker Game',
                  //     style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                  //   ),
                  //   onTap: () {
                  //     // Handle start game
                  //   },
                  // ),
                  // ListTile(
                  //   leading: const Icon(Icons.casino, color: Colors.white),
                  //   title: const Text(
                  //     'Start Fantasy Game',
                  //     style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                  //   ),
                  //   onTap: () {
                  //     // Handle start fantasy game
                  //   },
                  // ),
                  // ListTile(
                  //   leading: const Icon(Icons.calendar_today, color: Colors.white),
                  //   title: const Text(
                  //     'Plan a Date',
                  //     style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                  //   ),
                  //   onTap: () {
                  //     // Handle plan date
                  //   },
                  // ),
                  // ListTile(
                  //   leading: const Icon(Icons.psychology, color: Colors.white),
                  //   title: const Text(
                  //     'Get Inference',
                  //     style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                  //   ),
                  //   onTap: () {
                  //     // Handle get inference
                  //   },
                  // ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.white),
                    title: const Text(
                      'Block User',
                      style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                    ),
                    onTap: () {
                      context.read<ConversationBloc>().add(
                        BlockUser(userId: conversation.participantId),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.report, color: Colors.white),
                    title: const Text(
                      'Report',
                      style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ReportPage(
                            reportedUserId: widget.conversationId,
                            reportedUserName: widget.participantName,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.white),
                    title: const Text(
                      'Leave Conversation',
                      style: TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                    ),
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
    

    
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: statusIcon,
    );
  }

  String _formatOnlineStatus() {
    if (widget.isOnline) {
      return 'Online';
    } else if (widget.lastSeen != null) {
      try {
        final lastSeenDate = DateTime.parse(widget.lastSeen!);
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

  Widget _buildAvatar() {
    final size = MediaQuery.of(context).size;
    final avatarSize = (size.width * 0.08).clamp(32.0, 40.0); // Smaller avatar
    
    return CustomAvatar(
      name: widget.participantName,
      size: avatarSize,
      isOnline: widget.isOnline,
    );
  }

  // TODO: Uncomment when call feature is re-implemented
  // void _startCall(bool isAudioCall) {
  //   final channelName = '${widget.conversationId}_${DateTime.now().millisecondsSinceEpoch}';
    
  //   // Show call screen
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => CallScreen(
  //         channelName: channelName,
  //         isAudioCall: isAudioCall,
  //         participantName: widget.participantName,
  //         participantAvatar: widget.participantAvatar,
  //         onCallEnded: () {
  //           context.read<ConversationBloc>().add(EndCall(conversationId: widget.conversationId));
  //         },
  //       ),
  //     ),
  //   );

  //   // Notify bloc
  //   context.read<ConversationBloc>().add(
  //     isAudioCall
  //         ? StartAudioCall(conversationId: widget.conversationId)
  //         : StartVideoCall(conversationId: widget.conversationId),
  //   );
  // }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) {
      AppLogger.warning('Attempted to send empty message');
      return;
    }

    final content = _messageController.text.trim();
    final isAISuggested = _isAISuggestedMessage(content);
    
    // Content moderation check
    final moderationService = ContentModerationService();
    final moderationResult = moderationService.moderateContent(content, ContentType.message);
    
    if (!moderationResult.isAppropriate) {
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message contains inappropriate content. Please revise your message.',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Report the inappropriate content
      if (_currentUserId != null) {
        moderationService.reportInappropriateContent(content, ContentType.message, _currentUserId!);
      }
      
      return; // Don't send the message
    }
    
    // Use filtered content if any filtering was applied
    final finalContent = moderationResult.filteredText;
    
    _messageController.clear();

    if (_socketService != null && _currentUserId != null) {
      try {
        AppLogger.info('🔵 Attempting to send message to: ${widget.conversationId}');
        AppLogger.info('🔵 Socket connected: ${_socketService!.isConnected}');
        AppLogger.info('🔵 Current user ID: $_currentUserId');
        
        // Try encrypted message first, fallback to regular message if it fails
        bool encryptedSent = false;
        try {
          // Send encrypted message through socket
          await _socketService!.sendEncryptedMessage(
            widget.conversationId,
            finalContent,
            'text',
          );
          encryptedSent = true;
          AppLogger.info('✅ Encrypted message sent successfully');
        } catch (e) {
          AppLogger.error('❌ Failed to send encrypted message: $e');
          AppLogger.info('🔄 Falling back to regular message sending');
          
          // Fallback to regular message sending
          final messageData = {
            '_id': DateTime.now().millisecondsSinceEpoch.toString(),
            'from': _currentUserId,
            'to': widget.conversationId,
            'content': finalContent,
            'messageType': 'text',
            'status': 'sent',
            'createdAt': DateTime.now().toIso8601String(),
          };
          
          AppLogger.info('🔵 Sending regular message: ${messageData.toString()}');
          _socketService!.emit('private_message', messageData);
          AppLogger.info('✅ Regular message sent successfully');
        }
        
        // Create message data for local state
        final messageData = {
          '_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'from': _currentUserId,
          'to': widget.conversationId,
          'content': finalContent,
          'messageType': 'text',
          'status': 'sent',
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        // Add message to local state immediately with 'sent' status
        final msg = Message.fromJson({
          '_id': messageData['_id'],
          'sender': messageData['from'],
          'receiver': messageData['to'],
          'content': messageData['content'],
          'createdAt': messageData['createdAt'],
          'messageType': messageData['messageType'],
          'status': 'sent',
          'timestamp': DateTime.now(),
          'isAISuggested': isAISuggested,
        });
        context.read<ConversationBloc>().add(MessageSent(msg));
        
        // Invalidate inbox cache since we sent a message
        final apiCacheService = ApiCacheService();
        if (_currentUserId != null) {
          apiCacheService.invalidateCache('unified_conversations_$_currentUserId');
          AppLogger.info('🔵 Unified cache invalidated due to message sent');
        }
        
        // Scroll to bottom after sending message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        
        AppLogger.info('✅ Message sent successfully (${encryptedSent ? 'encrypted' : 'regular'})');
      } catch (e) {
        AppLogger.error('❌ Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } else {
      AppLogger.error('❌ Cannot send message: Socket or user ID is null');
      AppLogger.error('❌ Socket service: ${_socketService != null}');
      AppLogger.error('❌ Current user ID: $_currentUserId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Please try again.')),
      );
    }

    setState(() => _isTyping = false);
    _socketService?.emit('stop_typing', {'to': widget.conversationId});
  }

  List<String> _getRecentMessages() {
    final state = context.read<ConversationBloc>().state;
    if (state is ConversationLoaded) {
      // Get the last 5 messages for context
      return state.messages
          .take(5)
          .where((message) => message.type == MessageType.text)
          .map((message) => message.content)
          .toList();
    }
    return [];
  }

  void _onConversationStarterSelected(String suggestion) {
    // Auto-fill the message input with the suggestion
    _messageController.text = suggestion;
    
    // Focus the input field
    FocusScope.of(context).requestFocus();
    
    // Select all text for easy editing
    _messageController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: suggestion.length,
    );
  }

  bool _isAISuggestedMessage(String content) {
    // Check if the current message content matches any recent conversation starter suggestions
    // This is a simple approach - in a more sophisticated implementation, you might
    // track the exact suggestions that were shown to the user
    final state = context.read<ConversationBloc>().state;
    if (state is ConversationLoaded) {
      // For now, we'll use a simple heuristic: if the message was just auto-filled
      // from a conversation starter, we can track this in a more sophisticated way
      // For this implementation, we'll assume that if the message content matches
      // a common conversation starter pattern, it might be AI-suggested
      return _isCommonConversationStarterPattern(content);
    }
    return false;
  }

  bool _isCommonConversationStarterPattern(String content) {
    // Simple heuristic to detect common conversation starter patterns
    final patterns = [
      "What's your favorite",
      "I noticed you",
      "Your bio mentions",
      "I see we both",
      "How do you like to",
      "What do you think about",
      "Have you ever",
      "Do you enjoy",
      "What's the best",
      "Tell me about",
    ];
    
    return patterns.any((pattern) => content.toLowerCase().startsWith(pattern.toLowerCase()));
  }
} 