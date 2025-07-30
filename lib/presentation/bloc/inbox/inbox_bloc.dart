import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/domain/repositories/conversation_repository.dart';
import 'package:nookly/domain/entities/matched_profile.dart'; 
import 'package:nookly/domain/repositories/matches_repository.dart';
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
  final MatchesRepository _matchesRepository;
  final String _currentUserId; // ID of the currently logged-in user

  InboxBloc({
    required ConversationRepository conversationRepository,
    required MatchesRepository matchesRepository, 
    required String currentUserId, // Pass current user's ID here
  }) : _conversationRepository = conversationRepository,
       _matchesRepository = matchesRepository, 
       _currentUserId = currentUserId,
       super(InboxInitial()) {
    on<LoadInbox>(_onLoadInbox);
    on<RefreshInbox>(_onRefreshInbox);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
  }

  Future<void> _onLoadInbox(LoadInbox event, Emitter<InboxState> emit) async {
    emit(InboxLoading());
    try {
      final conversationsFuture = _conversationRepository.getConversations();
      final matchesFuture = _matchesRepository.getMatchedProfiles();

      final results = await Future.wait([conversationsFuture, matchesFuture]);

      final List<Conversation> existingConversations = results[0] as List<Conversation>;
      final List<MatchedProfile> matchedProfiles = results[1] as List<MatchedProfile>;

      // Store current state before merging
      final Map<String, Conversation> currentConversations = {};
      if (state is InboxLoaded) {
        final currentState = state as InboxLoaded;
        for (var conversation in currentState.conversations) {
          currentConversations[conversation.id] = conversation;
        }
      }

      final List<Conversation> mergedConversations = List.from(existingConversations);
      final Set<String> existingParticipantIds = existingConversations.map((c) => c.participantId).toSet();

      for (var match in matchedProfiles) {
        if (!existingParticipantIds.contains(match.id)) {
          final currentConversation = currentConversations[match.id];
          final newConversation = Conversation(
            id: match.id,
            participantId: match.id,
            participantName: match.name,
            participantAvatar: match.profilePicUrl,
            messages: currentConversation?.messages ?? [],
            lastMessage: currentConversation?.lastMessage,
            lastMessageTime: currentConversation?.lastMessageTime ?? DateTime.now(), // Use current time for new matches
            isOnline: false,
            unreadCount: currentConversation?.unreadCount ?? 0,
            userId: _currentUserId,
            updatedAt: currentConversation?.updatedAt ?? DateTime.now(), // Use current time for new matches
          );
          mergedConversations.add(newConversation);
        }
      }
      
      // Preserve current state for existing conversations
      for (var i = 0; i < mergedConversations.length; i++) {
        final conversation = mergedConversations[i];
        final currentConversation = currentConversations[conversation.id];
        if (currentConversation != null) {
          // Handle disappearing images logic when preserving state
          Message? lastMessage = currentConversation.lastMessage;
          if (lastMessage != null && lastMessage.isDisappearing && lastMessage.type == MessageType.image) {
            final isViewed = lastMessage.metadata?.containsKey('viewedAt') == true;
            final disappearingTime = lastMessage.disappearingTime ?? 5;
            
            if (isViewed) {
              // Check if the image has expired since being viewed
              final viewedAt = DateTime.parse(lastMessage.metadata!['viewedAt']!);
              final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
              
              if (elapsedSeconds >= disappearingTime) {
                AppLogger.info('Preserving state: Disappearing image has expired, not showing');
                lastMessage = null; // Don't show expired disappearing images
              } else {
                AppLogger.info('Preserving state: Disappearing image is still valid');
              }
            } else {
              AppLogger.info('Preserving state: Unviewed disappearing image, showing placeholder');
            }
          }
          
          mergedConversations[i] = conversation.copyWith(
            unreadCount: currentConversation.unreadCount,
            lastMessage: lastMessage,
            lastMessageTime: lastMessage?.timestamp ?? currentConversation.lastMessageTime,
            messages: currentConversation.messages,
            updatedAt: currentConversation.updatedAt,
          );
        }
      }
      
      mergedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      emit(InboxLoaded(mergedConversations));

    } catch (e) {
      emit(InboxError('Failed to load inbox: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshInbox(RefreshInbox event, Emitter<InboxState> emit) async {
    await _onLoadInbox(LoadInbox(), emit);
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

  // Helper to generate a conversation ID if needed (example)
  // String generateConversationIdForUser(String userId) {
  //   // Implement a consistent way to generate or retrieve a conversation ID
  //   // For example, if it's based on the other user's ID directly:
  //   return 'conv_with_'+userId;
  // }
} 