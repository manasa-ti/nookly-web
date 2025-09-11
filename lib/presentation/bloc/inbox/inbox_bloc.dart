import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/repositories/conversation_repository.dart';
// Removed MatchesRepository dependency - now using unified API
import 'package:nookly/core/services/api_cache_service.dart';
import 'package:nookly/core/utils/logger.dart';

part 'inbox_event.dart';
part 'inbox_state.dart';

// Ensure part files extend Equatable if they are meant to
// For example, in inbox_event.dart:
// abstract class InboxEvent extends Equatable { ... }
// And in inbox_state.dart:
// abstract class InboxState extends Equatable { ... }

class InboxBloc extends Bloc<InboxEvent, InboxState> {
  final ConversationRepository _conversationRepository;
  final String _currentUserId; // ID of the currently logged-in user

  InboxBloc({
    required ConversationRepository conversationRepository,
    required String currentUserId, // Pass current user's ID here
  }) : _conversationRepository = conversationRepository,
       _currentUserId = currentUserId,
       super(InboxInitial()) {
    on<LoadInbox>(_onLoadInbox);
    on<RefreshInbox>(_onRefreshInbox);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
  }

  Future<void> _onLoadInbox(LoadInbox event, Emitter<InboxState> emit) async {
    emit(InboxLoading());
    try {
      AppLogger.info('🔵 InboxBloc: Starting inbox load with unified API');
      final stopwatch = Stopwatch()..start();
      
      // Single API call to get unified conversations (includes both existing conversations and new matches)
      final conversations = await _conversationRepository.getConversations();
      
      stopwatch.stop();
      AppLogger.info('🔵 InboxBloc: Unified API loaded in ${stopwatch.elapsedMilliseconds}ms');
      AppLogger.info('🔵 InboxBloc: Found ${conversations.length} total conversations (existing + new matches)');
      
      emit(InboxLoaded(conversations));

    } catch (e) {
      emit(InboxError('Failed to load inbox: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshInbox(RefreshInbox event, Emitter<InboxState> emit) async {
    try {
      // Invalidate cache before refreshing to ensure fresh data
      final apiCacheService = ApiCacheService();
      apiCacheService.invalidateCache('unified_conversations_$_currentUserId');
      AppLogger.info('🔵 InboxBloc: Unified cache invalidated before refresh');
      
      // Force refresh by calling the same logic as LoadInbox
      await _onLoadInbox(LoadInbox(), emit);
    } catch (e) {
      emit(InboxError('Failed to refresh inbox: ${e.toString()}'));
    }
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<InboxState> emit,
  ) async {
    if (state is InboxLoaded) {
      final currentState = state as InboxLoaded;
      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          AppLogger.info('🔵 Marking conversation ${conversation.participantName} as read. Previous unread count: ${conversation.unreadCount}');
          return conversation.copyWith(unreadCount: 0);
        }
        return conversation;
      }).toList();
      
      emit(InboxLoaded(updatedConversations));
    }
  }

  // Removed _mergeConversationsWithMatches method - no longer needed with unified API
} 