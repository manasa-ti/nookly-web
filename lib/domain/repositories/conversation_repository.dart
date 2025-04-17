import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';

abstract class ConversationRepository {
  Future<List<Conversation>> getConversations();
  Future<Conversation> getConversation(String conversationId);
  Future<void> sendTextMessage(String conversationId, String content);
  Future<void> sendVoiceMessage(String conversationId, String audioPath, Duration duration);
  Future<void> sendFileMessage(String conversationId, String filePath, String fileName, int fileSize);
  Future<void> sendImageMessage(String conversationId, String imagePath);
  Future<void> markMessageAsRead(String messageId);
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
  Future<void> muteConversation(String conversationId);
  Future<void> unmuteConversation(String conversationId);
  Future<void> leaveConversation(String conversationId);
  Stream<List<Message>> listenToMessages(String conversationId);
  Future<void> startAudioCall(String conversationId);
  Future<void> startVideoCall(String conversationId);
  Future<void> endCall(String conversationId);
} 