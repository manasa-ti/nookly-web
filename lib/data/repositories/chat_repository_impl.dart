import 'package:hushmate/data/models/chat_conversation_model.dart';
import 'package:hushmate/domain/entities/chat_conversation.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:hushmate/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  // Mock data - using final to prevent accidental modifications
  final Map<String, Conversation> _mockConversations = {
    '1': Conversation(
      id: '1',
      participantId: 'user1',
      participantName: 'Sarah',
      participantAvatar: 'https://example.com/profile1.jpg',
      messages: [
        Message(
          id: 'm1',
          sender: 'user1',
          receiver: 'currentUser',
          content: 'Hey, how are you doing?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          type: MessageType.text,
        ),
        Message(
          id: 'm2',
          sender: 'currentUser',
          receiver: 'user1',
          content: 'I\'m good! How about you?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          type: MessageType.text,
        ),
        Message(
          id: 'm3',
          sender: 'user1',
          receiver: 'currentUser',
          content: 'Great! Would you like to grab coffee sometime?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          type: MessageType.text,
        ),
      ],
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 20)),
      isOnline: true,
      unreadCount: 1,
      userId: 'currentUser',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    '2': Conversation(
      id: '2',
      participantId: 'user2',
      participantName: 'Michael',
      participantAvatar: 'https://example.com/profile2.jpg',
      messages: [
        Message(
          id: 'm4',
          sender: 'user2',
          receiver: 'currentUser',
          content: 'I saw you like photography too! What kind of camera do you use?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: MessageType.text,
        ),
      ],
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      isOnline: false,
      unreadCount: 0,
      userId: 'currentUser',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  };

  @override
  Future<List<ChatConversation>> getConversations() async {
    // Mock data for now
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return [
      ChatConversationModel(
        id: '1',
        name: 'Sarah',
        profilePicture: 'https://example.com/profile1.jpg',
        lastMessage: 'Hey, how are you doing?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        unreadCount: 2,
        isOnline: true,
      ),
      ChatConversationModel(
        id: '2',
        name: 'Michael',
        profilePicture: 'https://example.com/profile2.jpg',
        lastMessage: 'I saw you like photography too! What kind of camera do you use?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isOnline: false,
      ),
      ChatConversationModel(
        id: '3',
        name: 'Jessica',
        profilePicture: 'https://example.com/profile3.jpg',
        lastMessage: 'That sounds like a great plan! Let me know when you\'re free.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
        isOnline: true,
      ),
      // Add more mock conversations as needed
    ];
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    // Mock implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual API call
  }

  @override
  Future<Conversation> getConversation(String conversationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final conversation = _mockConversations[conversationId];
    if (conversation == null) {
      throw Exception('Conversation not found');
    }
    return conversation;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final conversation = await getConversation(conversationId);
    return List.unmodifiable(conversation.messages); // Return immutable list
  }

  @override
  Future<Message> sendMessage(String conversationId, String content) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final conversation = _mockConversations[conversationId];
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    final newMessage = Message(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      sender: 'currentUser',
      receiver: conversationId,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    // Create a new conversation with the updated messages
    final updatedConversation = conversation.copyWith(
      messages: [...conversation.messages, newMessage],
      lastMessageTime: DateTime.now(),
    );
    
    // Update the mock data
    _mockConversations[conversationId] = updatedConversation;
    
    return newMessage;
  }
} 