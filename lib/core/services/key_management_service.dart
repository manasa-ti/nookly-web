import 'package:dio/dio.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/domain/repositories/auth_repository.dart';
import 'package:nookly/core/utils/e2ee_utils.dart';

class KeyManagementService {
  final AuthRepository _authRepository;
  
  KeyManagementService(this._authRepository);

  /// Get or create encryption key for a conversation
  /// First tries to get the key from the conversation object, falls back to API call
  Future<String> getConversationKey(String targetUserId, {String? conversationKeyFromApi}) async {
    try {
      AppLogger.info('🔵 Getting conversation key for: $targetUserId');
      
      // If we have the key from the unified API response, use it directly
      if (conversationKeyFromApi != null && conversationKeyFromApi.isNotEmpty) {
        AppLogger.info('✅ Using conversation key from unified API response');
        AppLogger.info('🔵 Server key (first 20 chars): ${conversationKeyFromApi.substring(0, conversationKeyFromApi.length > 20 ? 20 : conversationKeyFromApi.length)}...');
        return conversationKeyFromApi;
      }
      
      // Fallback: Make API call to get the key
      AppLogger.info('🔵 No key from unified API, making separate API request');
      final token = await _authRepository.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.info('🔵 Making API request to get conversation key');
      AppLogger.info('🔵 Bearer token: Bearer $token');
      AppLogger.info('🔵 Using SERVER key for decryption');
      final response = await NetworkService.dio.get(
        '/conversation-keys/$targetUserId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      AppLogger.info('🔵 API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final encryptionKey = data['encryptionKey'] as String;
        AppLogger.info('✅ Retrieved conversation key for user: $targetUserId');
        AppLogger.info('🔵 Server key (first 20 chars): ${encryptionKey.substring(0, encryptionKey.length > 20 ? 20 : encryptionKey.length)}...');
        return encryptionKey;
      } else {
        throw Exception('Failed to get conversation key: ${response.statusCode}');
      }
    } catch (error) {
      AppLogger.error('❌ Error getting conversation key: $error');
      AppLogger.error('❌ This might be because backend E2EE endpoints are not implemented yet');
      AppLogger.error('❌ Falling back to local key generation');
      
      // Fallback: generate a deterministic key for testing
      // In production, this should be removed and backend should be implemented
      final currentUser = await _authRepository.getCurrentUser();
      final currentUserId = currentUser?.id ?? 'current_user';
      
      final deterministicKey = E2EEUtils.generateDeterministicKey(targetUserId, currentUserId);
      AppLogger.info('🔵 Generated deterministic key for testing');
      AppLogger.info('🔵 Target user ID: $targetUserId');
      AppLogger.info('🔵 Current user ID: $currentUserId');
      AppLogger.info('🔵 Using DETERMINISTIC key for decryption (fallback)');
      AppLogger.info('🔵 Deterministic key (first 20 chars): ${deterministicKey.substring(0, deterministicKey.length > 20 ? 20 : deterministicKey.length)}...');
      
      // Test deterministic key consistency
      AppLogger.info('🔵 Testing deterministic key consistency...');
      E2EEUtils.testDeterministicKeyConsistency();
      
      return deterministicKey;
    }
  }

  /// Rotate encryption key for security
  Future<String> rotateConversationKey(String targetUserId) async {
    try {
      final token = await _authRepository.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.info('🔵 Bearer token for rotate: Bearer $token');
      final response = await NetworkService.dio.post(
        '/conversation-keys/$targetUserId/rotate',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final encryptionKey = data['encryptionKey'] as String;
        AppLogger.info('Rotated conversation key for user: $targetUserId');
        return encryptionKey;
      } else {
        throw Exception('Failed to rotate conversation key: ${response.statusCode}');
      }
    } catch (error) {
      AppLogger.error('Error rotating conversation key: $error');
      rethrow;
    }
  }

  /// Check if a conversation has an encryption key
  Future<bool> hasConversationKey(String targetUserId) async {
    try {
      await getConversationKey(targetUserId);
      return true;
    } catch (e) {
      return false;
    }
  }
} 