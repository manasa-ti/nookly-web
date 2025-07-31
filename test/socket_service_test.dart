import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/services/key_management_service.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Socket Service Constructor Tests', () {
    test('should create SocketService with KeyManagementService', () {
      final mockAuthRepository = MockAuthRepository();
      final keyManagementService = KeyManagementService(mockAuthRepository);
      final socketService = SocketService(keyManagementService: keyManagementService);
      
      expect(socketService, isNotNull);
      expect(keyManagementService, isNotNull);
    });

    test('should create SocketService without KeyManagementService', () {
      final socketService = SocketService();
      
      expect(socketService, isNotNull);
    });

    test('should have socket URL', () {
      final socketUrl = SocketService.socketUrl;
      expect(socketUrl, isNotEmpty);
      expect(socketUrl, contains('wss')); // WebSocket URL
    });
  });
} 