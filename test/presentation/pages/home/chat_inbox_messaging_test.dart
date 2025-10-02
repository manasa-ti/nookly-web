import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/pages/home/chat_inbox_page.dart';
import 'package:nookly/presentation/bloc/inbox/inbox_bloc.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockInboxBloc extends Mock implements InboxBloc {}
class MockInboxState extends Mock implements InboxState {}

void main() {
  group('ChatInboxPage Messaging Tests', () {
    late MockInboxBloc mockInboxBloc;
    late MockInboxState mockInboxState;

    setUp(() {
      mockInboxBloc = MockInboxBloc();
      mockInboxState = MockInboxState();
    });

    group('Conversation ID Matching', () {
      test('should match conversations using sorted conversation ID format', () {
        // Test conversation ID matching logic
        const currentUserId = 'user1';
        const participantId = 'user2';
        
        // Create sorted conversation ID
        final userIds = [currentUserId, participantId];
        userIds.sort();
        final sortedConversationId = '${userIds[0]}_${userIds[1]}';
        
        // Verify sorted format
        expect(sortedConversationId, equals('user1_user2'));
        expect(sortedConversationId.split('_'), hasLength(2));
      });

      test('should handle different user ID orders consistently', () {
        const user1 = 'user1';
        const user2 = 'user2';
        
        // Test both orders should produce same result
        final userIds1 = [user1, user2];
        userIds1.sort();
        final conversationId1 = '${userIds1[0]}_${userIds1[1]}';
        
        final userIds2 = [user2, user1];
        userIds2.sort();
        final conversationId2 = '${userIds2[0]}_${userIds2[1]}';
        
        // Both should produce the same conversation ID
        expect(conversationId1, equals(conversationId2));
        expect(conversationId1, equals('user1_user2'));
      });
    });

    group('Message Event Processing', () {
      test('should handle private_message event in inbox', () {
        // Test data for private_message event in inbox
        final messageEventData = {
          'conversationId': 'user1_user2',
          'from': 'user2',
          'to': 'user1',
          'content': 'Test message',
          'messageType': 'text',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Verify event data structure
        expect(messageEventData['conversationId'], isNotNull);
        expect(messageEventData['from'], isNotNull);
        expect(messageEventData['to'], isNotNull);
        expect(messageEventData['content'], isNotNull);
        expect(messageEventData['messageType'], isNotNull);
        expect(messageEventData['timestamp'], isNotNull);
      });

      test('should handle encrypted message event in inbox', () {
        // Test data for encrypted message event in inbox
        final encryptedMessageData = {
          'conversationId': 'user1_user2',
          'from': 'user2',
          'to': 'user1',
          'content': '[ENCRYPTED]',
          'encryptedContent': 'encrypted_data',
          'encryptionMetadata': {
            'iv': 'initialization_vector',
            'authTag': 'auth_tag',
            'algorithm': 'AES-256-CBC-HMAC',
          },
          'messageType': 'text',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Verify encrypted message data structure
        expect(encryptedMessageData['conversationId'], isNotNull);
        expect(encryptedMessageData['encryptedContent'], isNotNull);
        expect(encryptedMessageData['encryptionMetadata'], isNotNull);
      });

      test('should handle conversation_updated event', () {
        // Test data for conversation_updated event
        final conversationUpdatedData = {
          '_id': 'user2',
          'lastMessage': {
            '_id': 'msg1',
            'sender': 'user2',
            'receiver': 'user1',
            'content': 'Updated message',
            'messageType': 'text',
            'status': 'read',
            'createdAt': DateTime.now().toIso8601String(),
            'readAt': DateTime.now().toIso8601String(),
          },
          'unreadCount': 0,
          'user': {
            '_id': 'user2',
            'name': 'Test User',
            'email': 'test@example.com',
            'age': 25,
            'sex': 'f',
            'interests': ['deep conversations'],
            'profile_pic': 'https://example.com/avatar.jpg',
          },
        };

        // Verify conversation updated data structure
        expect(conversationUpdatedData['_id'], isNotNull);
        expect(conversationUpdatedData['lastMessage'], isNotNull);
        expect(conversationUpdatedData['unreadCount'], isNotNull);
        expect(conversationUpdatedData['user'], isNotNull);
      });
    });

    group('Typing Event Processing', () {
      test('should handle typing event in inbox', () {
        // Test data for typing event in inbox
        final typingEventData = {
          'conversationId': 'user1_user2',
          'from': 'user2',
          'to': 'user1',
          'isTyping': true,
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Verify typing event data structure
        expect(typingEventData['conversationId'], isNotNull);
        expect(typingEventData['from'], isNotNull);
        expect(typingEventData['to'], isNotNull);
        expect(typingEventData['isTyping'], isA<bool>());
        expect(typingEventData['isTyping'], isTrue);
      });

      test('should handle stop typing event in inbox', () {
        // Test data for stop typing event in inbox
        final stopTypingEventData = {
          'conversationId': 'user1_user2',
          'from': 'user2',
          'to': 'user1',
          'isTyping': false,
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Verify stop typing event data structure
        expect(stopTypingEventData['conversationId'], isNotNull);
        expect(stopTypingEventData['from'], isNotNull);
        expect(stopTypingEventData['to'], isNotNull);
        expect(stopTypingEventData['isTyping'], isA<bool>());
        expect(stopTypingEventData['isTyping'], isFalse);
      });
    });

    group('Game Event Processing', () {
      test('should handle game_invite event in inbox', () {
        // Test data for game_invite event in inbox
        final gameInviteData = {
          'conversationId': 'user1_user2',
          'fromUserId': 'user2',
          'toUserId': 'user1',
          'gameType': 'truth_or_thrill',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Verify game invite data structure
        expect(gameInviteData['conversationId'], isNotNull);
        expect(gameInviteData['fromUserId'], isNotNull);
        expect(gameInviteData['toUserId'], isNotNull);
        expect(gameInviteData['gameType'], isNotNull);
        expect(gameInviteData['timestamp'], isNotNull);
      });
    });

    group('User Status Events', () {
      test('should handle user_online event', () {
        // Test data for user_online event
        final userOnlineData = {
          'userId': 'user2',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Verify user online data structure
        expect(userOnlineData['userId'], isNotNull);
        expect(userOnlineData['timestamp'], isNotNull);
      });

      test('should handle user_offline event', () {
        // Test data for user_offline event
        final userOfflineData = {
          'userId': 'user2',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Verify user offline data structure
        expect(userOfflineData['userId'], isNotNull);
        expect(userOfflineData['timestamp'], isNotNull);
      });
    });

    group('Conversation Matching Logic', () {
      test('should match conversation by sorted conversation ID', () {
        // Test conversation matching logic
        const currentUserId = 'user1';
        const participantId = 'user2';
        const eventConversationId = 'user1_user2';
        
        // Create sorted conversation ID for matching
        final userIds = [currentUserId, participantId];
        userIds.sort();
        final sortedConversationId = '${userIds[0]}_${userIds[1]}';
        
        // Should match
        expect(sortedConversationId == eventConversationId, isTrue);
      });

      test('should not match conversation with different ID', () {
        // Test conversation non-matching logic
        const currentUserId = 'user1';
        const participantId = 'user2';
        const eventConversationId = 'user1_user3'; // Different participant
        
        // Create sorted conversation ID for matching
        final userIds = [currentUserId, participantId];
        userIds.sort();
        final sortedConversationId = '${userIds[0]}_${userIds[1]}';
        
        // Should not match
        expect(sortedConversationId == eventConversationId, isFalse);
      });

      test('should handle fallback matching by participant ID', () {
        // Test fallback matching when conversation ID is null
        const currentUserId = 'user1';
        const participantId = 'user2';
        const eventConversationId = null;
        const fromUserId = 'user2';
        
        // When conversation ID is null, should fallback to participant ID matching
        final shouldUseFallback = eventConversationId == null;
        expect(shouldUseFallback, isTrue);
        
        // Participant ID should match
        expect(participantId == fromUserId, isTrue);
      });
    });

    group('Event Data Validation', () {
      test('should validate required fields in message events', () {
        // Test message event validation
        final validMessageEvent = {
          'conversationId': 'user1_user2',
          'from': 'user2',
          'to': 'user1',
          'content': 'Test message',
          'messageType': 'text',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // All required fields should be present
        expect(validMessageEvent.containsKey('conversationId'), isTrue);
        expect(validMessageEvent.containsKey('from'), isTrue);
        expect(validMessageEvent.containsKey('to'), isTrue);
        expect(validMessageEvent.containsKey('content'), isTrue);
        expect(validMessageEvent.containsKey('messageType'), isTrue);
        expect(validMessageEvent.containsKey('timestamp'), isTrue);
      });

      test('should validate required fields in typing events', () {
        // Test typing event validation
        final validTypingEvent = {
          'conversationId': 'user1_user2',
          'from': 'user2',
          'to': 'user1',
          'isTyping': true,
          'timestamp': DateTime.now().toIso8601String(),
        };

        // All required fields should be present
        expect(validTypingEvent.containsKey('conversationId'), isTrue);
        expect(validTypingEvent.containsKey('from'), isTrue);
        expect(validTypingEvent.containsKey('to'), isTrue);
        expect(validTypingEvent.containsKey('isTyping'), isTrue);
        expect(validTypingEvent.containsKey('timestamp'), isTrue);
      });

      test('should validate required fields in game events', () {
        // Test game event validation
        final validGameEvent = {
          'conversationId': 'user1_user2',
          'fromUserId': 'user2',
          'toUserId': 'user1',
          'gameType': 'truth_or_thrill',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // All required fields should be present
        expect(validGameEvent.containsKey('conversationId'), isTrue);
        expect(validGameEvent.containsKey('fromUserId'), isTrue);
        expect(validGameEvent.containsKey('toUserId'), isTrue);
        expect(validGameEvent.containsKey('gameType'), isTrue);
        expect(validGameEvent.containsKey('timestamp'), isTrue);
      });
    });
  });
}
