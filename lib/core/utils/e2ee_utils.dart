import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart' hide Key;
import 'package:nookly/core/utils/logger.dart';

class E2EEUtils {
  static String generateConversationKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static String generateDeterministicKey(String user1Id, String user2Id) {
    // Generate a deterministic key based on conversation participants
    // This ensures both users get the same key for the same conversation
    final conversationId = generateConversationId(user1Id, user2Id);
    AppLogger.info('🔵 Generating deterministic key for conversation: $conversationId');
    AppLogger.info('🔵 User1 ID: $user1Id, User2 ID: $user2Id');
    final hash = sha256.convert(utf8.encode(conversationId));
    final keyBytes = hash.bytes.take(32).toList();
    final key = base64Encode(keyBytes);
    AppLogger.info('🔵 Generated key (first 20 chars): ${key.substring(0, key.length > 20 ? 20 : key.length)}...');
    return key;
  }

  static Map<String, dynamic> encryptMessage(String message, String key) {
    try {
      final keyBytes = base64Decode(key);
      final keyObj = encrypt.Key(keyBytes);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(keyObj));
      
      final encrypted = encrypter.encrypt(message, iv: iv);
      
      // Generate HMAC for integrity
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(encrypted.bytes);
      
      return {
        'encryptedContent': base64Encode(encrypted.bytes),
        'iv': base64Encode(iv.bytes),
        'authTag': base64Encode(digest.bytes),
        'algorithm': 'AES-256-CBC-HMAC'
      };
    } catch (e) {
      AppLogger.error('Failed to encrypt message: $e');
      throw Exception('Failed to encrypt message: $e');
    }
  }

  static String decryptMessage(Map<String, dynamic> encryptedData, String key) {
    try {
      AppLogger.info('🔵 Starting decryption process');
      AppLogger.info('🔵 Encrypted data keys: ${encryptedData.keys.toList()}');
      AppLogger.info('🔵 Encrypted content being decrypted: ${encryptedData['encryptedContent']}');
      
      // Check for required fields
      if (encryptedData['iv'] == null) {
        throw Exception('Missing IV in encrypted data');
      }
      if (encryptedData['encryptedContent'] == null) {
        throw Exception('Missing encrypted content in encrypted data');
      }
      if (encryptedData['authTag'] == null) {
        throw Exception('Missing auth tag in encrypted data');
      }
      
      AppLogger.info('🔵 All required fields present');
      
      final keyBytes = base64Decode(key);
      final keyObj = encrypt.Key(keyBytes);
      final iv = encrypt.IV.fromBase64(encryptedData['iv'] as String);
      final encryptedBytes = base64Decode(encryptedData['encryptedContent'] as String);
      final expectedHmac = base64Decode(encryptedData['authTag'] as String);
      
      AppLogger.info('🔵 Decoded key, IV, encrypted content, and auth tag');
      
      // Verify HMAC
      final hmac = Hmac(sha256, keyBytes);
      final actualHmac = hmac.convert(encryptedBytes);
      
      AppLogger.info('🔵 HMAC Verification Details:');
      AppLogger.info('🔵 Expected HMAC (base64): ${base64Encode(expectedHmac)}');
      AppLogger.info('🔵 Actual HMAC (base64): ${base64Encode(actualHmac.bytes)}');
      AppLogger.info('🔵 Expected HMAC (hex): ${expectedHmac.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      AppLogger.info('🔵 Actual HMAC (hex): ${actualHmac.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      AppLogger.info('🔵 Key used (first 16 bytes): ${keyBytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      AppLogger.info('🔵 Encrypted content length: ${encryptedBytes.length}');
      AppLogger.info('🔵 IV (base64): ${base64Encode(iv.bytes)}');
      
      if (!listEquals(actualHmac.bytes, expectedHmac)) {
        AppLogger.error('❌ HMAC verification failed - keys do not match');
        throw Exception('Message integrity check failed');
      }
      
      AppLogger.info('🔵 HMAC verification passed');
      
      final encrypter = encrypt.Encrypter(encrypt.AES(keyObj));
      final decrypted = encrypter.decrypt64(
        encryptedData['encryptedContent'] as String,
        iv: iv
      );
      
      AppLogger.info('🔵 Message decrypted successfully');
      return decrypted;
    } catch (e) {
      AppLogger.error('Failed to decrypt message: $e');
      AppLogger.error('Encrypted data: $encryptedData');
      throw Exception('Failed to decrypt message: $e');
    }
  }

  static String generateConversationId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Test method for verification
  static bool testEncryptionDecryption() {
    try {
      final testMessage = 'Hello, this is a test message!';
      final key = generateConversationKey();
      final encrypted = encryptMessage(testMessage, key);
      final decrypted = decryptMessage(encrypted, key);
      
      final success = testMessage == decrypted;
      AppLogger.info('E2EE Test: ${success ? 'PASSED' : 'FAILED'}');
      return success;
    } catch (e) {
      AppLogger.error('E2EE Test failed: $e');
      return false;
    }
  }

  // Test method to verify deterministic key generation
  static bool testDeterministicKeyConsistency() {
    try {
      final user1Id = 'user1';
      final user2Id = 'user2';
      
      // Generate key from user1's perspective
      final key1 = generateDeterministicKey(user1Id, user2Id);
      AppLogger.info('🔵 Key from user1 perspective: ${key1.substring(0, 20)}...');
      
      // Generate key from user2's perspective
      final key2 = generateDeterministicKey(user2Id, user1Id);
      AppLogger.info('🔵 Key from user2 perspective: ${key2.substring(0, 20)}...');
      
      // Test encryption/decryption with both keys
      final testMessage = 'Test message for key consistency';
      final encrypted = encryptMessage(testMessage, key1);
      final decrypted = decryptMessage(encrypted, key2);
      
      final success = testMessage == decrypted && key1 == key2;
      AppLogger.info('🔵 Deterministic Key Test: ${success ? 'PASSED' : 'FAILED'}');
      AppLogger.info('🔵 Keys match: ${key1 == key2}');
      AppLogger.info('🔵 Decryption works: ${testMessage == decrypted}');
      
      return success;
    } catch (e) {
      AppLogger.error('🔵 Deterministic Key Test failed: $e');
      return false;
    }
  }
} 