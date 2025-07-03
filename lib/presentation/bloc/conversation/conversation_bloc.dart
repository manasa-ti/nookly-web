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
    on<BulkMessageDelivered>(_onBulkMessageDelivered);
    on<BulkMessageRead>(_onBulkMessageRead);
    on<MessageExpired>(_onMessageExpired);
    on<MessageViewed>(_onMessageViewed);
    on<UpdateMessageId>(_onUpdateMessageId);
    on<UpdateMessageImageData>(_onUpdateMessageImageData);
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

      // Debug: Log message types
      AppLogger.info('🔵 Loaded ${messages.length} messages from API');
      for (final message in messages) {
        AppLogger.info('🔵 - Message ID: ${message.id}, Type: ${message.type}, Content: ${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...');
        
        // Add specific logging for disappearing image messages
        if (message.type == MessageType.image && message.isDisappearing) {
          AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: Found disappearing image in API response');
          AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Message ID: ${message.id}');
          AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Disappearing time: ${message.disappearingTime} seconds');
          AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Has viewedAt metadata: ${message.metadata?.containsKey('viewedAt')}');
          AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - ViewedAt value: ${message.metadata?['viewedAt']}');
        }
      }

      // Filter out expired disappearing images
      final filteredMessages = messages.where((message) {
        if (message.isDisappearing && message.type == MessageType.image) {
          final isViewed = message.metadata?.containsKey('viewedAt') == true;
          final disappearingTime = message.disappearingTime ?? 5;
          
          if (isViewed) {
            // Check if the image has expired since being viewed
            final viewedAt = DateTime.parse(message.metadata!['viewedAt']!);
            final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
            
            if (elapsedSeconds >= disappearingTime) {
              AppLogger.info('Conversation bloc: Filtering out expired disappearing image: ${message.id}');
              return false; // Filter out expired disappearing images
            }
          }
          // Keep unviewed disappearing images and valid viewed ones
        }
        return true; // Keep all other messages
      }).toList();

      // Create conversation with initial messages
      final conversation = Conversation(
        id: event.participantId,
        participantId: event.participantId,
        participantName: event.participantName,
        participantAvatar: event.participantAvatar,
        messages: filteredMessages,
        lastMessage: filteredMessages.isNotEmpty ? filteredMessages.first : null, // First message is newest
        lastMessageTime: filteredMessages.isNotEmpty ? filteredMessages.first.timestamp : DateTime.now(),
        isOnline: event.isOnline,
        unreadCount: 0,
        userId: _currentUserId,
        updatedAt: DateTime.now(),
      );

      emit(ConversationLoaded(
        conversation: conversation,
        messages: filteredMessages,
        hasMoreMessages: _hasMoreMessages,
        participantName: event.participantName,
        participantAvatar: event.participantAvatar,
        isOnline: event.isOnline,
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
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
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

  void _onStartAudioCall(
    StartAudioCall event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      emit(currentState.copyWith(
        isCallActive: true,
        isAudioCall: true,
      ));
      AppLogger.info('🔵 Audio call started for conversation: ${event.conversationId}');
    }
  }

  void _onStartVideoCall(
    StartVideoCall event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      emit(currentState.copyWith(
        isCallActive: true,
        isAudioCall: false,
      ));
      AppLogger.info('🔵 Video call started for conversation: ${event.conversationId}');
    }
  }

  void _onEndCall(
    EndCall event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      emit(currentState.copyWith(
        isCallActive: false,
        isAudioCall: false,
      ));
      AppLogger.info('🔵 Call ended for conversation: ${event.conversationId}');
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      final updatedMessages = [event.message, ...currentState.messages];
      
      // Debug: Log disappearing image messages
      if (event.message.type == MessageType.image && event.message.isDisappearing) {
        AppLogger.info('🔵 DEBUGGING Disappearing Image: Adding disappearing image message to state');
        AppLogger.info('🔵 DEBUGGING Disappearing Image: Message ID: ${event.message.id}');
        AppLogger.info('🔵 DEBUGGING Disappearing Image: Disappearing time: ${event.message.disappearingTime} seconds');
      }
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: event.message,
          lastMessageTime: event.message.timestamp,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    }
  }

  void _onMessageDelivered(MessageDelivered event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Updating message status to delivered in bloc: ${event.messageId}');
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Current messages before update: ${currentState.messages.map((m) => '${m.id}: ${m.status}').join(', ')}');
      
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Found message to update: ${msg.id}');
          final deliveredAt = event.deliveredAt ?? DateTime.now();
          AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Setting deliveredAt to: $deliveredAt');
          return msg.copyWith(
            status: 'delivered',
            deliveredAt: deliveredAt,
          );
        }
        return msg;
      }).toList();
      
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Messages after update: ${updatedMessages.map((m) => '${m.id}: ${m.status} (deliveredAt: ${m.deliveredAt})').join(', ')}');
      
      // Update both the messages list and the lastMessage in the conversation
      final updatedLastMessage = currentState.conversation.lastMessage?.id == event.messageId
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'delivered',
              deliveredAt: event.deliveredAt ?? DateTime.now(),
            )
          : currentState.conversation.lastMessage;
      
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Updated last message: ${updatedLastMessage?.id}: ${updatedLastMessage?.status} (deliveredAt: ${updatedLastMessage?.deliveredAt})');
      
      // Create a new state to force UI rebuild
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        isCallActive: currentState.isCallActive,
        isAudioCall: currentState.isAudioCall,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
      
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Emitted new state with updated message status');
    }
  }

  void _onBulkMessageDelivered(BulkMessageDelivered event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Updating bulk message status to delivered in bloc: ${event.messageIds.join(', ')}');
      
      final deliveredAt = DateTime.now();
      final updatedMessages = currentState.messages.map((msg) {
        if (event.messageIds.contains(msg.id)) {
          AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Found message to update: ${msg.id}');
          return msg.copyWith(
            status: 'delivered',
            deliveredAt: deliveredAt,
          );
        }
        return msg;
      }).toList();
      
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Messages after bulk update: ${updatedMessages.map((m) => '${m.id}: ${m.status} (deliveredAt: ${m.deliveredAt})').join(', ')}');
      
      // Update lastMessage if it's in the bulk update
      final updatedLastMessage = event.messageIds.contains(currentState.conversation.lastMessage?.id)
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'delivered',
              deliveredAt: deliveredAt,
            )
          : currentState.conversation.lastMessage;
      
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Updated last message in bulk update: ${updatedLastMessage?.id}: ${updatedLastMessage?.status} (deliveredAt: ${updatedLastMessage?.deliveredAt})');
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        isCallActive: currentState.isCallActive,
        isAudioCall: currentState.isAudioCall,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
      
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Emitted new state with bulk updated message status');
    }
  }

  void _onMessageRead(MessageRead event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 Updating message status to read in bloc: ${event.messageId}');
      AppLogger.info('🔵 Current messages before update: ${currentState.messages.map((m) => '${m.id}: ${m.status}').join(', ')}');
      
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          AppLogger.info('🔵 Found message to update: ${msg.id}');
          final readAt = event.readAt ?? DateTime.now();
          AppLogger.info('🔵 Setting readAt to: $readAt');
          return msg.copyWith(
            status: 'read',
            readAt: readAt,
          );
        }
        return msg;
      }).toList();
      
      AppLogger.info('🔵 Messages after update: ${updatedMessages.map((m) => '${m.id}: ${m.status} (readAt: ${m.readAt})').join(', ')}');
      
      // Update both the messages list and the lastMessage in the conversation
      final updatedLastMessage = currentState.conversation.lastMessage?.id == event.messageId
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'read',
              readAt: event.readAt ?? DateTime.now(),
            )
          : currentState.conversation.lastMessage;
      
      AppLogger.info('🔵 Updated last message: ${updatedLastMessage?.id}: ${updatedLastMessage?.status} (readAt: ${updatedLastMessage?.readAt})');
      
      // Create a new state to force UI rebuild
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        isCallActive: currentState.isCallActive,
        isAudioCall: currentState.isAudioCall,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    }
  }

  void _onBulkMessageRead(BulkMessageRead event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 Updating bulk message status to read in bloc: ${event.messageIds.join(', ')}');
      
      final readAt = DateTime.now();
      final updatedMessages = currentState.messages.map((msg) {
        if (event.messageIds.contains(msg.id)) {
          AppLogger.info('🔵 Found message to update: ${msg.id}');
          return msg.copyWith(
            status: 'read',
            readAt: readAt,
          );
        }
        return msg;
      }).toList();
      
      // Update lastMessage if it's in the bulk update
      final updatedLastMessage = event.messageIds.contains(currentState.conversation.lastMessage?.id)
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'read',
              readAt: readAt,
            )
          : currentState.conversation.lastMessage;
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        isCallActive: currentState.isCallActive,
        isAudioCall: currentState.isAudioCall,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
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
      
      // Debug: Log disappearing image messages
      if (event.message.type == MessageType.image && event.message.isDisappearing) {
        AppLogger.info('🔵 DEBUGGING Disappearing Image: Adding sent disappearing image message to state');
        AppLogger.info('🔵 DEBUGGING Disappearing Image: Message ID: ${event.message.id}');
        AppLogger.info('🔵 DEBUGGING Disappearing Image: Disappearing time: ${event.message.disappearingTime} seconds');
      }
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: event.message,
          lastMessageTime: event.message.timestamp,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    }
  }

  void _onConversationUpdated(
    ConversationUpdated event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Processing conversation update event');
      
      // If we have a lastMessage, update its status in the messages list
      if (event.lastMessage != null) {
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Updating message status from conversation update');
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Last message: id=${event.lastMessage!.id}, status=${event.lastMessage!.status}');
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Last message timestamps: deliveredAt=${event.lastMessage!.deliveredAt}, readAt=${event.lastMessage!.readAt}');
        
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == event.lastMessage!.id) {
            AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Found message to update: ${msg.id}');
            return msg.copyWith(
              status: event.lastMessage!.status,
              deliveredAt: event.lastMessage!.deliveredAt,
              readAt: event.lastMessage!.readAt,
            );
          }
          return msg;
        }).toList();
        
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Messages after update: ${updatedMessages.map((m) => '${m.id}: ${m.status} (deliveredAt: ${m.deliveredAt}, readAt: ${m.readAt})').join(', ')}');
        
        emit(ConversationLoaded(
          conversation: currentState.conversation.copyWith(
            lastMessage: event.lastMessage,
            updatedAt: event.updatedAt,
            isTyping: event.isTyping,
          ),
          messages: updatedMessages,
          hasMoreMessages: currentState.hasMoreMessages,
          isCallActive: currentState.isCallActive,
          isAudioCall: currentState.isAudioCall,
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
        ));
        
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Emitted new state from conversation update');
      } else {
        // If no lastMessage, just update the conversation
        emit(ConversationLoaded(
          conversation: currentState.conversation.copyWith(
            updatedAt: event.updatedAt,
            isTyping: event.isTyping,
          ),
          messages: currentState.messages,
          hasMoreMessages: currentState.hasMoreMessages,
          isCallActive: currentState.isCallActive,
          isAudioCall: currentState.isAudioCall,
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
        ));
        
        AppLogger.info('🔵 DEBUGGING MESSAGE DELIVERY: Emitted new state without message update');
      }
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

  void _onMessageExpired(MessageExpired event, Emitter<ConversationState> emit) {
    AppLogger.info('🔵 Handling MessageExpired event for message: ${event.messageId}');
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 Current state has ${currentState.messages.length} messages');
      
      // Debug: Log all message IDs to see what we're working with
      AppLogger.info('🔵 All message IDs in current state:');
      for (final message in currentState.messages) {
        AppLogger.info('  - Message ID: ${message.id}');
      }
      
      // Check if the message exists
      final messageExists = currentState.messages.any((message) => message.id == event.messageId);
      AppLogger.info('🔵 Message with ID ${event.messageId} exists: $messageExists');
      
      // Remove the expired message from the list
      final updatedMessages = currentState.messages.where((message) => message.id != event.messageId).toList();
      
      AppLogger.info('🔵 Removed expired message, new message count: ${updatedMessages.length}');
      AppLogger.info('🔵 Messages after removal:');
      for (final message in updatedMessages) {
        AppLogger.info('  - Message ID: ${message.id}');
      }
      
      emit(ConversationLoaded(
        conversation: currentState.conversation,
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    } else {
      AppLogger.warning('⚠️ Cannot handle MessageExpired: state is not ConversationLoaded');
    }
  }

  void _onMessageViewed(MessageViewed event, Emitter<ConversationState> emit) {
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: Processing MessageViewed event');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Message ID: ${event.messageId}');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Viewed at: ${event.viewedAt}');
    
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Current state has ${currentState.messages.length} messages');
      
      // Log all messages before update
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Messages before update:');
      for (final msg in currentState.messages) {
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - ID: ${msg.id}, Type: ${msg.type}, IsDisappearing: ${msg.isDisappearing}');
      }
      
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.messageId) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Found message to update: ${message.id}');
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Current metadata: ${message.metadata}');
          
          // If this is a disappearing image message, start the timer
          if (message.type == MessageType.image && message.isDisappearing) {
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: Adding viewedAt metadata to disappearing image message');
            // Create a new message with the viewed timestamp and start the timer
            final updatedMessage = message.copyWith(
              metadata: {
                ...?message.metadata,
                'viewedAt': event.viewedAt.toIso8601String(),
              },
            );
            AppLogger.info('🔵 DEBUGGING MESSAGE ID: Updated metadata: ${updatedMessage.metadata}');
            return updatedMessage;
          }
          return message;
        }
        return message;
      }).toList();
      
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Messages after update:');
      for (final msg in updatedMessages) {
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - ID: ${msg.id}, Type: ${msg.type}, Metadata: ${msg.metadata}');
      }

      emit(ConversationLoaded(
        conversation: currentState.conversation,
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
      
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: MessageViewed event processed successfully');
    } else {
      AppLogger.error('🔵 DEBUGGING MESSAGE ID: Cannot process MessageViewed: state is not ConversationLoaded');
    }
  }

  void _onUpdateMessageId(UpdateMessageId event, Emitter<ConversationState> emit) {
    AppLogger.info('🔵 DEBUGGING Disappearing Image: Updating message ID from ${event.oldMessageId} to ${event.newMessageId}');
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      AppLogger.info('🔵 DEBUGGING Disappearing Image: Current state has ${currentState.messages.length} messages');
      
      // Find and update the message with the new ID
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.oldMessageId) {
          AppLogger.info('🔵 DEBUGGING Disappearing Image: Found message to update ID: ${message.id}');
          return message.copyWith(id: event.newMessageId);
        }
        return message;
      }).toList();
      
      AppLogger.info('🔵 DEBUGGING Disappearing Image: Updated message ID, new message count: ${updatedMessages.length}');
      
      emit(ConversationLoaded(
        conversation: currentState.conversation,
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    } else {
      AppLogger.warning('⚠️ DEBUGGING Disappearing Image: Cannot update message ID: state is not ConversationLoaded');
    }
  }

  void _onUpdateMessageImageData(UpdateMessageImageData event, Emitter<ConversationState> emit) {
    AppLogger.info('🔵 Updating message image data for message: ${event.messageId}');
    AppLogger.info('🔵 New image URL: ${event.newImageUrl}');
    AppLogger.info('🔵 New expiration time: ${event.newExpirationTime}');
    AppLogger.info('🔵 Additional data: ${event.additionalData}');
    
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      
      // Find and update the message with new image data
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.messageId) {
          AppLogger.info('🔵 Found message to update image data: ${message.id}');
          
          // Create updated metadata with any additional fields from refresh response
          final updatedMetadata = Map<String, String>.from(message.metadata ?? {});
          event.additionalData.forEach((key, value) {
            if (value != null) {
              updatedMetadata[key] = value.toString();
            }
          });
          
          return message.copyWith(
            content: event.newImageUrl, // Update the image URL
            urlExpirationTime: event.newExpirationTime, // Update expiration time
            metadata: updatedMetadata, // Update metadata with any additional fields
          );
        }
        return message;
      }).toList();
      
      AppLogger.info('🔵 Updated message image data successfully');
      
      emit(ConversationLoaded(
        conversation: currentState.conversation,
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    } else {
      AppLogger.warning('⚠️ Cannot update message image data: state is not ConversationLoaded');
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

class MessageExpired extends ConversationEvent {
  final String messageId;

  const MessageExpired(this.messageId);

  @override
  List<Object> get props => [messageId];
} 