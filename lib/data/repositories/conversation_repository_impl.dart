import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart'; // Use NetworkService
import 'package:nookly/core/utils/logger.dart'; // Add logger import
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/domain/repositories/conversation_repository.dart';
import 'package:nookly/domain/repositories/auth_repository.dart'; // Still needed for currentUserId
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/core/services/key_management_service.dart';
import 'package:nookly/core/utils/e2ee_utils.dart'; 

class ConversationRepositoryImpl implements ConversationRepository {
  // Dio instance is now managed by NetworkService
  final AuthRepository _authRepository; // Still needed for currentUserId
  final KeyManagementService? _keyManagementService;

  final Map<String, StreamController<List<Message>>> _messageControllers = {};

  ConversationRepositoryImpl(this._authRepository, {KeyManagementService? keyManagementService}) 
    : _keyManagementService = keyManagementService; // Updated constructor

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      final User? currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Current user not found for conversation context.');
      }
      final String currentUserId = currentUser.id;

      // NetworkService interceptor handles token and base URL
      final response = await NetworkService.dio.get('/messages/conversations'); // Endpoint path

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> apiResponseData = response.data as List<dynamic>;
        final List<Conversation> conversations = [];

        for (var item in apiResponseData) {
          final itemMap = item as Map<String, dynamic>;
          final userJson = itemMap['user'] as Map<String, dynamic>; 
          final lastMessageJson = itemMap['lastMessage'] as Map<String, dynamic>?;

          Message? lastMessage;
          DateTime lastMessageTime;

          if (lastMessageJson != null) {
            // Ensure required fields are present in the message data
            final messageData = Map<String, dynamic>.from(lastMessageJson);
            if (!messageData.containsKey('sender')) {
              messageData['sender'] = userJson['_id'] as String; // Use conversation user as sender
            }
            if (!messageData.containsKey('receiver')) {
              messageData['receiver'] = currentUserId; // Use current user as receiver
            }
            // Convert messageType to type enum
            if (messageData.containsKey('messageType')) {
              messageData['type'] = messageData['messageType'] == 'image' ? 'image' : 'text';
            }
            lastMessage = Message.fromJson(messageData);
            
            // Handle disappearing images logic
            if (lastMessage.isDisappearing && lastMessage.type == MessageType.image) {
              final isViewed = lastMessage.metadata?.containsKey('viewedAt') == true;
              final disappearingTime = lastMessage.disappearingTime ?? 5;
              
              if (isViewed) {
                // Check if the image has expired since being viewed
                final viewedAt = DateTime.parse(lastMessage.metadata!['viewedAt']!);
                final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
                
                if (elapsedSeconds >= disappearingTime) {
                  AppLogger.info('Disappearing image has expired, not showing in conversation list');
                  lastMessage = null; // Don't show expired disappearing images
                } else {
                  AppLogger.info('Disappearing image is still valid, showing in conversation list');
                }
              } else {
                // Unviewed disappearing image - show placeholder
                AppLogger.info('Unviewed disappearing image, showing placeholder');
                // Keep the message but it will show as "Photo" in the UI
              }
            }
            
            lastMessageTime = lastMessage?.timestamp ?? DateTime.now();
          } else {
            lastMessageTime = DateTime.now();
          }
          
          final participantIdFromJson = userJson['_id'] as String;

          conversations.add(Conversation(
            id: participantIdFromJson, 
            participantId: participantIdFromJson, 
            participantName: userJson['name'] as String? ?? 'Unknown',
            participantAvatar: userJson['profile_pic'] as String?,
            messages: lastMessage != null ? [lastMessage] : [],
            lastMessageTime: lastMessageTime,
            isOnline: userJson['isOnline'] as bool? ?? false, 
            unreadCount: itemMap['unreadCount'] as int? ?? 0,
            userId: currentUserId,
            updatedAt: lastMessageTime,
          ));
        }
        return conversations;
      }
      
      throw Exception('Failed to load conversations: Status ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.info('DioError fetching conversations: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load conversations: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('Error fetching conversations: $e');
      throw Exception('Failed to load conversations: An unexpected error occurred: $e');
    }
  }

  @override
  Future<Conversation> getConversation(
    String participantId,
    // Receive participant details from the caller
    String participantName,
    String? participantAvatar,
    bool isOnline,
  ) async {
    try {
      final User? currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Current user not found to fetch conversation details.');
      }
      final String currentUserId = currentUser.id;

      final response = await NetworkService.dio.get('/messages/chat/$participantId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> messagesJson = response.data as List<dynamic>;
        final List<Message> messages = messagesJson
            .map((json) {
              AppLogger.info('🔵 Processing message from API:');
              AppLogger.info('🔵 - Message ID: ${json['_id']}');
              AppLogger.info('🔵 - Content: ${json['content']}');
              AppLogger.info('🔵 - Type: ${json['type']}');
              AppLogger.info('🔵 - IsDisappearing: ${json['isDisappearing']}');
              AppLogger.info('🔵 - DisappearingTime: ${json['disappearingTime']}');
              AppLogger.info('🔵 - Full JSON: $json');
              
              return Message.fromJson({
                '_id': json['_id'],
                'sender': json['sender'],
                'receiver': json['receiver'],
                'content': json['content'],
                'createdAt': json['createdAt'],
                'type': json['type'],
                'isRead': json['isRead'],
                'status': json['status'],
                'isDisappearing': json['isDisappearing'],
                'disappearingTime': json['disappearingTime'],
                'updatedAt': json['updatedAt'],
              });
            })
            .toList();

        // Filter out expired disappearing images
        final filteredMessages = messages.where((message) {
          if (message.isDisappearing && message.type == MessageType.image) {
            final isViewed = message.metadata?.containsKey('viewedAt') == true;
            final disappearingTime = message.disappearingTime ?? 5;
            
            if (isViewed) {
              // Check if the image has expired since being viewed
              final viewedAt = DateTime.parse(message.metadata!['viewedAt']!);
              final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
              
              if (elapsedSeconds >= disappearingTime) {
                AppLogger.info('Filtering out expired disappearing image: ${message.id}');
                return false; // Filter out expired disappearing images
              }
            }
            // Keep unviewed disappearing images and valid viewed ones
          }
          return true; // Keep all other messages
        }).toList();

        filteredMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        DateTime lastMessageTime = DateTime.now();
        if (filteredMessages.isNotEmpty) {
          lastMessageTime = filteredMessages.last.timestamp;
        }

        return Conversation(
          id: participantId, 
          participantId: participantId, 
          // Use passed-in details
          participantName: participantName, 
          participantAvatar: participantAvatar,
          messages: filteredMessages,
          lastMessageTime: lastMessageTime,
          isOnline: isOnline, 
          unreadCount: 0, // API doesn't provide this for chat history endpoint
          userId: currentUserId,
          updatedAt: lastMessageTime,
        );
      } else {
        throw Exception('Failed to load chat history: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.info('DioError fetching chat history for $participantId: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load chat history: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('Error fetching chat history for $participantId: $e');
      throw Exception('Failed to load chat history: An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> sendTextMessage(String conversationId, String content) async {
    // conversationId here is the participantId (receiverId for the message)
    try {
      await NetworkService.dio.post(
        '/messages',
        data: {
          'receiver': conversationId, 
          'content': content,
          'messageType': 'text',
        },
      );
    } on DioException catch (e) {
      AppLogger.info('DioError sending message: ${e.response?.data ?? e.message}');
      throw Exception('Failed to send message: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('Error sending message: $e');
      throw Exception('Failed to send message: An unexpected error occurred.');
    }
  }

  @override
  Future<void> sendVoiceMessage(String conversationId, String audioPath, Duration duration) async {
    throw UnimplementedError('sendVoiceMessage not implemented with API yet.');
  }

  @override
  Future<void> sendFileMessage(String conversationId, String filePath, String fileName, int fileSize) async {
    throw UnimplementedError('sendFileMessage not implemented with API yet.');
  }

  @override
  Future<void> sendImageMessage(String conversationId, String imagePath) async {
    try {
      AppLogger.info('debug disappearing: Starting image upload process');
      AppLogger.info('debug disappearing: Base URL from NetworkService: ${NetworkService.baseUrl}');
      
      // Create form data for the image upload
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'receiver': conversationId,
        'messageType': 'image',
        'isDisappearing': true,
        'disappearingTime': 5, // Default to 5 seconds
      });

      // Log the full URL that will be used
      final fullUrl = '${NetworkService.baseUrl}messages/upload-image';
      AppLogger.info('debug disappearing: Full URL for upload: $fullUrl');
      AppLogger.info('debug disappearing: Form data fields: ${formData.fields}');

      // Upload the image - use the full URL
      final response = await NetworkService.dio.post(
        'messages/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => true, // Accept all status codes for debugging
        ),
      );

      AppLogger.info('debug disappearing: Response status: ${response.statusCode}');
      AppLogger.info('debug disappearing: Response data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }

      // Log the complete response structure to understand what fields are available
      AppLogger.info('debug disappearing: Upload response data structure:');
      AppLogger.info('debug disappearing: - Response data type: ${response.data.runtimeType}');
      AppLogger.info('debug disappearing: - Response data keys: ${response.data.keys.toList()}');
      AppLogger.info('debug disappearing: - Full response data: ${response.data}');

      // The response should contain the image URL and message data
      final imageUrl = response.data['imageUrl'];
      final imageKey = response.data['imageKey'] ?? response.data['key'] ?? response.data['s3Key'];
      final imageSize = response.data['imageSize'] ?? response.data['size'] ?? response.data['fileSize'];
      final imageType = response.data['imageType'] ?? response.data['type'] ?? response.data['mimeType'] ?? response.data['contentType'];
      
      if (imageUrl == null) {
        throw Exception('No image URL in response');
      }

      AppLogger.info('debug disappearing: Extracted values:');
      AppLogger.info('debug disappearing: - imageUrl: $imageUrl');
      AppLogger.info('debug disappearing: - imageKey: $imageKey');
      AppLogger.info('debug disappearing: - imageSize: $imageSize');
      AppLogger.info('debug disappearing: - imageType: $imageType');

      // Provide fallback values if not provided by upload response
      final finalImageKey = imageKey ?? _extractImageKeyFromUrl(imageUrl);
      final finalImageSize = imageSize ?? await _getFileSize(imagePath);
      final finalImageType = imageType ?? _getMimeTypeFromExtension(imagePath);

      AppLogger.info('debug disappearing: Final values for POST /messages:');
      AppLogger.info('debug disappearing: - imageUrl: $imageUrl');
      AppLogger.info('debug disappearing: - imageKey: $finalImageKey');
      AppLogger.info('debug disappearing: - imageSize: $finalImageSize');
      AppLogger.info('debug disappearing: - imageType: $finalImageType');

      // Send the message with the image URL and metadata
      final messageUrl = '${NetworkService.baseUrl}messages';
      AppLogger.info('debug disappearing: Full URL for message: $messageUrl');
      
      final messageResponse = await NetworkService.dio.post(
        'messages',
        data: {
          'receiver': conversationId, // API expects 'receiver' field
          'content': '', // Can be empty for image messages
          'messageType': 'image',
          'imageUrl': imageUrl,
          'imageKey': finalImageKey,
          'imageSize': finalImageSize,
          'imageType': finalImageType,
          'isDisappearing': true,
          'disappearingTime': 5, // Default to 5 seconds
        },
        options: Options(
          validateStatus: (status) => true, // Accept all status codes for debugging
        ),
      );
      
      AppLogger.info('debug disappearing: Message creation response status: ${messageResponse.statusCode}');
      AppLogger.info('debug disappearing: Message creation response data: ${messageResponse.data}');
      
      if (messageResponse.statusCode != 200 && messageResponse.statusCode != 201) {
        AppLogger.info('debug disappearing: Failed to create message record: ${messageResponse.statusCode}');
        AppLogger.info('debug disappearing: Error response data: ${messageResponse.data}');
        AppLogger.info('debug disappearing: Request payload was: ${messageResponse.requestOptions.data}');
        throw Exception('Failed to create message record: ${messageResponse.statusMessage}');
      }
      
      AppLogger.info('debug disappearing: Message sent successfully');
    } on DioException catch (e) {
      AppLogger.info('debug disappearing: DioException details:');
      AppLogger.info('debug disappearing: - Type: ${e.type}');
      AppLogger.info('debug disappearing: - Message: ${e.message}');
      AppLogger.info('debug disappearing: - Response: ${e.response?.data}');
      AppLogger.info('debug disappearing: - Request: ${e.requestOptions.uri}');
      throw Exception('Failed to send image message: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('debug disappearing: General error: $e');
      throw Exception('Failed to send image message: An unexpected error occurred.');
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
      AppLogger.info('debug disappearing: Failed to extract image key from URL: $e');
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
      AppLogger.info('debug disappearing: Failed to get file size: $e');
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

  @override
  Future<void> markMessageAsRead(String messageId) async {
    throw UnimplementedError('markMessageAsRead not implemented with API yet.');
  }

  @override
  Future<void> blockUser(String userId) async {
    try {
      AppLogger.info('🔵 Blocking user: $userId');
      
      final response = await NetworkService.dio.post(
        '/users/block/$userId',
      );

      AppLogger.info('🔵 Block response: ${response.statusCode}');
      AppLogger.info('🔵 Block response data: ${response.data}');

      if (response.statusCode == 200) {
        AppLogger.info('✅ Successfully blocked user: $userId');
      } else {
        throw Exception('Failed to block user: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Error blocking user: $e');
      if (e is DioException) {
        throw Exception('Failed to block user: ${e.response?.data?['message'] ?? e.message}');
      }
      throw Exception('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    throw UnimplementedError('unblockUser not implemented with API yet.');
  }

  @override
  Future<void> muteConversation(String conversationId) async {
    throw UnimplementedError('muteConversation not implemented with API yet.');
  }

  @override
  Future<void> unmuteConversation(String conversationId) async {
    throw UnimplementedError('unmuteConversation not implemented with API yet.');
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    try {
      AppLogger.info('🔵 Leaving conversation (unmatching): $conversationId');
      
      final response = await NetworkService.dio.delete(
        '/users/unmatch/$conversationId',
      );

      AppLogger.info('🔵 Unmatch response: ${response.statusCode}');
      AppLogger.info('🔵 Unmatch response data: ${response.data}');

      if (response.statusCode == 200) {
        AppLogger.info('✅ Successfully unmatched with user: $conversationId');
      } else {
        throw Exception('Failed to unmatch: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Error leaving conversation (unmatching): $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw Exception('Profile not found or no match exists with this user');
        } else if (e.response?.statusCode == 500) {
          throw Exception('Server error during unmatch process');
        } else {
          throw Exception('Failed to unmatch: ${e.response?.data?['message'] ?? e.message}');
        }
      }
      throw Exception('Failed to unmatch: $e');
    }
  }

  @override
  Future<void> startAudioCall(String conversationId) async {
    throw UnimplementedError('startAudioCall not implemented with API yet.');
  }

  @override
  Future<void> startVideoCall(String conversationId) async {
    throw UnimplementedError('startVideoCall not implemented with API yet.');
  }

  @override
  Future<void> endCall(String conversationId) async {
    throw UnimplementedError('endCall not implemented with API yet.');
  }

  @override
  Stream<List<Message>> listenToMessages(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId] = StreamController<List<Message>>.broadcast();
      AppLogger.info('listenToMessages for $conversationId is using a mock stream controller.');
    }
    return _messageControllers[conversationId]!.stream;
  }

  @override
  Future<Map<String, dynamic>> getMessages({
    required String participantId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await NetworkService.dio.get(
        '/messages/chat/$participantId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      AppLogger.info('API Response data: ${response.data}');
      AppLogger.info('🔵 DEBUGGING API RESPONSE: Full API response structure');
      AppLogger.info('🔵 DEBUGGING API RESPONSE: - Response type: ${response.data.runtimeType}');
      AppLogger.info('🔵 DEBUGGING API RESPONSE: - Response keys: ${response.data.keys.toList()}');
      
      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Messages data: ${data['messages']}');
      
      // Debug individual messages in the response
      if (data['messages'] is List) {
        final messagesList = data['messages'] as List;
        AppLogger.info('🔵 DEBUGGING API RESPONSE: Found ${messagesList.length} messages in response');
        for (int i = 0; i < messagesList.length; i++) {
          final msg = messagesList[i];
          AppLogger.info('🔵 DEBUGGING API RESPONSE: Message $i: $msg');
          if (msg is Map<String, dynamic>) {
            AppLogger.info('🔵 DEBUGGING API RESPONSE: - Message $i keys: ${msg.keys.toList()}');
            AppLogger.info('🔵 DEBUGGING API RESPONSE: - Message $i isDisappearing: ${msg['isDisappearing']}');
            AppLogger.info('🔵 DEBUGGING API RESPONSE: - Message $i disappearingTime: ${msg['disappearingTime']}');
          }
        }
      }
      
      // Get current user ID once
      final currentUser = await _authRepository.getCurrentUser();
      final currentUserId = currentUser?.id;
      
      final messages = await Future.wait((data['messages'] as List)
          .map((msg) async {
            AppLogger.info('Processing message: $msg');
            if (msg is! Map<String, dynamic>) {
              AppLogger.info('Warning: Message is not a Map: $msg');
              msg = {'id': DateTime.now().millisecondsSinceEpoch.toString(), 'content': msg.toString()};
            }
            
            // Ensure required fields are present
            final messageData = Map<String, dynamic>.from(msg);
            if (!messageData.containsKey('sender')) {
              messageData['sender'] = participantId; // Use participantId as sender if missing
            }
            if (!messageData.containsKey('receiver')) {
              messageData['receiver'] = currentUserId; // Use current user as receiver if missing
            }
            
            // Add debugging for disappearing fields
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: Processing message from getMessages method');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Message ID: ${messageData['_id']}');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Raw isDisappearing: ${messageData['isDisappearing']}');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Raw disappearingTime: ${messageData['disappearingTime']}');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Full messageData: $messageData');
            
            final message = Message.fromJson(messageData);
            
            // Decrypt message if it's encrypted
            return await _decryptMessageIfNeeded(message, participantId);
          }));

      return {
        'messages': messages,
        'pagination': data['pagination'],
      };
    } catch (e) {
      AppLogger.info('Error getting messages: $e');
      rethrow;
    }
  }

  void dispose() {
    for (var controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
  }

  /// Decrypt a message if it's encrypted
  Future<Message> _decryptMessageIfNeeded(Message message, String senderId) async {
    if (!message.isEncrypted || message.encryptionMetadata == null) {
      return message; // Not encrypted, return as is
    }

    if (_keyManagementService == null) {
      AppLogger.error('Key management service not available for decryption');
      return message.copyWith(
        content: '[DECRYPTION FAILED - NO KEY SERVICE]',
        decryptionError: true,
      );
    }

    try {
      // Get conversation key
      final encryptionKey = await _keyManagementService!.getConversationKey(senderId);
      
      // Create the proper encrypted data structure
      final encryptedData = {
        'iv': message.encryptionMetadata!['iv'],
        'encryptedContent': message.encryptedContent,
        'authTag': message.encryptionMetadata!['authTag'],
      };
      AppLogger.info('🔵 Decrypting message from repository: $encryptedData');
      
      // Decrypt the message
      final decryptedContent = E2EEUtils.decryptMessage(
        encryptedData,
        encryptionKey
      );
      
      return message.copyWith(
        content: decryptedContent,
        decryptionError: false,
      );
    } catch (error) {
      AppLogger.error('Error decrypting message: $error');
      return message.copyWith(
        content: '[DECRYPTION FAILED]',
        decryptionError: true,
      );
    }
  }
} 