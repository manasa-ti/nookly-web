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
  final bool isLoadingMore;
  final bool isCallActive;
  final bool isAudioCall;
  final String? error;
  final String participantName;
  final String? participantAvatar;
  final bool isOnline;

  const ConversationLoaded({
    required this.conversation,
    required this.messages,
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
    this.isCallActive = false,
    this.isAudioCall = false,
    this.error,
    required this.participantName,
    this.participantAvatar,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [
        conversation,
        messages,
        hasMoreMessages,
        isLoadingMore,
        isCallActive,
        isAudioCall,
        error,
        participantName,
        participantAvatar,
        isOnline,
      ];

  ConversationLoaded copyWith({
    Conversation? conversation,
    List<Message>? messages,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    bool? isCallActive,
    bool? isAudioCall,
    String? error,
    String? participantName,
    String? participantAvatar,
    bool? isOnline,
  }) {
    return ConversationLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCallActive: isCallActive ?? this.isCallActive,
      isAudioCall: isAudioCall ?? this.isAudioCall,
      error: error,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      isOnline: isOnline ?? this.isOnline,
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