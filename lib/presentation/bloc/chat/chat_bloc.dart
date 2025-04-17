import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:hushmate/domain/repositories/chat_repository.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversation extends ChatEvent {
  final String conversationId;

  const LoadConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends ChatEvent {
  final String content;

  const SendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final Conversation conversation;

  const ChatLoaded(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class MessageSending extends ChatState {
  final Conversation conversation;

  const MessageSending(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class MessageSent extends ChatState {
  final Conversation conversation;
  final Message message;

  const MessageSent(this.conversation, this.message);

  @override
  List<Object?> get props => [conversation, message];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  String? _currentConversationId;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _currentConversationId = event.conversationId;
      final conversation = await _chatRepository.getConversation(event.conversationId);
      emit(ChatLoaded(conversation));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentConversationId == null) {
      emit(const ChatError('No active conversation'));
      return;
    }

    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(MessageSending(currentState.conversation));

      try {
        final message = await _chatRepository.sendMessage(
          _currentConversationId!,
          event.content,
        );
        final updatedConversation = await _chatRepository.getConversation(_currentConversationId!);
        emit(MessageSent(updatedConversation, message));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    }
  }
} 