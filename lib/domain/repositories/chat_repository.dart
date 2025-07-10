import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/message.dart';

abstract class ChatRepository {
  Future<Conversation> getConversation(String conversationId);
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> sendMessage(String conversationId, String content);
} 