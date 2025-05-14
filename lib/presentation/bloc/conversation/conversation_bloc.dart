import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/conversation.dart'; // Required for ConversationLoaded state
import 'package:hushmate/domain/entities/message.dart'; // Import Message entity
import 'package:hushmate/domain/repositories/conversation_repository.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_event.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRepository repository;
  StreamSubscription? _messagesSubscription;
  // Store current participantId to manage message subscription
  String? _currentOpenParticipantId;

  ConversationBloc({required this.repository}) : super(ConversationInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendVoiceMessage>(_onSendVoiceMessage);
    on<SendFileMessage>(_onSendFileMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<MuteConversation>(_onMuteConversation);
    on<UnmuteConversation>(_onUnmuteConversation);
    on<LeaveConversation>(_onLeaveConversation);
    on<StartAudioCall>(_onStartAudioCall);
    on<StartVideoCall>(_onStartVideoCall);
    on<EndCall>(_onEndCall);
    // Add a new event handler for when messages are updated by the stream
    on<_MessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      // Cancel previous message subscription if any, and if for a different participant
      if (_currentOpenParticipantId != null && _currentOpenParticipantId != event.participantId) {
        await _messagesSubscription?.cancel();
        _messagesSubscription = null;
      }
      _currentOpenParticipantId = event.participantId;

      // Fetch initial conversation details (which includes messages)
      final conversation = await repository.getConversation(
        event.participantId,
        event.participantName,
        event.participantAvatar,
        event.isOnline,
      );
      
      // Emit loaded state with the fetched conversation (which contains initial messages)
      emit(ConversationLoaded(
        conversation: conversation,
        messages: conversation.messages, // Messages are now part of the Conversation object from repo
      ));

      // Listen to new messages for this participantId
      // The repository.listenToMessages might need adjustment if it also needs full participant details
      // or if it should purely work on participantId.
      // For now, assuming listenToMessages primarily works with participantId.
      _messagesSubscription = repository.listenToMessages(event.participantId).listen(
        (updatedMessages) {
          // Add an event to handle message updates to ensure state is managed by BLoC events
          add(_MessagesUpdated(updatedMessages)); 
        },
        onError: (error) {
          // Handle stream errors, perhaps emit an error state or log
          print('Message stream error: $error');
          emit(ConversationError('Error listening to messages: ${error.toString()}'));
        }
      );
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  // Event handler for messages pushed by the stream
  void _onMessagesUpdated(_MessagesUpdated event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      // Create a new Conversation object with the updated messages
      // and potentially other fields from the current loaded conversation state.
      final updatedConversation = currentState.conversation.copyWith(messages: event.messages);
      emit(currentState.copyWith(conversation: updatedConversation, messages: event.messages));
    }
    // If not ConversationLoaded, the stream might have pushed messages for a conversation not fully loaded yet.
    // Or, the state changed due to other events. Decide how to handle or if to ignore.
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      // No need to check (state is ConversationLoaded) if send can happen regardless
      // The repository call handles the sending. UI might disable send if not loaded.
      await repository.sendTextMessage(event.conversationId, event.content);
      // Messages will update via the stream from listenToMessages
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  // ... other event handlers (sendVoice, sendFile, etc.) remain largely the same,
  // they call repository methods and rely on the message stream for UI updates.
  // Ensure they use event.conversationId (which is the participantId) correctly.

  Future<void> _onSendVoiceMessage(
    SendVoiceMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.sendVoiceMessage(
        event.conversationId, 
        event.audioPath,
        event.duration,
      );
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendFileMessage(
    SendFileMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.sendFileMessage(
        event.conversationId,
        event.filePath,
        event.fileName,
        event.fileSize,
      );
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.sendImageMessage(
        event.conversationId,
        event.imagePath,
      );
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.markMessageAsRead(event.messageId);
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  // For BlockUser, UnblockUser, Mute, Unmute, Leave: 
  // These might require re-fetching the conversation list (InboxBloc) 
  // or specific conversation details (ConversationBloc) if the status change isn't reflected via streams.
  // For now, they modify backend state. The ConversationLoaded state in this BLoC might become stale
  // regarding isBlocked, isMuted flags until a fresh LoadConversation.

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.blockUser(event.userId);
      if (state is ConversationLoaded && _currentOpenParticipantId != null) {
        final currentState = state as ConversationLoaded;
        // Optimistically update or re-fetch. For now, just calling repo.
        // Consider re-calling getConversation or updating the state directly.
        // For simplicity, if these actions affect the current view significantly, 
        // a re-fetch via LoadConversation might be dispatched by UI or here.
        // Or, the Conversation object itself can be updated.
        emit(currentState.copyWith(conversation: currentState.conversation.copyWith(isBlocked: true)));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.unblockUser(event.userId);
      if (state is ConversationLoaded && _currentOpenParticipantId != null) {
        final currentState = state as ConversationLoaded;
        emit(currentState.copyWith(conversation: currentState.conversation.copyWith(isBlocked: false)));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onMuteConversation(
    MuteConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.muteConversation(event.conversationId);
       if (state is ConversationLoaded && _currentOpenParticipantId == event.conversationId) {
        final currentState = state as ConversationLoaded;
        emit(currentState.copyWith(conversation: currentState.conversation.copyWith(isMuted: true)));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onUnmuteConversation(
    UnmuteConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.unmuteConversation(event.conversationId);
      if (state is ConversationLoaded && _currentOpenParticipantId == event.conversationId) {
        final currentState = state as ConversationLoaded;
        emit(currentState.copyWith(conversation: currentState.conversation.copyWith(isMuted: false)));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onLeaveConversation(
    LeaveConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.leaveConversation(event.conversationId);
      emit(ConversationLeft()); // UI should handle this, e.g. pop screen
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onStartAudioCall(
    StartAudioCall event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.startAudioCall(event.conversationId);
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        emit(currentState.copyWith(isCallActive: true, isAudioCall: true));
      } else {
        // This state transition might need re-evaluation if not already loaded.
        // emit(AudioCallStarted()); // This state needs to be part of ConversationState
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onStartVideoCall(
    StartVideoCall event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.startVideoCall(event.conversationId);
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        emit(currentState.copyWith(isCallActive: true, isAudioCall: false));
      } else {
        // emit(VideoCallStarted()); // This state needs to be part of ConversationState
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onEndCall(
    EndCall event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.endCall(event.conversationId);
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        emit(currentState.copyWith(isCallActive: false, isAudioCall: false));
      } else {
        // emit(CallEnded()); // This state needs to be part of ConversationState
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}

// Private event for BLoC to handle message stream updates
class _MessagesUpdated extends ConversationEvent {
  final List<Message> messages;
  const _MessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
} 