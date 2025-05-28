import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/conversation.dart'; // Required for ConversationLoaded state
import 'package:hushmate/domain/entities/message.dart'; // Import Message entity
import 'package:hushmate/domain/repositories/conversation_repository.dart';
import 'package:hushmate/core/network/socket_service.dart';
import 'package:hushmate/core/utils/logger.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRepository _conversationRepository;
  final SocketService _socketService;
  String _currentUserId;
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMoreMessages = true;
  StreamSubscription? _messagesSubscription;
  // Store current participantId to manage message subscription
  String? _currentOpenParticipantId;

  ConversationBloc({
    required ConversationRepository conversationRepository,
    required SocketService socketService,
    required String currentUserId,
  }) : _conversationRepository = conversationRepository,
       _socketService = socketService,
       _currentUserId = currentUserId,
       super(ConversationInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<LoadMoreMessages>(_onLoadMoreMessages);
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
    on<MessageReceived>(_onMessageReceived);
    on<MessageDelivered>(_onMessageDelivered);
    on<MessageRead>(_onMessageRead);
    on<Typing>(_onTyping);
    on<StopTyping>(_onStopTyping);
    on<MessageEdited>(_onMessageEdited);
    on<MessageDeleted>(_onMessageDeleted);
    on<MessageSent>(_onMessageSent);
    on<ConversationUpdated>(_onConversationUpdated);
    on<UpdateCurrentUserId>(_onUpdateCurrentUserId);
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationLoading());
    try {
      _currentPage = 0;
      _hasMoreMessages = true;
      
      final response = await _conversationRepository.getMessages(
        participantId: event.participantId,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // API sends messages in descending order (newest first)
      // Keep this order since we want newest at bottom in UI
      final messages = response['messages'] as List<Message>;
      _hasMoreMessages = response['pagination']['hasMore'] as bool;

      // Create conversation with initial messages
      final conversation = Conversation(
        id: event.participantId,
        participantId: event.participantId,
        participantName: event.participantName,
        participantAvatar: event.participantAvatar,
        messages: messages,
        lastMessage: messages.isNotEmpty ? messages.first : null, // First message is newest
        lastMessageTime: messages.isNotEmpty ? messages.first.timestamp : DateTime.now(),
        isOnline: event.isOnline,
        unreadCount: 0,
        userId: _currentUserId,
        updatedAt: DateTime.now(),
      );

      emit(ConversationLoaded(
        conversation: conversation,
        messages: messages,
        hasMoreMessages: _hasMoreMessages,
      ));

    } catch (e) {
      emit(ConversationError('Failed to load conversation: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ConversationState> emit,
  ) async {
    if (!_hasMoreMessages) return;

    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      try {
        _currentPage++;
        
        final response = await _conversationRepository.getMessages(
          participantId: currentState.conversation.participantId,
          page: _currentPage,
          pageSize: _pageSize,
        );

        // API sends messages in descending order (newest first)
        // Keep this order since we want newest at bottom in UI
        final newMessages = response['messages'] as List<Message>;
        _hasMoreMessages = response['pagination']['hasMore'] as bool;

        // Combine existing messages with new messages
        // Since both are in descending order, we can just append
        final updatedMessages = [...currentState.messages, ...newMessages];

        emit(ConversationLoaded(
          conversation: currentState.conversation,
          messages: updatedMessages,
          hasMoreMessages: _hasMoreMessages,
        ));

      } catch (e) {
        emit(ConversationError('Failed to load more messages: ${e.toString()}'));
      }
    }
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      // No need to check (state is ConversationLoaded) if send can happen regardless
      // The repository call handles the sending. UI might disable send if not loaded.
      await _conversationRepository.sendTextMessage(event.conversationId, event.content);
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
      await _conversationRepository.sendVoiceMessage(
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
      await _conversationRepository.sendFileMessage(
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
      await _conversationRepository.sendImageMessage(
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
      await _conversationRepository.markMessageAsRead(event.messageId);
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
      await _conversationRepository.blockUser(event.userId);
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
      await _conversationRepository.unblockUser(event.userId);
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
      await _conversationRepository.muteConversation(event.conversationId);
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
      await _conversationRepository.unmuteConversation(event.conversationId);
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
      await _conversationRepository.leaveConversation(event.conversationId);
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
      await _conversationRepository.startAudioCall(event.conversationId);
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
      await _conversationRepository.startVideoCall(event.conversationId);
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
      await _conversationRepository.endCall(event.conversationId);
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

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedMessages = [event.message, ...currentState.messages];
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: event.message,
          lastMessageTime: event.message.timestamp,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
      ));
    }
  }

  void _onMessageDelivered(MessageDelivered event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(status: 'delivered', deliveredAt: event.deliveredAt);
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onMessageRead(MessageRead event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(status: 'read', readAt: event.readAt);
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onTyping(Typing event, Emitter<ConversationState> emit) {
    // Optionally, set a flag in state to show typing indicator
    // Not persisted in ConversationLoaded, so you may want to extend state for this
  }

  void _onStopTyping(StopTyping event, Emitter<ConversationState> emit) {
    // Optionally, unset typing indicator flag
  }

  void _onMessageEdited(MessageEdited event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(content: event.newContent, metadata: {...?msg.metadata, 'editedAt': event.editedAt.toIso8601String()});
        }
        return msg;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onMessageDeleted(MessageDeleted event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedMessages = currentState.messages.where((msg) => msg.id != event.messageId).toList();
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onMessageSent(
    MessageSent event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedMessages = [event.message, ...currentState.messages];
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: event.message,
          lastMessageTime: event.message.timestamp,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
      ));
    }
  }

  void _onConversationUpdated(
    ConversationUpdated event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedConversation = currentState.conversation.copyWith(
        lastMessage: event.lastMessage,
        updatedAt: event.updatedAt,
      );
      emit(ConversationLoaded(
        conversation: updatedConversation,
        messages: currentState.messages,
        hasMoreMessages: currentState.hasMoreMessages,
      ));
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

  void _onUpdateCurrentUserId(UpdateCurrentUserId event, Emitter<ConversationState> emit) {
    _currentUserId = event.userId;
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