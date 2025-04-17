import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final Conversation conversation;
  final List<Message> messages;

  const ConversationLoaded({
    required this.conversation,
    required this.messages,
  });

  ConversationLoaded copyWith({
    Conversation? conversation,
    List<Message>? messages,
  }) {
    return ConversationLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [conversation, messages];
}

class ConversationLeft extends ConversationState {}

class AudioCallStarted extends ConversationState {}

class VideoCallStarted extends ConversationState {}

class CallEnded extends ConversationState {}

class ConversationError extends ConversationState {
  final String message;

  const ConversationError(this.message);

  @override
  List<Object?> get props => [message];
} 