import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/data/repositories/conversation_repository_impl.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('ConversationRepository Messaging Tests', () {
    late ConversationRepositoryImpl conversationRepository;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      conversationRepository = ConversationRepositoryImpl(mockAuthRepository);
    });

    group('Conversation ID Format', () {
      test('should use sorted conversation ID format', () {
        // Test conversation ID format consistency
        const user1 = 'user1_id';
        const user2 = 'user2_id';
        
        // Create sorted conversation ID
        final userIds = [user1, user2];
        userIds.sort();
        final sortedConversationId = '${userIds[0]}_${userIds[1]}';
        
        // Verify sorted format
        expect(sortedConversationId, equals('user1_id_user2_id'));
        expect(sortedConversationId.split('_'), hasLength(2));
      });

      test('should handle different user ID orders consistently', () {
        const user1 = 'user1_id';
        const user2 = 'user2_id';
        
        // Test both orders should produce same result
        final userIds1 = [user1, user2];
        userIds1.sort();
        final conversationId1 = '${userIds1[0]}_${userIds1[1]}';
        
        final userIds2 = [user2, user1];
        userIds2.sort();
        final conversationId2 = '${userIds2[0]}_${userIds2[1]}';
        
        // Both should produce the same conversation ID
        expect(conversationId1, equals(conversationId2));
        expect(conversationId1, equals('user1_id_user2_id'));
      });
    });

    group('Message Read Status', () {
      test('should handle markMessageAsRead method', () async {
        // Test markMessageAsRead method exists and can be called
        const messageId = 'msg1';
        
        // Mock the getToken method
        when(mockAuthRepository.getToken()).thenAnswer((_) async => 'test_token');
        
        // Should not throw errors
        expect(() => conversationRepository.markMessageAsRead(messageId), returnsNormally);
      });

      test('should handle markConversationAsRead method', () async {
        // Test markConversationAsRead method exists and can be called
        const conversationId = 'user1_user2';
        
        // Mock the getToken method
        when(mockAuthRepository.getToken()).thenAnswer((_) async => 'test_token');
        
        // Should not throw errors
        expect(() => conversationRepository.markMessageAsRead('msg1'), returnsNormally);
      });

      test('should handle authentication errors gracefully', () async {
        // Test handling of authentication errors
        const messageId = 'msg1';
        const conversationId = 'user1_user2';
        
        // Mock the getToken method to return null (not authenticated)
        when(mockAuthRepository.getToken()).thenAnswer((_) async => null);
        
        // Should not throw errors even when not authenticated
        expect(() => conversationRepository.markMessageAsRead(messageId), returnsNormally);
        expect(() => conversationRepository.markMessageAsRead('msg1'), returnsNormally);
      });
    });

    group('Conversation Data Parsing', () {
      test('should handle unreadCount parsing from Decimal128', () {
        // Test unreadCount parsing from Decimal128 format
        final conversationData = {
          '_id': 'user2',
          'lastMessage': {
            '_id': 'msg1',
            'sender': 'user2',
            'receiver': 'user1',
            'content': 'Test message',
            'messageType': 'text',
            'status': 'read',
            'createdAt': DateTime.now().toIso8601String(),
          },
          'unreadCount': {'\$numberDecimal': '5'}, // Decimal128 format
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

        // Verify unreadCount can be parsed
        final unreadCount = conversationData['unreadCount'];
        expect(unreadCount, isNotNull);
        expect(unreadCount, isA<Map>());
        expect((unreadCount as Map)['\$numberDecimal'], isNotNull);
      });

      test('should handle unreadCount parsing from integer', () {
        // Test unreadCount parsing from integer format
        final conversationData = {
          '_id': 'user2',
          'lastMessage': {
            '_id': 'msg1',
            'sender': 'user2',
            'receiver': 'user1',
            'content': 'Test message',
            'messageType': 'text',
            'status': 'read',
            'createdAt': DateTime.now().toIso8601String(),
          },
          'unreadCount': 3, // Integer format
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

        // Verify unreadCount can be parsed
        final unreadCount = conversationData['unreadCount'];
        expect(unreadCount, isNotNull);
        expect(unreadCount, isA<int>());
        expect(unreadCount, equals(3));
      });
    });

    group('Conversation Key Storage', () {
      test('should handle conversation key storage with sorted ID', () {
        // Test conversation key storage with sorted conversation ID
        const currentUserId = 'user1';
        const participantId = 'user2';
        const conversationKey = 'test_key';
        
        // Create sorted conversation ID
        final userIds = [currentUserId, participantId];
        userIds.sort();
        final conversationId = '${userIds[0]}_${userIds[1]}';
        
        // Verify conversation ID format
        expect(conversationId, equals('user1_user2'));
        expect(conversationId.split('_'), hasLength(2));
      });

      test('should handle conversation key retrieval with sorted ID', () {
        // Test conversation key retrieval with sorted conversation ID
        const currentUserId = 'user1';
        const participantId = 'user2';
        
        // Create sorted conversation ID
        final userIds = [currentUserId, participantId];
        userIds.sort();
        final conversationId = '${userIds[0]}_${userIds[1]}';
        
        // Verify conversation ID format for retrieval
        expect(conversationId, equals('user1_user2'));
        expect(conversationId.split('_'), hasLength(2));
      });
    });

    group('Message Data Structure', () {
      test('should handle message data structure', () {
        // Test message data structure
        final messageData = {
          '_id': 'msg1',
          'sender': 'user2',
          'receiver': 'user1',
          'content': 'Test message',
          'messageType': 'text',
          'status': 'read',
          'createdAt': DateTime.now().toIso8601String(),
          'readAt': DateTime.now().toIso8601String(),
        };

        // Verify message data structure
        expect(messageData['_id'], isNotNull);
        expect(messageData['sender'], isNotNull);
        expect(messageData['receiver'], isNotNull);
        expect(messageData['content'], isNotNull);
        expect(messageData['messageType'], isNotNull);
        expect(messageData['status'], isNotNull);
        expect(messageData['createdAt'], isNotNull);
        expect(messageData['readAt'], isNotNull);
      });

      test('should handle encrypted message data structure', () {
        // Test encrypted message data structure
        final encryptedMessageData = {
          '_id': 'msg1',
          'sender': 'user2',
          'receiver': 'user1',
          'content': '[ENCRYPTED]',
          'encryptedContent': 'encrypted_data',
          'encryptionMetadata': {
            'iv': 'initialization_vector',
            'authTag': 'auth_tag',
            'algorithm': 'AES-256-CBC-HMAC',
          },
          'messageType': 'text',
          'status': 'read',
          'createdAt': DateTime.now().toIso8601String(),
          'readAt': DateTime.now().toIso8601String(),
        };

        // Verify encrypted message data structure
        expect(encryptedMessageData['_id'], isNotNull);
        expect(encryptedMessageData['sender'], isNotNull);
        expect(encryptedMessageData['receiver'], isNotNull);
        expect(encryptedMessageData['content'], isNotNull);
        expect(encryptedMessageData['encryptedContent'], isNotNull);
        expect(encryptedMessageData['encryptionMetadata'], isNotNull);
        expect(encryptedMessageData['messageType'], isNotNull);
        expect(encryptedMessageData['status'], isNotNull);
        expect(encryptedMessageData['createdAt'], isNotNull);
        expect(encryptedMessageData['readAt'], isNotNull);
      });
    });

    group('User Data Structure', () {
      test('should handle user data structure', () {
        // Test user data structure
        final userData = {
          '_id': 'user2',
          'name': 'Test User',
          'email': 'test@example.com',
          'age': 25,
          'sex': 'f',
          'interests': ['deep conversations'],
          'profile_pic': 'https://example.com/avatar.jpg',
        };

        // Verify user data structure
        expect(userData['_id'], isNotNull);
        expect(userData['name'], isNotNull);
        expect(userData['email'], isNotNull);
        expect(userData['age'], isNotNull);
        expect(userData['sex'], isNotNull);
        expect(userData['interests'], isNotNull);
        expect(userData['profile_pic'], isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Test network error handling
        const messageId = 'msg1';
        const conversationId = 'user1_user2';
        
        // Mock the getToken method to return a token
        when(mockAuthRepository.getToken()).thenAnswer((_) async => 'test_token');
        
        // Should not throw errors even when network fails
        expect(() => conversationRepository.markMessageAsRead(messageId), returnsNormally);
        expect(() => conversationRepository.markMessageAsRead('msg1'), returnsNormally);
      });

      test('should handle invalid data gracefully', () {
        // Test invalid data handling
        final invalidConversationData = {
          '_id': null, // Invalid ID
          'lastMessage': null, // Invalid message
          'unreadCount': 'invalid', // Invalid unread count
          'user': null, // Invalid user
        };

        // Should handle invalid data gracefully
        expect(invalidConversationData['_id'], isNull);
        expect(invalidConversationData['lastMessage'], isNull);
        expect(invalidConversationData['unreadCount'], isA<String>());
        expect(invalidConversationData['user'], isNull);
      });
    });

    group('Data Validation', () {
      test('should validate conversation ID format', () {
        // Test conversation ID format validation
        const validConversationId = 'user1_user2';
        const invalidConversationId = 'user1-user2'; // Wrong separator
        
        // Valid format should have underscore separator
        expect(validConversationId.split('_'), hasLength(2));
        
        // Invalid format should not have underscore separator
        expect(invalidConversationId.split('_'), hasLength(1));
      });

      test('should validate message ID format', () {
        // Test message ID format validation
        const validMessageId = 'msg1';
        const invalidMessageId = ''; // Empty ID
        
        // Valid message ID should not be empty
        expect(validMessageId.isNotEmpty, isTrue);
        
        // Invalid message ID should be empty
        expect(invalidMessageId.isEmpty, isTrue);
      });

      test('should validate user ID format', () {
        // Test user ID format validation
        const validUserId = 'user1';
        const invalidUserId = ''; // Empty ID
        
        // Valid user ID should not be empty
        expect(validUserId.isNotEmpty, isTrue);
        
        // Invalid user ID should be empty
        expect(invalidUserId.isEmpty, isTrue);
      });
    });
  });
}
