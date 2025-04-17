import 'dart:async';
import 'dart:math';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  final Map<String, List<Message>> _messages = {};
  final Map<String, Conversation> _conversations = {
    '1': Conversation(
      id: '1',
      participantId: 'user1',
      participantName: 'Sarah',
      messages: [
        Message(
          id: 'm1',
          senderId: 'user1',
          content: 'Hey, how are you doing?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      isOnline: true,
      unreadCount: 1,
    ),
    '2': Conversation(
      id: '2',
      participantId: 'user2',
      participantName: 'Michael',
      messages: [
        Message(
          id: 'm2',
          senderId: 'user2',
          content: 'I saw you like photography too! What kind of camera do you use?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      isOnline: false,
      unreadCount: 0,
    ),
  };

  @override
  Future<List<Conversation>> getConversations() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _conversations.values.toList();
  }

  @override
  Future<Conversation> getConversation(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final conversation = _conversations[conversationId];
    if (conversation == null) {
      throw Exception('Conversation not found');
    }
    return conversation;
  }

  @override
  Future<void> sendTextMessage(String conversationId, String content) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'currentUser',
      content: content,
      timestamp: DateTime.now(),
    );
    
    _messages[conversationId]?.add(message);
    _messageControllers[conversationId]?.add(_messages[conversationId]!);
  }

  @override
  Future<void> sendVoiceMessage(String conversationId, String audioPath, Duration duration) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'currentUser',
      content: audioPath,
      timestamp: DateTime.now(),
      type: MessageType.voice,
      metadata: {'duration': duration.inSeconds},
    );
    
    _messages[conversationId]?.add(message);
    _messageControllers[conversationId]?.add(_messages[conversationId]!);
  }

  @override
  Future<void> sendFileMessage(String conversationId, String filePath, String fileName, int fileSize) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'currentUser',
      content: filePath,
      timestamp: DateTime.now(),
      type: MessageType.file,
      metadata: {
        'fileName': fileName,
        'fileSize': fileSize,
      },
    );
    
    _messages[conversationId]?.add(message);
    _messageControllers[conversationId]?.add(_messages[conversationId]!);
  }

  @override
  Future<void> sendImageMessage(String conversationId, String imagePath) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'currentUser',
      content: imagePath,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );
    
    _messages[conversationId]?.add(message);
    _messageControllers[conversationId]?.add(_messages[conversationId]!);
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would update the message status in the database
  }

  @override
  Future<void> blockUser(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would update the user's blocked status in the database
  }

  @override
  Future<void> unblockUser(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would update the user's blocked status in the database
  }

  @override
  Future<void> muteConversation(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would update the conversation's muted status in the database
  }

  @override
  Future<void> unmuteConversation(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would update the conversation's muted status in the database
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would remove the user from the conversation in the database
  }

  @override
  Future<void> startAudioCall(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would initiate an audio call
  }

  @override
  Future<void> startVideoCall(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would initiate a video call
  }

  @override
  Future<void> endCall(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would end the active call
  }

  @override
  Stream<List<Message>> listenToMessages(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId] = StreamController<List<Message>>.broadcast();
      _messages[conversationId] = [];
    }
    return _messageControllers[conversationId]!.stream;
  }

  void _notifyMessageListeners(String conversationId, List<Message> messages) {
    if (_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId]!.add(messages);
    }
  }

  void dispose() {
    for (var controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
    _messages.clear();
    _conversations.clear();
  }
} 