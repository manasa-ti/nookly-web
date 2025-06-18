import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hushmate/core/network/network_service.dart'; // Use NetworkService
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:hushmate/domain/repositories/conversation_repository.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart'; // Still needed for currentUserId
import 'package:hushmate/domain/entities/user.dart'; 

class ConversationRepositoryImpl implements ConversationRepository {
  // Dio instance is now managed by NetworkService
  final AuthRepository _authRepository; // Still needed for currentUserId

  final Map<String, StreamController<List<Message>>> _messageControllers = {};

  ConversationRepositoryImpl(this._authRepository); // Updated constructor

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
            lastMessageTime = lastMessage.timestamp;
          } else {
            lastMessageTime = DateTime.fromMillisecondsSinceEpoch(0);
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
      print('DioError fetching conversations: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load conversations: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Error fetching conversations: $e');
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
            .map((json) => Message.fromJson({
                  '_id': json['_id'],
                  'sender': json['sender'],
                  'receiver': json['receiver'],
                  'content': json['content'],
                  'createdAt': json['createdAt'],
                  'messageType': json['messageType'],
                  'isRead': json['isRead'],
                  'status': json['status'],
                  'isDisappearing': json['isDisappearing'],
                  'updatedAt': json['updatedAt'],
                }))
            .toList();

        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        DateTime lastMessageTime = DateTime.fromMillisecondsSinceEpoch(0);
        if (messages.isNotEmpty) {
          lastMessageTime = messages.last.timestamp;
        }

        return Conversation(
          id: participantId, 
          participantId: participantId, 
          // Use passed-in details
          participantName: participantName, 
          participantAvatar: participantAvatar,
          messages: messages,
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
      print('DioError fetching chat history for $participantId: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load chat history: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Error fetching chat history for $participantId: $e');
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
      print('DioError sending message: ${e.response?.data ?? e.message}');
      throw Exception('Failed to send message: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Error sending message: $e');
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
      print('debug disappearing: Starting image upload process');
      print('debug disappearing: Base URL from NetworkService: ${NetworkService.baseUrl}');
      
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
      print('debug disappearing: Full URL for upload: $fullUrl');
      print('debug disappearing: Form data fields: ${formData.fields}');

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

      print('debug disappearing: Response status: ${response.statusCode}');
      print('debug disappearing: Response data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }

      // The response should contain the image URL and message data
      final imageUrl = response.data['imageUrl'];
      if (imageUrl == null) {
        throw Exception('No image URL in response');
      }

      print('debug disappearing: Image URL received: $imageUrl');

      // Send the message with the image URL
      final messageUrl = '${NetworkService.baseUrl}messages';
      print('debug disappearing: Full URL for message: $messageUrl');
      
      await NetworkService.dio.post(
        'messages',
        data: {
          'receiver': conversationId,
          'content': imageUrl,
          'messageType': 'image',
          'isDisappearing': true,
          'disappearingTime': 5, // Default to 5 seconds
        },
      );
      
      print('debug disappearing: Message sent successfully');
    } on DioException catch (e) {
      print('debug disappearing: DioException details:');
      print('debug disappearing: - Type: ${e.type}');
      print('debug disappearing: - Message: ${e.message}');
      print('debug disappearing: - Response: ${e.response?.data}');
      print('debug disappearing: - Request: ${e.requestOptions.uri}');
      throw Exception('Failed to send image message: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('debug disappearing: General error: $e');
      throw Exception('Failed to send image message: An unexpected error occurred.');
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    throw UnimplementedError('markMessageAsRead not implemented with API yet.');
  }

  @override
  Future<void> blockUser(String userId) async {
    throw UnimplementedError('blockUser not implemented with API yet.');
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
    throw UnimplementedError('leaveConversation not implemented with API yet.');
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
      print('listenToMessages for $conversationId is using a mock stream controller.');
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

      print('API Response data: ${response.data}');
      final data = response.data as Map<String, dynamic>;
      print('Messages data: ${data['messages']}');
      
      // Get current user ID once
      final currentUser = await _authRepository.getCurrentUser();
      final currentUserId = currentUser?.id;
      
      final messages = (data['messages'] as List)
          .map((msg) {
            print('Processing message: $msg');
            if (msg is! Map<String, dynamic>) {
              print('Warning: Message is not a Map: $msg');
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
            
            return Message.fromJson(messageData);
          })
          .toList();

      return {
        'messages': messages,
        'pagination': data['pagination'],
      };
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  void dispose() {
    for (var controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
  }
} 