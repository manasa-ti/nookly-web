import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/utils/e2ee_utils.dart';

void main() {
  group('Deterministic Key Tests', () {
    test('should generate same key for same conversation', () {
      final user1Id = '68848ac04d763c4ca8885208';
      final user2Id = '68821610fb0c1337a41394a9';
      
      final key1 = E2EEUtils.generateDeterministicKey(user1Id, user2Id);
      final key2 = E2EEUtils.generateDeterministicKey(user2Id, user1Id);
      final key3 = E2EEUtils.generateDeterministicKey(user1Id, user2Id);
      
      expect(key1, equals(key2));
      expect(key1, equals(key3));
      print('Key 1: ${key1.substring(0, 10)}...');
      print('Key 2: ${key2.substring(0, 10)}...');
      print('Key 3: ${key3.substring(0, 10)}...');
    });

    test('should generate different keys for different conversations', () {
      final user1Id = '68848ac04d763c4ca8885208';
      final user2Id = '68821610fb0c1337a41394a9';
      final user3Id = '999999999999999999999999';
      
      final key1 = E2EEUtils.generateDeterministicKey(user1Id, user2Id);
      final key2 = E2EEUtils.generateDeterministicKey(user1Id, user3Id);
      
      expect(key1, isNot(equals(key2)));
      print('Key 1 (user1-user2): ${key1.substring(0, 10)}...');
      print('Key 2 (user1-user3): ${key2.substring(0, 10)}...');
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
  });
} 