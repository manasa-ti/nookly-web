import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/repositories/conversation_repository.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_event.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRepository repository;
  StreamSubscription? _messagesSubscription;
  String? _currentConversationId;

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
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      emit(ConversationLoading());
      
      // Cancel previous subscription if any
      await _messagesSubscription?.cancel();
      
      // Get conversation
      final conversation = await repository.getConversation(event.conversationId);
      _currentConversationId = event.conversationId;
      
      // Listen to messages
      _messagesSubscription = repository.listenToMessages(event.conversationId).listen(
        (messages) {
          if (state is ConversationLoaded) {
            final currentState = state as ConversationLoaded;
            emit(currentState.copyWith(messages: messages));
          } else {
            emit(ConversationLoaded(
              conversation: conversation,
              messages: messages,
            ));
          }
        },
      );
      
      // Initial state
      emit(ConversationLoaded(
        conversation: conversation,
        messages: conversation.messages,
      ));
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        
        // Send message
        await repository.sendTextMessage(event.conversationId, event.content);
        
        // State will be updated via stream
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendVoiceMessage(
    SendVoiceMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        
        // Send message
        await repository.sendVoiceMessage(
          event.conversationId,
          event.audioPath,
          event.duration,
        );
        
        // State will be updated via stream
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendFileMessage(
    SendFileMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        
        // Send message
        await repository.sendFileMessage(
          event.conversationId,
          event.filePath,
          event.fileName,
          event.fileSize,
        );
        
        // State will be updated via stream
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        
        // Send message
        await repository.sendImageMessage(
          event.conversationId,
          event.imagePath,
        );
        
        // State will be updated via stream
      }
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
      // State will be updated via stream
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await repository.blockUser(event.userId);
      
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        // Reload conversation after blocking
        final updatedConversation = await repository.getConversation(_currentConversationId!);
        emit(currentState.copyWith(conversation: updatedConversation));
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
      
      if (state is ConversationLoaded) {
        final currentState = state as ConversationLoaded;
        // Reload conversation after unblocking
        final updatedConversation = await repository.getConversation(_currentConversationId!);
        emit(currentState.copyWith(conversation: updatedConversation));
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
      // State will be updated via stream
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
      // State will be updated via stream
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
      emit(ConversationLeft());
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
        emit(AudioCallStarted());
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
        emit(VideoCallStarted());
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
        emit(CallEnded());
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