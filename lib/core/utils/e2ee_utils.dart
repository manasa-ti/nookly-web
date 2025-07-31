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
    final hash = sha256.convert(utf8.encode(conversationId));
    final keyBytes = hash.bytes.take(32).toList();
    return base64Encode(keyBytes);
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
      
      if (!listEquals(actualHmac.bytes, expectedHmac)) {
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
} 