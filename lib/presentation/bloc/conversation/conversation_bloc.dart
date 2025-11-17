import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/conversation.dart'; // Required for ConversationLoaded state
import 'package:nookly/domain/entities/message.dart'; // Import Message entity
import 'package:nookly/domain/repositories/conversation_repository.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/di/injection_container.dart' as di;

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationRepository _conversationRepository;
  final SocketService _socketService;
  final AnalyticsService _analyticsService;
  String _currentUserId;
  String? _currentCursor; // Cursor for cursor-based pagination
  static const int _pageSize = 20;
  bool _hasMoreMessages = true;
  StreamSubscription? _messagesSubscription;
  // Store current participantId to manage message subscription
  String? _currentOpenParticipantId;

  ConversationBloc({
    required ConversationRepository conversationRepository,
    required SocketService socketService,
    required String currentUserId,
    AnalyticsService? analyticsService,
  }) : _conversationRepository = conversationRepository,
       _socketService = socketService,
       _analyticsService = analyticsService ?? di.sl<AnalyticsService>(),
       _currentUserId = currentUserId,
       super(ConversationInitial()) {
    on<LoadConversation>(_onLoadConversation);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendVoiceMessage>(_onSendVoiceMessage);
    on<SendFileMessage>(_onSendFileMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<SendGifMessage>(_onSendGifMessage);
    on<SendStickerMessage>(_onSendStickerMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<MuteConversation>(_onMuteConversation);
    on<UnmuteConversation>(_onUnmuteConversation);
    on<LeaveConversation>(_onLeaveConversation);
    // Call event handlers
    on<StartAudioCall>(_onStartAudioCall);
    on<StartVideoCall>(_onStartVideoCall);
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
      // Reset pagination state for new conversation
      _hasMoreMessages = true;
      
      // First page - use empty cursor string to trigger cursor-based pagination
      // API requires cursor= (empty value) for first request to return cursor in response
      const initialCursor = ''; // Empty string triggers cursor-based pagination
      _currentCursor = initialCursor;
      
      AppLogger.info('🔵 First page - using empty cursor to trigger cursor-based pagination');
      
      final response = await _conversationRepository.getMessages(
        participantId: event.participantId,
        cursor: initialCursor,
        page: null,
        pageSize: _pageSize,
      );

      // API sends messages in descending order (newest first)
      // Keep this order since we want newest at bottom in UI
      final messages = response['messages'] as List<Message>;
      final pagination = response['pagination'] as Map<String, dynamic>;
      _hasMoreMessages = pagination['hasMore'] as bool? ?? false;
      
      // Debug: Log full pagination structure
      AppLogger.info('🔵 PAGINATION DEBUG: Full pagination object: $pagination');
      AppLogger.info('🔵 PAGINATION DEBUG: Pagination keys: ${pagination.keys.toList()}');
      AppLogger.info('🔵 PAGINATION DEBUG: Has cursor key: ${pagination.containsKey('cursor')}');
      if (pagination.containsKey('cursor')) {
        AppLogger.info('🔵 PAGINATION DEBUG: Cursor value: ${pagination['cursor']} (type: ${pagination['cursor'].runtimeType})');
      }
      
      // Extract cursor from pagination response for subsequent requests
      if (pagination.containsKey('cursor') && pagination['cursor'] != null) {
        _currentCursor = pagination['cursor'] as String;
        AppLogger.info('🔵 Initial cursor from first page: $_currentCursor');
      } else {
        // If no cursor in response, derive it from the last (oldest) message timestamp
        // Messages are in descending order, so last message is oldest
        if (messages.isNotEmpty) {
          final lastMessage = messages.last;
          _currentCursor = lastMessage.timestamp.toIso8601String();
          AppLogger.info('🔵 Derived cursor from last message timestamp: $_currentCursor');
        } else {
          AppLogger.warning('⚠️ No cursor in pagination and no messages to derive cursor from');
        }
      }

      // Debug: Log message types
      AppLogger.info('🔵 Loaded ${messages.length} messages from API');
      for (final message in messages) {
        AppLogger.info('🔵 - Message ID: ${message.id}, Type: ${message.type}, Content: ${message.content.substring(0, message.content.length > 50 ? 50 : message.content.length)}...');
      }

      // Filter out expired disappearing images
      final filteredMessages = messages.where((message) {
        if (message.metadata?.isDisappearing == true && message.type == MessageType.image) {
          final isViewed = message.metadata?.image?.expiresAt != null;
          final disappearingTime = message.metadata?.disappearingTime ?? 5;
          
          AppLogger.info('🔍 FILTERING DEBUG: Message ${message.id}');
          AppLogger.info('🔍 FILTERING DEBUG: - isDisappearing: ${message.metadata?.isDisappearing}');
          AppLogger.info('🔍 FILTERING DEBUG: - type: ${message.type}');
          AppLogger.info('🔍 FILTERING DEBUG: - isViewed: $isViewed');
          AppLogger.info('🔍 FILTERING DEBUG: - disappearingTime: $disappearingTime');
          AppLogger.info('🔍 FILTERING DEBUG: - metadata: ${message.metadata}');
          
          if (isViewed) {
            // Check if the image has expired since being viewed
            final viewedAt = DateTime.parse(message.metadata!.image!.expiresAt!);
            final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
            
            AppLogger.info('🔍 FILTERING DEBUG: - viewedAt: $viewedAt');
            AppLogger.info('🔍 FILTERING DEBUG: - elapsedSeconds: $elapsedSeconds');
            AppLogger.info('🔍 FILTERING DEBUG: - shouldExpire: ${elapsedSeconds >= disappearingTime}');
            
            if (elapsedSeconds >= disappearingTime) {
              AppLogger.info('🔍 FILTERING DEBUG: Filtering out expired disappearing image: ${message.id}');
              return false; // Filter out expired disappearing images
            } else {
              AppLogger.info('🔍 FILTERING DEBUG: Keeping valid disappearing image: ${message.id}');
            }
          } else {
            AppLogger.info('🔍 FILTERING DEBUG: Keeping unviewed disappearing image: ${message.id}');
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
        lastSeen: event.lastSeen,
        connectionStatus: event.connectionStatus,
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
        // Only use cursor-based pagination - no page fallback
        // If no cursor available or cursor is empty, we can't load more
        if (_currentCursor == null || _currentCursor!.isEmpty) {
          AppLogger.warning('⚠️ Cannot load more messages: no cursor available (cursor: $_currentCursor)');
          _hasMoreMessages = false; // Mark as no more messages if cursor is invalid
          return;
        }
        
        AppLogger.info('🔵 LoadMoreMessages - Using cursor: $_currentCursor, hasMore: $_hasMoreMessages');
        
        final response = await _conversationRepository.getMessages(
          participantId: currentState.conversation.participantId,
          cursor: _currentCursor,
          page: null, // Always null - use cursor only
          pageSize: _pageSize,
        );

        // API sends messages in descending order (newest first)
        // Keep this order since we want newest at bottom in UI
        final newMessages = response['messages'] as List<Message>;
        final pagination = response['pagination'] as Map<String, dynamic>;
        _hasMoreMessages = pagination['hasMore'] as bool? ?? false;
        
        // Debug: Log full pagination structure
        AppLogger.info('🔵 PAGINATION DEBUG (LoadMore): Full pagination object: $pagination');
        AppLogger.info('🔵 PAGINATION DEBUG (LoadMore): Pagination keys: ${pagination.keys.toList()}');
        
        // Update cursor from pagination response for next request
        if (pagination.containsKey('cursor') && pagination['cursor'] != null && pagination['cursor'].toString().isNotEmpty) {
          _currentCursor = pagination['cursor'] as String;
          AppLogger.info('🔵 Updated cursor for next page: $_currentCursor');
        } else if (newMessages.isNotEmpty) {
          // If no cursor in response, derive it from the last (oldest) message timestamp
          final lastMessage = newMessages.last;
          _currentCursor = lastMessage.timestamp.toIso8601String();
          AppLogger.info('🔵 Derived cursor from last message timestamp: $_currentCursor');
        } else {
          // If no cursor and no messages, we've reached the end
          AppLogger.warning('⚠️ No cursor in pagination response and no messages - reached end');
          _currentCursor = null;
          _hasMoreMessages = false; // Ensure hasMore is false when we can't get cursor
        }
        
        // Log current state for debugging
        AppLogger.info('🔵 LoadMore state - hasMore: $_hasMoreMessages, cursor: $_currentCursor, newMessages: ${newMessages.length}');

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
      // Track analytics
      await _analyticsService.logMessageSent(
        conversationId: event.conversationId,
        messageType: 'text',
      );
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
      // Create a temporary voice message for immediate UI feedback
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Voice message',
        sender: _currentUserId,
        receiver: event.conversationId,
        type: MessageType.voice,
        timestamp: DateTime.now(),
        status: 'sending',
        metadata: MessageMetadata(
          isDisappearing: false,
          isRead: false,
          isViewOnce: false,
          voice: VoiceMetadata(
            voiceKey: 'temp_key',
            voiceUrl: 'temp_url',
            voiceSize: 0,
            voiceType: 'audio/m4a',
            voiceDuration: event.duration.inSeconds,
            expiresAt: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          ),
        ),
      );

      // Add to current state immediately
      final currentState = state;
      if (currentState is ConversationLoaded) {
        final updatedMessages = [tempMessage, ...currentState.messages];
        emit(ConversationLoaded(
          conversation: currentState.conversation,
          messages: updatedMessages,
          hasMoreMessages: currentState.hasMoreMessages,
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
        ));
      }

      // Send the actual voice message
      await _conversationRepository.sendVoiceMessage(
        event.conversationId, 
        event.audioPath,
        event.duration,
      );
      
      // Track analytics
      await _analyticsService.logMessageSent(
        conversationId: event.conversationId,
        messageType: 'voice',
      );

      // The real message will be received via socket and replace the temp message
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
      // Track analytics - conversationId is the recipient user ID
      await _analyticsService.logImageSent(recipientId: event.conversationId);
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendGifMessage(
    SendGifMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      // Create a temporary GIF message for immediate UI feedback
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: event.gifMetadata['giphyUrl'] as String,
        sender: _currentUserId,
        receiver: event.conversationId,
        type: MessageType.gif,
        timestamp: DateTime.now(),
        status: 'sending',
        metadata: MessageMetadata(
          isDisappearing: false,
          isRead: false,
          isViewOnce: false,
          gif: GifMetadata(
            giphyId: event.gifMetadata['giphyId'] as String,
            giphyUrl: event.gifMetadata['giphyUrl'] as String,
            giphyPreviewUrl: event.gifMetadata['giphyPreviewUrl'] as String,
            width: event.gifMetadata['width'] as int,
            height: event.gifMetadata['height'] as int,
            title: event.gifMetadata['title'] as String,
          ),
        ),
      );

      // Add to current state immediately
      final currentState = state;
      if (currentState is ConversationLoaded) {
        final updatedMessages = [tempMessage, ...currentState.messages];
        emit(ConversationLoaded(
          conversation: currentState.conversation,
          messages: updatedMessages,
          hasMoreMessages: currentState.hasMoreMessages,
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
        ));
      }

      // Send the actual GIF message
      await _conversationRepository.sendGifMessage(
        event.conversationId,
        event.gifMetadata,
      );

      // Track analytics - conversationId is the recipient user ID
      await _analyticsService.logGifSent(recipientId: event.conversationId);

      // The real message will be received via socket and replace the temp message
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSendStickerMessage(
    SendStickerMessage event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      // Create a temporary sticker message for immediate UI feedback
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: event.stickerMetadata['stickerUrl'] as String,
        sender: _currentUserId,
        receiver: event.conversationId,
        type: MessageType.sticker,
        timestamp: DateTime.now(),
        status: 'sending',
        metadata: MessageMetadata(
          isDisappearing: false,
          isRead: false,
          isViewOnce: false,
          sticker: StickerMetadata(
            giphyId: event.stickerMetadata['giphyId'] as String,
            stickerUrl: event.stickerMetadata['stickerUrl'] as String,
            width: event.stickerMetadata['width'] as int,
            height: event.stickerMetadata['height'] as int,
            title: event.stickerMetadata['title'] as String,
          ),
        ),
      );

      // Add to current state immediately
      final currentState = state;
      if (currentState is ConversationLoaded) {
        final updatedMessages = [tempMessage, ...currentState.messages];
        emit(ConversationLoaded(
          conversation: currentState.conversation,
          messages: updatedMessages,
          hasMoreMessages: currentState.hasMoreMessages,
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
        ));
      }

      // Send the actual sticker message
      await _conversationRepository.sendStickerMessage(
        event.conversationId,
        event.stickerMetadata,
      );

      // Track analytics - conversationId is the recipient user ID
      await _analyticsService.logStickerSent(recipientId: event.conversationId);

      // The real message will be received via socket and replace the temp message
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

  // Call event handlers
  void _onStartAudioCall(
    StartAudioCall event,
    Emitter<ConversationState> emit,
  ) {
    // Call initiation is handled by CallManagerService
    // This is just for logging/tracking in the bloc if needed
    AppLogger.info('🔵 [CALL] Audio call event triggered for: ${event.conversationId}');
  }

  void _onStartVideoCall(
    StartVideoCall event,
    Emitter<ConversationState> emit,
  ) {
    // Call initiation is handled by CallManagerService
    // This is just for logging/tracking in the bloc if needed
    AppLogger.info('🔵 [CALL] Video call event triggered for: ${event.conversationId}');
  }

  // void _onEndCall(
  //   EndCall event,
  //   Emitter<ConversationState> emit,
  // ) {
  //   if (state is ConversationLoaded) {
  //     final currentState = state as ConversationLoaded;
  //     emit(currentState.copyWith(
  //       isCallActive: false,
  //       isAudioCall: false,
  //     ));
  //     AppLogger.info('🔵 Call ended for conversation: ${event.conversationId}');
  //   }
  // }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ConversationState> emit,
  ) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      
      // Check if message already exists to prevent duplicates
      final messageExists = currentState.messages.any((msg) => msg.id == event.message.id);
      if (messageExists) {
        AppLogger.warning('⚠️ Message already exists in state, skipping duplicate: ${event.message.id}');
        return;
      }
      
      final updatedMessages = [event.message, ...currentState.messages];
      

      
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
      
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == event.messageId) {
          final deliveredAt = event.deliveredAt ?? DateTime.now();
          return msg.copyWith(
            status: 'delivered',
            metadata: msg.metadata?.copyWith(
              deliveredAt: deliveredAt.toIso8601String(),
            ),
          );
        }
        return msg;
      }).toList();
      
      // Update both the messages list and the lastMessage in the conversation
      final updatedLastMessage = currentState.conversation.lastMessage?.id == event.messageId
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'delivered',
              metadata: currentState.conversation.lastMessage?.metadata?.copyWith(
                deliveredAt: (event.deliveredAt ?? DateTime.now()).toIso8601String(),
              ),
            )
          : currentState.conversation.lastMessage;
      
      // Create a new state to force UI rebuild
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        // TODO: Uncomment when call feature is re-implemented
        // // TODO: Uncomment when call feature is re-implemented
        // isCallActive: currentState.isCallActive,
        // // isAudioCall: currentState.isAudioCall,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    }
  }

  void _onBulkMessageDelivered(BulkMessageDelivered event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      
      final deliveredAt = DateTime.now();
      final updatedMessages = currentState.messages.map((msg) {
        if (event.messageIds.contains(msg.id)) {
          return msg.copyWith(
            status: 'delivered',
            metadata: msg.metadata?.copyWith(
              deliveredAt: deliveredAt.toIso8601String(),
            ),
          );
        }
        return msg;
      }).toList();
      
      // Update lastMessage if it's in the bulk update
      final updatedLastMessage = event.messageIds.contains(currentState.conversation.lastMessage?.id)
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'delivered',
              metadata: currentState.conversation.lastMessage?.metadata?.copyWith(
                deliveredAt: deliveredAt.toIso8601String(),
              ),
            )
          : currentState.conversation.lastMessage;
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        // TODO: Uncomment when call feature is re-implemented
        // // TODO: Uncomment when call feature is re-implemented
        // isCallActive: currentState.isCallActive,
        // // isAudioCall: currentState.isAudioCall,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
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
            metadata: msg.metadata?.copyWith(
              readAt: readAt.toIso8601String(),
            ),
          );
        }
        return msg;
      }).toList();
      
      AppLogger.info('🔵 Messages after update: ${updatedMessages.map((m) => '${m.id}: ${m.status} (readAt: ${m.metadata?.readAt})').join(', ')}');
      
      // Update both the messages list and the lastMessage in the conversation
      final updatedLastMessage = currentState.conversation.lastMessage?.id == event.messageId
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'read',
              metadata: currentState.conversation.lastMessage?.metadata?.copyWith(
                readAt: (event.readAt ?? DateTime.now()).toIso8601String(),
              ),
            )
          : currentState.conversation.lastMessage;
      
      AppLogger.info('🔵 Updated last message: ${updatedLastMessage?.id}: ${updatedLastMessage?.status} (readAt: ${updatedLastMessage?.metadata?.readAt})');
      
      // Create a new state to force UI rebuild
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        // TODO: Uncomment when call feature is re-implemented
        // isCallActive: currentState.isCallActive,
        // isAudioCall: currentState.isAudioCall,
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
            metadata: msg.metadata?.copyWith(
              readAt: readAt.toIso8601String(),
            ),
          );
        }
        return msg;
      }).toList();
      
      // Update lastMessage if it's in the bulk update
      final updatedLastMessage = event.messageIds.contains(currentState.conversation.lastMessage?.id)
          ? currentState.conversation.lastMessage?.copyWith(
              status: 'read',
              metadata: currentState.conversation.lastMessage?.metadata?.copyWith(
                readAt: readAt.toIso8601String(),
              ),
            )
          : currentState.conversation.lastMessage;
      
      emit(ConversationLoaded(
        conversation: currentState.conversation.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: DateTime.now(),
        ),
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        // TODO: Uncomment when call feature is re-implemented
        // isCallActive: currentState.isCallActive,
        // isAudioCall: currentState.isAudioCall,
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
          return msg.copyWith(content: event.newContent, metadata: msg.metadata?.copyWith());
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
      
      // Check if message already exists to prevent duplicates
      final messageExists = currentState.messages.any((msg) => msg.id == event.message.id);
      if (messageExists) {
        AppLogger.warning('⚠️ Sent message already exists in state, skipping duplicate: ${event.message.id}');
        return;
      }
      
      final updatedMessages = [event.message, ...currentState.messages];
      

      
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
      
      // If we have a lastMessage, update its status in the messages list
      if (event.lastMessage != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.id == event.lastMessage!.id) {
            return msg.copyWith(
              status: event.lastMessage!.status,
              metadata: msg.metadata?.copyWith(
                deliveredAt: event.lastMessage!.metadata?.deliveredAt,
                readAt: event.lastMessage!.metadata?.readAt,
              ),
            );
          }
          return msg;
        }).toList();
        
        emit(ConversationLoaded(
          conversation: currentState.conversation.copyWith(
            lastMessage: event.lastMessage,
            updatedAt: event.updatedAt,
            isTyping: event.isTyping,
          ),
          messages: updatedMessages,
          hasMoreMessages: currentState.hasMoreMessages,
          // TODO: Uncomment when call feature is re-implemented
        // isCallActive: currentState.isCallActive,
          // isAudioCall: currentState.isAudioCall,
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
        ));
      } else {
        // If no lastMessage, just update the conversation
        emit(ConversationLoaded(
          conversation: currentState.conversation.copyWith(
            updatedAt: event.updatedAt,
            isTyping: event.isTyping,
          ),
          messages: currentState.messages,
          hasMoreMessages: currentState.hasMoreMessages,
          // TODO: Uncomment when call feature is re-implemented
        // isCallActive: currentState.isCallActive,
          // isAudioCall: currentState.isAudioCall,
          participantName: currentState.participantName,
          participantAvatar: currentState.participantAvatar,
          isOnline: currentState.isOnline,
        ));
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
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.messageId) {
          // If this is a disappearing image message, start the timer
          if (message.type == MessageType.image && message.metadata?.isDisappearing == true) {
            // Create a new message with the viewed timestamp and start the timer
            final updatedMessage = message.copyWith(
              metadata: message.metadata?.copyWith(
                image: message.metadata?.image?.copyWith(
                  expiresAt: event.viewedAt.toIso8601String(),
                ),
              ),
            );
            return updatedMessage;
          }
          return message;
        }
        return message;
      }).toList();

      emit(ConversationLoaded(
        conversation: currentState.conversation,
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
    }
  }

  void _onUpdateMessageId(UpdateMessageId event, Emitter<ConversationState> emit) {
    if (state is ConversationLoaded) {
      final currentState = state as ConversationLoaded;
      
      // Find and update the message with the new ID
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.oldMessageId) {
          return message.copyWith(id: event.newMessageId);
        }
        return message;
      }).toList();
      
      emit(ConversationLoaded(
        conversation: currentState.conversation,
        messages: updatedMessages,
        hasMoreMessages: currentState.hasMoreMessages,
        participantName: currentState.participantName,
        participantAvatar: currentState.participantAvatar,
        isOnline: currentState.isOnline,
      ));
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
          final updatedMetadata = message.metadata?.copyWith();
          
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