part of 'conversation_bloc.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversation extends ConversationEvent {
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final bool isOnline;

  const LoadConversation({
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [participantId, participantName, participantAvatar, isOnline];
}

class LoadMoreMessages extends ConversationEvent {}

class SendTextMessage extends ConversationEvent {
  final String conversationId;
  final String content;

  const SendTextMessage({required this.conversationId, required this.content});

  @override
  List<Object?> get props => [conversationId, content];
}

class SendVoiceMessage extends ConversationEvent {
  final String conversationId;
  final String audioPath;
  final Duration duration;

  const SendVoiceMessage({
    required this.conversationId,
    required this.audioPath,
    required this.duration,
  });

  @override
  List<Object?> get props => [conversationId, audioPath, duration];
}

class SendFileMessage extends ConversationEvent {
  final String conversationId;
  final String filePath;
  final String fileName;
  final int fileSize;

  const SendFileMessage({
    required this.conversationId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });

  @override
  List<Object?> get props => [conversationId, filePath, fileName, fileSize];
}

class SendImageMessage extends ConversationEvent {
  final String conversationId;
  final String imagePath;

  const SendImageMessage({required this.conversationId, required this.imagePath});

  @override
  List<Object?> get props => [conversationId, imagePath];
}

class MarkMessageAsRead extends ConversationEvent {
  final String messageId;

  const MarkMessageAsRead({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class BlockUser extends ConversationEvent {
  final String userId;

  const BlockUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UnblockUser extends ConversationEvent {
  final String userId;

  const UnblockUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class MuteConversation extends ConversationEvent {
  final String conversationId;

  const MuteConversation({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class UnmuteConversation extends ConversationEvent {
  final String conversationId;

  const UnmuteConversation({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class LeaveConversation extends ConversationEvent {
  final String conversationId;

  const LeaveConversation({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class StartAudioCall extends ConversationEvent {
  final String conversationId;

  const StartAudioCall({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class StartVideoCall extends ConversationEvent {
  final String conversationId;

  const StartVideoCall({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class EndCall extends ConversationEvent {
  final String conversationId;

  const EndCall({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class MessageReceived extends ConversationEvent {
  final Message message;
  const MessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class MessageDelivered extends ConversationEvent {
  final String messageId;
  final DateTime deliveredAt;
  const MessageDelivered(this.messageId, this.deliveredAt);
  @override
  List<Object?> get props => [messageId, deliveredAt];
}

class MessageRead extends ConversationEvent {
  final String messageId;
  final DateTime readAt;
  const MessageRead(this.messageId, this.readAt);
  @override
  List<Object?> get props => [messageId, readAt];
}

class Typing extends ConversationEvent {
  final String fromUserId;
  const Typing(this.fromUserId);
  @override
  List<Object?> get props => [fromUserId];
}

class StopTyping extends ConversationEvent {
  final String fromUserId;
  const StopTyping(this.fromUserId);
  @override
  List<Object?> get props => [fromUserId];
}

class MessageEdited extends ConversationEvent {
  final String messageId;
  final String newContent;
  final DateTime editedAt;
  const MessageEdited(this.messageId, this.newContent, this.editedAt);
  @override
  List<Object?> get props => [messageId, newContent, editedAt];
}

class MessageDeleted extends ConversationEvent {
  final String messageId;
  const MessageDeleted(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

class MessageSent extends ConversationEvent {
  final Message message;
  const MessageSent(this.message);
  @override
  List<Object?> get props => [message];
}

class ConversationUpdated extends ConversationEvent {
  final String conversationId;
  final Message? lastMessage;
  final DateTime updatedAt;
  final bool? isTyping;

  ConversationUpdated({
    required this.conversationId,
    this.lastMessage,
    required this.updatedAt,
    this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, lastMessage, updatedAt, isTyping];
}

class UpdateCurrentUserId extends ConversationEvent {
  final String userId;
  const UpdateCurrentUserId(this.userId);
  @override
  List<Object?> get props => [userId];
} 