import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/utils/e2ee_utils.dart';

void main() {
  group('Conversation Key Tests', () {
    test('should generate consistent conversation IDs', () {
      final user1Id = '68848ac04d763c4ca8885208';
      final user2Id = '68821610fb0c1337a41394a9';
      
      final conversationId1 = E2EEUtils.generateConversationId(user1Id, user2Id);
      final conversationId2 = E2EEUtils.generateConversationId(user2Id, user1Id);
      
      expect(conversationId1, equals(conversationId2));
      print('Conversation ID: $conversationId1');
    });

    test('should encrypt and decrypt with deterministic key', () {
      final testMessage = 'Hello, this is a test message!';
      final user1Id = '68848ac04d763c4ca8885208';
      final user2Id = '68821610fb0c1337a41394a9';
      final key = E2EEUtils.generateDeterministicKey(user1Id, user2Id);
      
      final encrypted = E2EEUtils.encryptMessage(testMessage, key);
      final decrypted = E2EEUtils.decryptMessage(encrypted, key);
      
      expect(decrypted, equals(testMessage));
      print('Original: $testMessage');
      print('Decrypted: $decrypted');
      print('Match: ${testMessage == decrypted}');
    });

    test('should fail with different keys', () {
      final testMessage = 'Hello, this is a test message!';
      final key1 = E2EEUtils.generateConversationKey();
      final key2 = E2EEUtils.generateConversationKey();
      
      final encrypted = E2EEUtils.encryptMessage(testMessage, key1);
      
      expect(() => E2EEUtils.decryptMessage(encrypted, key2), throwsException);
    });
  });
} 