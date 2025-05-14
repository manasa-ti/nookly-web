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
            lastMessage = Message.fromJson(lastMessageJson);
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
          ));
        }
        return conversations;
      } else {
        throw Exception('Failed to load conversations: Status ${response.statusCode}');
      }
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
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();

        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
    throw UnimplementedError('sendImageMessage not implemented with API yet.');
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

  void dispose() {
    for (var controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
  }
} 