import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/repositories/conversation_repository.dart';
import 'package:hushmate/domain/entities/matched_profile.dart'; 
import 'package:hushmate/domain/repositories/matches_repository.dart';

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
  }

  Future<void> _onLoadInbox(LoadInbox event, Emitter<InboxState> emit) async {
    emit(InboxLoading());
    try {
      final conversationsFuture = _conversationRepository.getConversations();
      final matchesFuture = _matchesRepository.getMatchedProfiles();

      final results = await Future.wait([conversationsFuture, matchesFuture]);

      final List<Conversation> existingConversations = results[0] as List<Conversation>; // Conversations with current user
      final List<MatchedProfile> matchedProfiles = results[1] as List<MatchedProfile>; // Matched users

      final List<Conversation> mergedConversations = List.from(existingConversations);
      // Create a set of participant IDs from existing conversations for quick lookup.
      // This assumes Conversation.participantId is the ID of the *other* user.
      final Set<String> existingParticipantIds = existingConversations.map((c) => c.participantId).toSet();

      for (var match in matchedProfiles) {
        // If the matched user is not already part of an existing conversation,
        // create a new conversation entry for them.
        if (!existingParticipantIds.contains(match.id)) {
          final newConversation = Conversation(
            // Conversation ID is the other participant's ID, same as participantId
            id: match.id, 
            participantId: match.id, 
            participantName: match.name, 
            participantAvatar: match.profilePicUrl,
            messages: [], // No messages initially
            lastMessageTime: DateTime.fromMillisecondsSinceEpoch(0), // Default timestamp
            isOnline: false, // Assume offline until presence system updates this
            unreadCount: 0, 
            userId: _currentUserId, // Use the passed-in current user ID
            // isMuted, isBlocked will use default values from Conversation constructor
          );
          mergedConversations.add(newConversation);
        }
      }
      
      mergedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      emit(InboxLoaded(mergedConversations));

    } catch (e) {
      emit(InboxError('Failed to load inbox: ${e.toString()}'));
    }
  }

  // Helper to generate a conversation ID if needed (example)
  // String generateConversationIdForUser(String userId) {
  //   // Implement a consistent way to generate or retrieve a conversation ID
  //   // For example, if it's based on the other user's ID directly:
  //   return 'conv_with_'+userId;
  // }
} 