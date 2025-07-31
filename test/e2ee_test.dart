import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/utils/e2ee_utils.dart';

void main() {
  group('E2EE Utils Tests', () {
    test('should generate conversation key', () {
      final key1 = E2EEUtils.generateConversationKey();
      final key2 = E2EEUtils.generateConversationKey();
      
      expect(key1, isNotEmpty);
      expect(key2, isNotEmpty);
      expect(key1, isNot(equals(key2))); // Keys should be different
    });

    test('should encrypt and decrypt message correctly', () {
      final testMessage = 'Hello, this is a test message!';
      final key = E2EEUtils.generateConversationKey();
      
      final encrypted = E2EEUtils.encryptMessage(testMessage, key);
      final decrypted = E2EEUtils.decryptMessage(encrypted, key);
      
      expect(decrypted, equals(testMessage));
    });

    test('should generate consistent conversation ID', () {
      final user1Id = 'user123';
      final user2Id = 'user456';
      
      final conversationId1 = E2EEUtils.generateConversationId(user1Id, user2Id);
      final conversationId2 = E2EEUtils.generateConversationId(user2Id, user1Id);
      
      expect(conversationId1, equals(conversationId2)); // Should be same regardless of order
    });

    test('should handle encryption/decryption with special characters', () {
      final testMessage = 'Hello! This message has special chars: @#\$%^&*()_+-=[]{}|;:,.<>?';
      final key = E2EEUtils.generateConversationKey();
      
      final encrypted = E2EEUtils.encryptMessage(testMessage, key);
      final decrypted = E2EEUtils.decryptMessage(encrypted, key);
      
      expect(decrypted, equals(testMessage));
    });

    test('should fail decryption with wrong key', () {
      final testMessage = 'Hello, this is a test message!';
      final key1 = E2EEUtils.generateConversationKey();
      final key2 = E2EEUtils.generateConversationKey();
      
      final encrypted = E2EEUtils.encryptMessage(testMessage, key1);
      
      expect(() => E2EEUtils.decryptMessage(encrypted, key2), throwsException);
    });

    test('should pass encryption/decryption test', () {
      final success = E2EEUtils.testEncryptionDecryption();
      expect(success, isTrue);
    });
  });
} 