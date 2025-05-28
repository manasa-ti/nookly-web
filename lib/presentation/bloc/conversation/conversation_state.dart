part of 'conversation_bloc.dart';

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
  final bool hasMoreMessages;
  final bool isCallActive;
  final bool isAudioCall;

  const ConversationLoaded({
    required this.conversation,
    required this.messages,
    this.hasMoreMessages = false,
    this.isCallActive = false,
    this.isAudioCall = false,
  });

  @override
  List<Object?> get props => [conversation, messages, hasMoreMessages, isCallActive, isAudioCall];

  ConversationLoaded copyWith({
    Conversation? conversation,
    List<Message>? messages,
    bool? hasMoreMessages,
    bool? isCallActive,
    bool? isAudioCall,
  }) {
    return ConversationLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isCallActive: isCallActive ?? this.isCallActive,
      isAudioCall: isAudioCall ?? this.isAudioCall,
    );
  }
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