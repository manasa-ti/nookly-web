import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockConversationRepository extends Mock implements ConversationRepository {}

void main() {
  group('Disappearing Image Bloc Tests', () {
    late ConversationBloc conversationBloc;
    late MockConversationRepository mockRepository;

    setUp(() {
      mockRepository = MockConversationRepository();
      conversationBloc = ConversationBloc(repository: mockRepository);
    });

    tearDown(() {
      conversationBloc.close();
    });

    group('Message Viewed Event', () {
      test('should start timer for disappearing image when viewed', () {
        // Create a test conversation with disappearing image message
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // Trigger message viewed event
        final viewedAt = DateTime.now();
        conversationBloc.add(MessageViewed('msg1', viewedAt));

        // Verify the message has viewedAt metadata
        final state = conversationBloc.state as ConversationLoaded;
        final updatedMessage = state.messages.firstWhere((msg) => msg.id == 'msg1');
        
        expect(updatedMessage.metadata, isNotNull);
        expect(updatedMessage.metadata!['viewedAt'], isNotNull);
        expect(updatedMessage.metadata!['viewedAt'], equals(viewedAt.toIso8601String()));
      });

      test('should not modify non-disappearing image messages', () {
        // Create a test conversation with regular image message
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: false,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: false,
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // Trigger message viewed event
        final viewedAt = DateTime.now();
        conversationBloc.add(MessageViewed('msg1', viewedAt));

        // Verify the message is not modified
        final state = conversationBloc.state as ConversationLoaded;
        final updatedMessage = state.messages.firstWhere((msg) => msg.id == 'msg1');
        
        expect(updatedMessage.metadata, isNull);
      });

      test('should not modify non-image messages', () {
        // Create a test conversation with text message
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test text',
            createdAt: DateTime.now(),
            type: MessageType.text,
            isDisappearing: true,
            disappearingTime: 5,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test text',
            createdAt: DateTime.now(),
            type: MessageType.text,
            isDisappearing: true,
            disappearingTime: 5,
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // Trigger message viewed event
        final viewedAt = DateTime.now();
        conversationBloc.add(MessageViewed('msg1', viewedAt));

        // Verify the message is not modified
        final state = conversationBloc.state as ConversationLoaded;
        final updatedMessage = state.messages.firstWhere((msg) => msg.id == 'msg1');
        
        expect(updatedMessage.metadata, isNull);
      });
    });

    group('Message Filtering', () {
      test('should filter out expired disappearing images', () {
        // Create a test conversation with expired disappearing image
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
            metadata: {
              'viewedAt': DateTime.now().subtract(const Duration(seconds: 10)).toIso8601String(),
            },
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // The message should be filtered out due to expiration
        final state = conversationBloc.state as ConversationLoaded;
        expect(state.messages, isEmpty);
      });

      test('should keep valid disappearing images', () {
        // Create a test conversation with valid disappearing image
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
            metadata: {
              'viewedAt': DateTime.now().subtract(const Duration(seconds: 2)).toIso8601String(),
            },
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // The message should be kept as it's still valid
        final state = conversationBloc.state as ConversationLoaded;
        expect(state.messages, hasLength(1));
        expect(state.messages.first.id, equals('msg1'));
      });

      test('should keep unviewed disappearing images', () {
        // Create a test conversation with unviewed disappearing image
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // The message should be kept as it's unviewed
        final state = conversationBloc.state as ConversationLoaded;
        expect(state.messages, hasLength(1));
        expect(state.messages.first.id, equals('msg1'));
      });
    });

    group('Edge Cases', () {
      test('should handle missing disappearing time', () {
        // Create a test conversation with disappearing image without time
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: null,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: null,
            metadata: {
              'viewedAt': DateTime.now().subtract(const Duration(seconds: 10)).toIso8601String(),
            },
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // Should use default disappearing time (5 seconds)
        final state = conversationBloc.state as ConversationLoaded;
        expect(state.messages, isEmpty); // Should be filtered out
      });

      test('should handle invalid viewedAt timestamp', () {
        // Create a test conversation with invalid timestamp
        final testConversation = Conversation(
          id: 'conv1',
          participantId: 'user2',
          participantName: 'Test User',
          lastMessage: Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
          ),
          unreadCount: 0,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        final testMessages = [
          Message(
            id: 'msg1',
            sender: 'user2',
            receiver: 'user1',
            content: 'Test image',
            createdAt: DateTime.now(),
            type: MessageType.image,
            isDisappearing: true,
            disappearingTime: 5,
            metadata: {
              'viewedAt': 'invalid_timestamp',
            },
          ),
        ];

        // Emit initial state
        conversationBloc.emit(ConversationLoaded(
          conversation: testConversation,
          messages: testMessages,
          hasMoreMessages: false,
          participantName: 'Test User',
          participantAvatar: null,
          isOnline: true,
        ));

        // Should handle gracefully and keep the message
        final state = conversationBloc.state as ConversationLoaded;
        expect(state.messages, hasLength(1));
        expect(state.messages.first.id, equals('msg1'));
      });
    });
  });
}
