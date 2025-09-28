import 'package:nookly/core/utils/logger.dart';

/// Service to cache conversation keys from unified API
/// This prevents redundant conversation-keys API calls
/// Keys are cached by conversation ID to prevent mismatches
class ConversationKeyCache {
  static final ConversationKeyCache _instance = ConversationKeyCache._internal();
  factory ConversationKeyCache() => _instance;
  ConversationKeyCache._internal();

  // Cache: conversationId -> encryptionKey
  final Map<String, String> _keyCache = {};
  
  // Cache: participantId -> conversationId (for backward compatibility and lookup)
  final Map<String, String> _participantToConversationMap = {};
  
  /// Store conversation key from unified API
  /// conversationId: The actual conversation ID (e.g., "user1_user2" or server-provided ID)
  /// participantId: The other user's ID (for backward compatibility)
  void storeConversationKey(String conversationId, String encryptionKey, {String? participantId}) {
    if (conversationId.isNotEmpty && encryptionKey.isNotEmpty) {
      _keyCache[conversationId] = encryptionKey;
      AppLogger.info('💾 ConversationKeyCache: Stored key for conversation $conversationId');
      AppLogger.info('💾 ConversationKeyCache: Key (first 20 chars): ${encryptionKey.substring(0, encryptionKey.length > 20 ? 20 : encryptionKey.length)}...');
      
      // Also store participant mapping for backward compatibility
      if (participantId != null && participantId.isNotEmpty) {
        _participantToConversationMap[participantId] = conversationId;
        AppLogger.info('💾 ConversationKeyCache: Mapped participant $participantId to conversation $conversationId');
      }
    }
  }

  /// Get cached conversation key by conversation ID
  String? getConversationKey(String conversationId) {
    final key = _keyCache[conversationId];
    if (key != null) {
      AppLogger.info('💾 ConversationKeyCache: Retrieved cached key for conversation $conversationId');
    } else {
      AppLogger.info('💾 ConversationKeyCache: No cached key found for conversation $conversationId');
    }
    return key;
  }

  /// Get cached conversation key by participant ID (backward compatibility)
  /// This tries multiple lookup strategies to find the right conversation
  String? getConversationKeyByParticipant(String participantId, {String? currentUserId}) {
    // Strategy 1: Direct participant mapping
    final mappedConversationId = _participantToConversationMap[participantId];
    if (mappedConversationId != null) {
      final key = _keyCache[mappedConversationId];
      if (key != null) {
        AppLogger.info('💾 ConversationKeyCache: Retrieved key via participant mapping: $participantId -> $mappedConversationId');
        return key;
      }
    }
    
    // Strategy 2: Try common conversation ID formats
    if (currentUserId != null && currentUserId.isNotEmpty) {
      // Try currentUserId_participantId format
      final inboxFormatId = '${currentUserId}_$participantId';
      final inboxKey = _keyCache[inboxFormatId];
      if (inboxKey != null) {
        AppLogger.info('💾 ConversationKeyCache: Retrieved key via inbox format: $inboxFormatId');
        return inboxKey;
      }
      
      // Try sorted format: user1_user2 (alphabetically)
      final userIds = [currentUserId, participantId];
      userIds.sort();
      final sortedFormatId = '${userIds[0]}_${userIds[1]}';
      final sortedKey = _keyCache[sortedFormatId];
      if (sortedKey != null) {
        AppLogger.info('💾 ConversationKeyCache: Retrieved key via sorted format: $sortedFormatId');
        return sortedKey;
      }
    }
    
    AppLogger.info('💾 ConversationKeyCache: No cached key found for participant $participantId');
    return null;
  }

  /// Check if key exists in cache for conversation ID
  bool hasConversationKey(String conversationId) {
    return _keyCache.containsKey(conversationId) && _keyCache[conversationId]!.isNotEmpty;
  }

  /// Check if key exists in cache for participant ID
  bool hasConversationKeyByParticipant(String participantId, {String? currentUserId}) {
    return getConversationKeyByParticipant(participantId, currentUserId: currentUserId) != null;
  }

  /// Clear all cached keys
  void clearCache() {
    AppLogger.info('💾 ConversationKeyCache: Clearing all cached keys');
    _keyCache.clear();
    _participantToConversationMap.clear();
  }

  /// Clear key for specific conversation
  void clearKeyForConversation(String conversationId) {
    if (_keyCache.containsKey(conversationId)) {
      AppLogger.info('💾 ConversationKeyCache: Clearing key for conversation $conversationId');
      _keyCache.remove(conversationId);
      
      // Also remove from participant mapping
      _participantToConversationMap.removeWhere((key, value) => value == conversationId);
    }
  }

  /// Clear key for specific participant
  void clearKeyForParticipant(String participantId) {
    final conversationId = _participantToConversationMap[participantId];
    if (conversationId != null) {
      clearKeyForConversation(conversationId);
    }
  }

  /// Clear keys for new conversation (invalidates old keys)
  void clearKeysForNewConversation(String participantId, {String? currentUserId}) {
    AppLogger.info('💾 ConversationKeyCache: Clearing keys for new conversation with participant $participantId');
    
    // Clear existing keys for this participant
    clearKeyForParticipant(participantId);
    
    // Also clear any keys that might be using different conversation ID formats
    if (currentUserId != null && currentUserId.isNotEmpty) {
      // Clear inbox format
      final inboxFormatId = '${currentUserId}_$participantId';
      clearKeyForConversation(inboxFormatId);
      
      // Clear sorted format
      final userIds = [currentUserId, participantId];
      userIds.sort();
      final sortedFormatId = '${userIds[0]}_${userIds[1]}';
      clearKeyForConversation(sortedFormatId);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalKeys': _keyCache.length,
      'cachedConversations': _keyCache.keys.toList(),
      'participantMappings': _participantToConversationMap,
    };
  }

  /// Store multiple conversation keys (from unified API response)
  void storeMultipleKeys(Map<String, String> conversationKeyMap) {
    AppLogger.info('💾 ConversationKeyCache: Storing ${conversationKeyMap.length} conversation keys');
    conversationKeyMap.forEach((conversationId, key) {
      // Extract participant ID from conversation ID if possible
      String? participantId;
      if (conversationId.contains('_')) {
        final parts = conversationId.split('_');
        if (parts.length >= 2) {
          participantId = parts.last; // Assume last part is participant ID
        }
      }
      
      storeConversationKey(conversationId, key, participantId: participantId);
    });
  }
}
