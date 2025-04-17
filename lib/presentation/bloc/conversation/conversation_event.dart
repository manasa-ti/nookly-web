import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/message.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversation extends ConversationEvent {
  final String conversationId;

  const LoadConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendTextMessage extends ConversationEvent {
  final String conversationId;
  final String content;

  const SendTextMessage(this.conversationId, this.content);

  @override
  List<Object?> get props => [conversationId, content];
}

class SendVoiceMessage extends ConversationEvent {
  final String conversationId;
  final String audioPath;
  final Duration duration;

  const SendVoiceMessage(this.conversationId, this.audioPath, this.duration);

  @override
  List<Object?> get props => [conversationId, audioPath, duration];
}

class SendFileMessage extends ConversationEvent {
  final String conversationId;
  final String filePath;
  final String fileName;
  final int fileSize;

  const SendFileMessage(
    this.conversationId,
    this.filePath,
    this.fileName,
    this.fileSize,
  );

  @override
  List<Object?> get props => [conversationId, filePath, fileName, fileSize];
}

class SendImageMessage extends ConversationEvent {
  final String conversationId;
  final String imagePath;

  const SendImageMessage(this.conversationId, this.imagePath);

  @override
  List<Object?> get props => [conversationId, imagePath];
}

class MarkMessageAsRead extends ConversationEvent {
  final String messageId;

  const MarkMessageAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class BlockUser extends ConversationEvent {
  final String userId;

  const BlockUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnblockUser extends ConversationEvent {
  final String userId;

  const UnblockUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MuteConversation extends ConversationEvent {
  final String conversationId;

  const MuteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class UnmuteConversation extends ConversationEvent {
  final String conversationId;

  const UnmuteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class LeaveConversation extends ConversationEvent {
  final String conversationId;

  const LeaveConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class StartAudioCall extends ConversationEvent {
  final String conversationId;

  const StartAudioCall(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class StartVideoCall extends ConversationEvent {
  final String conversationId;

  const StartVideoCall(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class EndCall extends ConversationEvent {
  final String conversationId;

  const EndCall(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
} 