import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/core/services/key_management_service.dart';

void main() {
  group('Dependency Injection Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await init(); // Initialize dependency injection
    });

    test('should create SocketService with KeyManagementService', () {
      final socketService = sl<SocketService>();
      expect(socketService, isNotNull);
      
      // Test that the socket service can access key management service
      // This will throw an error if the dependency is not properly injected
      expect(() => socketService.isConnected, returnsNormally);
    });

    test('should create KeyManagementService', () {
      final keyManagementService = sl<KeyManagementService>();
      expect(keyManagementService, isNotNull);
    });

    test('should create both services independently', () {
      final socketService1 = sl<SocketService>();
      final socketService2 = sl<SocketService>();
      final keyManagementService = sl<KeyManagementService>();
      
      expect(socketService1, isNotNull);
      expect(socketService2, isNotNull);
      expect(keyManagementService, isNotNull);
      
      // Should be the same instance (singleton)
      expect(identical(socketService1, socketService2), isTrue);
    });
  });
} 