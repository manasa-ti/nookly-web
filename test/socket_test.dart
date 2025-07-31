import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/utils/e2ee_utils.dart';

void main() {
  group('Socket Service Tests', () {
    test('should create socket service instance', () {
      final socketService = SocketService();
      expect(socketService, isNotNull);
    });

    test('should have socket URL', () {
      final socketUrl = SocketService.socketUrl;
      expect(socketUrl, isNotEmpty);
      expect(socketUrl, contains('wss')); // WebSocket URL
    });

    test('should test E2EE utils', () {
      // Test that E2EE utils work correctly
      final testMessage = 'Hello, this is a test!';
      final key = E2EEUtils.generateConversationKey(); // Use proper key generation
      final encrypted = E2EEUtils.encryptMessage(testMessage, key);
      final decrypted = E2EEUtils.decryptMessage(encrypted, key);
      
      expect(decrypted, equals(testMessage));
    });
  });
} 