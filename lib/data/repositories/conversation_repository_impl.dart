import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:nookly/core/network/network_service.dart'; // Use NetworkService
import 'package:nookly/core/utils/logger.dart'; // Add logger import
import 'package:nookly/domain/entities/conversation.dart';
import 'package:nookly/domain/entities/conversation_key.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/domain/repositories/conversation_repository.dart';
import 'package:nookly/domain/repositories/auth_repository.dart'; // Still needed for currentUserId
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/network/socket_service.dart';
import 'package:nookly/domain/entities/user.dart';
import 'package:nookly/core/services/key_management_service.dart';
import 'package:nookly/core/services/api_cache_service.dart';
import 'package:nookly/core/services/conversation_key_cache.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/utils/e2ee_utils.dart';
import 'package:nookly/core/di/injection_container.dart' as di; 

class ConversationRepositoryImpl implements ConversationRepository {
  // Dio instance is now managed by NetworkService
  final AuthRepository _authRepository; // Still needed for currentUserId
  final KeyManagementService? _keyManagementService;

  final Map<String, StreamController<List<Message>>> _messageControllers = {};

  ConversationRepositoryImpl(this._authRepository, {KeyManagementService? keyManagementService}) 
    : _keyManagementService = keyManagementService; // Updated constructor

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      AppLogger.info('🔵 ConversationRepository: Starting getConversations API call');
      final apiStopwatch = Stopwatch()..start();
      
      final User? currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Current user not found for conversation context.');
      }
      final String currentUserId = currentUser.id;
      
      // Check cache first
      final cacheKey = 'unified_conversations_$currentUserId';
      final apiCacheService = ApiCacheService();
      final cachedConversations = apiCacheService.getCachedResponse<List<Conversation>>(cacheKey);
      if (cachedConversations != null) {
        AppLogger.info('🔵 ConversationRepository: Returning cached conversations (${cachedConversations.length} items)');
        return cachedConversations;
      }

      AppLogger.info('🔵 ConversationRepository: Making HTTP GET to /messages/conversations');
      final httpStopwatch = Stopwatch()..start();
      
      // NetworkService interceptor handles token and base URL
      final response = await NetworkService.dio.get('/messages/conversations'); // Endpoint path
      
      httpStopwatch.stop();
      AppLogger.info('🔵 ConversationRepository: HTTP response received in ${httpStopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final List<dynamic> conversationsData = responseData['conversations'] as List<dynamic>;
        final List<Conversation> conversations = [];
        
        AppLogger.info('🔵 ConversationRepository: Processing ${conversationsData.length} unified conversation items');
        final processingStopwatch = Stopwatch()..start();

        for (var item in conversationsData) {
          final itemMap = item as Map<String, dynamic>;
          final userJson = itemMap['user'] as Map<String, dynamic>; 
          final lastMessageJson = itemMap['lastMessage'] as Map<String, dynamic>?;

          // Parse conversation key if available (needed for message decryption)
          ConversationKey? conversationKey;
          if (itemMap['conversationKey'] != null) {
            try {
              conversationKey = ConversationKey.fromJson(itemMap['conversationKey'] as Map<String, dynamic>);
              AppLogger.info('🔵 ConversationRepository: Parsed conversation key for conversation: ${userJson['_id']}');
              
              // Store conversation key in cache to prevent redundant API calls
              if (conversationKey.encryptionKey.isNotEmpty) {
                final participantId = userJson['_id'] as String;
                
                // Store with sorted conversation ID format (standardized: sorted userIds)
                final userIds = [currentUserId, participantId];
                userIds.sort();
                final conversationId = '${userIds[0]}_${userIds[1]}';
                ConversationKeyCache().storeConversationKey(
                  conversationId, 
                  conversationKey.encryptionKey,
                  participantId: participantId
                );
                AppLogger.info('💾 ConversationRepository: Stored conversation key in cache for conversation: $conversationId');
              }
            } catch (e) {
              AppLogger.error('❌ ConversationRepository: Error parsing conversation key: $e');
            }
          }

          Message? lastMessage;
          DateTime lastMessageTime;

          if (lastMessageJson != null) {
            // Ensure required fields are present in the message data
            final messageData = Map<String, dynamic>.from(lastMessageJson);
            AppLogger.info('🔵 ConversationRepository: Raw lastMessage from API: $lastMessageJson');
            AppLogger.info('🔵 ConversationRepository: Raw lastMessage sender field: ${messageData['sender']}');
            AppLogger.info('🔵 ConversationRepository: Raw lastMessage from field: ${messageData['from']}');
            AppLogger.info('🔵 ConversationRepository: Raw lastMessage isRead field: ${messageData['isRead']}');
            AppLogger.info('🔵 ConversationRepository: Raw lastMessage status field: ${messageData['status']}');
            
            if (!messageData.containsKey('sender')) {
              messageData['sender'] = userJson['_id'] as String; // Use conversation user as sender
              AppLogger.info('🔵 ConversationRepository: No sender field, using participantId: ${userJson['_id']}');
            }
            if (!messageData.containsKey('receiver')) {
              messageData['receiver'] = currentUserId; // Use current user as receiver
            }
            // Convert messageType to type enum
            if (messageData.containsKey('messageType')) {
              messageData['type'] = messageData['messageType'] == 'image' ? 'image' : 'text';
            }
            AppLogger.info('🔵 ConversationRepository: Message data before parsing: $messageData');
            lastMessage = Message.fromJson(messageData);
            AppLogger.info('🔵 ConversationRepository: Parsed message sender: ${lastMessage.sender}');
            
            // Decrypt message if it's encrypted
            if (lastMessage.isEncrypted && lastMessage.encryptionMetadata != null) {
              AppLogger.info('🔵 Decrypting last message in conversation list');
              AppLogger.info('🔵 Message content before decryption: ${lastMessage.content}');
              AppLogger.info('🔵 Encrypted content to decrypt: ${lastMessage.encryptedContent}');
              // Get conversation key from the conversation object if available
              final encryptionKeyFromConversation = conversationKey?.encryptionKey;
              lastMessage = await _decryptMessageIfNeeded(lastMessage, userJson['_id'] as String, conversationKey: encryptionKeyFromConversation);
              AppLogger.info('🔵 Message content after decryption: ${lastMessage.content}');
            }
            
            // Handle disappearing images logic (inbox preview)
            // Rules:
            // 1) Consider the image "viewed" only if we have a definitive signal:
            //    - metadata.readAt (preferred)
            //    - metadata.viewedAt (if backend adds it in future)
            // 2) Do NOT derive viewed state from S3 URL expiresAt; it is not a user-view signal
            // 3) If we cannot determine viewed state, keep the message and display as "📷 Photo"
            if (lastMessage.metadata?.isDisappearing == true && lastMessage.type == MessageType.image) {
              final readAtStr = lastMessage.metadata?.readAt;
              // Placeholder for future support; keep null-safe for now
              final String? viewedAtStr = null; 
              final disappearingTime = lastMessage.metadata?.disappearingTime ?? 5;

              final hasDefinitiveViewedSignal = (readAtStr != null) || (viewedAtStr != null);

              if (hasDefinitiveViewedSignal) {
                try {
                  final viewedAt = DateTime.parse(readAtStr ?? viewedAtStr!);
                  final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
                  if (elapsedSeconds >= disappearingTime) {
                    AppLogger.info('Disappearing image expired after being viewed; keeping inbox preview but consider expired in detail view');
                    // Keep lastMessage for inbox preview. Do not null it to avoid "No messages yet".
                  }
                } catch (e) {
                  AppLogger.warning('Failed to parse viewedAt/readAt for disappearing image: $e');
                }
              } else {
                AppLogger.info('Disappearing image without viewed signal; showing placeholder in inbox');
              }
            }
            
            lastMessageTime = lastMessage?.timestamp ?? DateTime.now();
          } else {
            lastMessageTime = DateTime.now();
          }
          
          final participantIdFromJson = userJson['_id'] as String;

          // Adjust unread count based on last message status
          int unreadCount = itemMap['unreadCount'] as int? ?? 0;
          if (lastMessage != null) {
            AppLogger.info('🔵 ConversationRepository: Last message sender: ${lastMessage.sender}, Current user: $currentUserId');
            AppLogger.info('🔵 ConversationRepository: Last message isRead: ${lastMessage.metadata?.isRead}');
            
            // If last message is from current user, unread count should be 0
            if (lastMessage.sender == currentUserId) {
              unreadCount = 0;
              AppLogger.info('🔵 ConversationRepository: Last message is from current user, setting unread count to 0');
            }
            // If last message is marked as read, it means all messages are read
            else if (lastMessage.metadata?.isRead == true) {
              unreadCount = 0;
              AppLogger.info('🔵 ConversationRepository: Last message is marked as read, setting unread count to 0');
            }
          }
          
          AppLogger.info('🔵 ConversationRepository: Final unread count for ${userJson['name']}: $unreadCount (API reported: ${itemMap['unreadCount']})');

          final conversation = Conversation(
            id: participantIdFromJson, 
            participantId: participantIdFromJson, 
            participantName: userJson['name'] as String? ?? 'Unknown',
            participantAvatar: userJson['profile_pic'] as String?,
            messages: lastMessage != null ? [lastMessage] : [],
            lastMessageTime: lastMessageTime,
            isOnline: userJson['isOnline'] as bool? ?? false, 
            unreadCount: unreadCount,
            userId: currentUserId,
            lastMessage: lastMessage, // Add the lastMessage field
            updatedAt: lastMessageTime,
            conversationKey: conversationKey,
            lastSeen: userJson['lastSeen'] as String?,
            connectionStatus: userJson['connectionStatus'] as String?,
          );
          
          AppLogger.info('🔵 ConversationRepository: Created conversation for ${conversation.participantName}');
          AppLogger.info('🔵 ConversationRepository: Last message content: ${conversation.lastMessage?.content}');
          AppLogger.info('🔵 ConversationRepository: Unread count: ${conversation.unreadCount}');
          
          conversations.add(conversation);
        }
        
        processingStopwatch.stop();
        apiStopwatch.stop();
        AppLogger.info('🔵 ConversationRepository: Processing completed in ${processingStopwatch.elapsedMilliseconds}ms');
        AppLogger.info('🔵 ConversationRepository: getConversations unified API completed in ${apiStopwatch.elapsedMilliseconds}ms, found ${conversations.length} conversations');
        
        // Log statistics if available
        if (responseData.containsKey('statistics')) {
          final stats = responseData['statistics'] as Map<String, dynamic>;
          AppLogger.info('🔵 ConversationRepository: Statistics - Total conversations: ${stats['totalConversations']}, New matches: ${stats['totalNewMatches']}, Total unread: ${stats['totalUnread']}');
        }
        
        // Cache the result
        apiCacheService.cacheResponse(cacheKey, conversations, duration: const Duration(minutes: 3));
        
        return conversations;
      }
      
      throw Exception('Failed to load conversations: Status ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.info('DioError fetching conversations: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load conversations: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('Error fetching conversations: $e');
      throw Exception('Failed to load conversations: An unexpected error occurred: $e');
    }
  }

  @override
  Future<Conversation> getConversation(
    String participantId,
    // Receive participant details from the caller
    String participantName,
    String? participantAvatar,
    bool isOnline,
  ) async {
    try {
      final User? currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Current user not found to fetch conversation details.');
      }
      final String currentUserId = currentUser.id;

      final response = await NetworkService.dio.get('/messages/chat/$participantId');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> messagesJson = response.data as List<dynamic>;
        final List<Message> messages = messagesJson
            .map((json) {
              AppLogger.info('🔵 Processing message from API:');
              AppLogger.info('🔵 - Message ID: ${json['_id']}');
              AppLogger.info('🔵 - Content: ${json['content']}');
              AppLogger.info('🔵 - Type: ${json['type']}');
              AppLogger.info('🔵 - IsDisappearing: ${json['isDisappearing']}');
              AppLogger.info('🔵 - DisappearingTime: ${json['disappearingTime']}');
              AppLogger.info('🔵 - Full JSON: $json');
              
              return Message.fromJson(json);
            })
            .toList();

        // Filter out expired disappearing images
        final filteredMessages = messages.where((message) {
          if (message.metadata?.isDisappearing == true && message.type == MessageType.image) {
            final isViewed = message.metadata?.image?.expiresAt != null;
            final disappearingTime = message.metadata?.disappearingTime ?? 5;
            
            AppLogger.info('🔍 REPO FILTERING DEBUG: Message ${message.id}');
            AppLogger.info('🔍 REPO FILTERING DEBUG: - isDisappearing: ${message.metadata?.isDisappearing}');
            AppLogger.info('🔍 REPO FILTERING DEBUG: - type: ${message.type}');
            AppLogger.info('🔍 REPO FILTERING DEBUG: - isViewed: $isViewed');
            AppLogger.info('🔍 REPO FILTERING DEBUG: - disappearingTime: $disappearingTime');
            AppLogger.info('🔍 REPO FILTERING DEBUG: - metadata: ${message.metadata}');
            
            if (isViewed) {
              // Check if the image has expired since being viewed
              final viewedAt = DateTime.parse(message.metadata!.image!.expiresAt);
              final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
              
              AppLogger.info('🔍 REPO FILTERING DEBUG: - viewedAt: $viewedAt');
              AppLogger.info('🔍 REPO FILTERING DEBUG: - elapsedSeconds: $elapsedSeconds');
              AppLogger.info('🔍 REPO FILTERING DEBUG: - shouldExpire: ${elapsedSeconds >= disappearingTime}');
              
              if (elapsedSeconds >= disappearingTime) {
                AppLogger.info('🔍 REPO FILTERING DEBUG: Filtering out expired disappearing image: ${message.id}');
                return false; // Filter out expired disappearing images
              } else {
                AppLogger.info('🔍 REPO FILTERING DEBUG: Keeping valid disappearing image: ${message.id}');
              }
            } else {
              AppLogger.info('🔍 REPO FILTERING DEBUG: Keeping unviewed disappearing image: ${message.id}');
            }
            // Keep unviewed disappearing images and valid viewed ones
          }
          return true; // Keep all other messages
        }).toList();

        filteredMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        DateTime lastMessageTime = DateTime.now();
        if (filteredMessages.isNotEmpty) {
          lastMessageTime = filteredMessages.last.timestamp;
        }

        return Conversation(
          id: participantId, 
          participantId: participantId, 
          // Use passed-in details
          participantName: participantName, 
          participantAvatar: participantAvatar,
          messages: filteredMessages,
          lastMessageTime: lastMessageTime,
          isOnline: isOnline, 
          unreadCount: 0, // API doesn't provide this for chat history endpoint
          userId: currentUserId,
          updatedAt: lastMessageTime,
        );
      } else {
        throw Exception('Failed to load chat history: Status ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.info('DioError fetching chat history for $participantId: ${e.response?.data ?? e.message}');
      throw Exception('Failed to load chat history: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('Error fetching chat history for $participantId: $e');
      throw Exception('Failed to load chat history: An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> sendTextMessage(String conversationId, String content) async {
    // conversationId here is the participantId (receiverId for the message)
    try {
      await NetworkService.dio.post(
        '/messages',
        data: {
          'receiver': conversationId, 
          'content': content,
          'messageType': 'text',
        },
      );
    } on DioException catch (e) {
      AppLogger.info('DioError sending message: ${e.response?.data ?? e.message}');
      throw Exception('Failed to send message: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('Error sending message: $e');
      throw Exception('Failed to send message: An unexpected error occurred.');
    }
  }

  @override
  Future<void> sendVoiceMessage(String conversationId, String audioPath, Duration duration) async {
    try {
      final uploadForm = FormData.fromMap({
        'voice': await MultipartFile.fromFile(
          audioPath,
          filename: audioPath.split('/').last,
          contentType: MediaType.parse('audio/m4a'),
        ),
      });
      final uploadResponse = await NetworkService.dio.post(
        '/messages/upload-voice',
        data: uploadForm,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (uploadResponse.statusCode == 200) {
        final voiceData = uploadResponse.data;
        final voiceUrl = voiceData['voiceUrl'] as String;
        final voiceKey = voiceData['key'] as String;
        final voiceSize = (voiceData['size'] as num?)?.toInt() ?? 0;
        final voiceType = voiceData['type'] as String;
        // Backend may not return duration; use local recording duration
        final voiceDuration = duration.inSeconds;
        final expiresAt = voiceData['expiresAt'] as String;

        final messageResponse = await NetworkService.dio.post(
          '/messages',
          data: {
            'receiver': conversationId,
            'messageType': 'voice',
            'voiceKey': voiceKey,
            'voiceSize': voiceSize,
            'voiceType': voiceType,
            'voiceDuration': voiceDuration,
          },
        );

        if (messageResponse.statusCode == 200 || messageResponse.statusCode == 201) {
          AppLogger.info('✅ Voice message sent successfully');
          // Also emit private_message over socket so receiver updates in real-time
          try {
            final socket = sl<SocketService>();
            socket.sendMessage({
              'to': conversationId,
              'content': '[VOICE]',
              'messageType': 'voice',
              'status': 'sent',
              'metadata': {
                'voice': {
                  'voiceUrl': voiceUrl,
                  'voiceKey': voiceKey,
                  'voiceSize': voiceSize,
                  'voiceType': voiceType,
                  'voiceDuration': voiceDuration,
                  'expiresAt': expiresAt,
                }
              }
            });
          } catch (e) {
            AppLogger.error('❌ Failed to emit private_message for voice: $e');
          }
          return;
        }
        throw Exception('Failed to send voice message: ${messageResponse.data}');
      }
      throw Exception('Failed to upload voice file: ${uploadResponse.data}');
    } catch (e) {
      AppLogger.error('❌ Error sending voice message: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendFileMessage(String conversationId, String filePath, String fileName, int fileSize) async {
    throw UnimplementedError('sendFileMessage not implemented with API yet.');
  }

  @override
  Future<void> sendGifMessage(String conversationId, Map<String, dynamic> gifMetadata) async {
    try {
      final response = await NetworkService.dio.post(
        '/messages',
        data: {
          'receiver': conversationId,
          'content': gifMetadata['giphyUrl'] as String,
          'messageType': 'gif',
          'giphyId': gifMetadata['giphyId'] as String,
          'metadata': {
            'isDisappearing': false,
            'isRead': false,
            'isViewOnce': false,
            'gif': {
              'giphyId': gifMetadata['giphyId'] as String,
              'giphyUrl': gifMetadata['giphyUrl'] as String,
              'giphyPreviewUrl': gifMetadata['giphyPreviewUrl'] as String? ?? gifMetadata['giphyUrl'] as String,
              'title': gifMetadata['title'] as String? ?? '',
              'width': gifMetadata['width'] as int? ?? 0,
              'height': gifMetadata['height'] as int? ?? 0,
              'size': gifMetadata['size'] as int? ?? 0,
              'webpUrl': gifMetadata['webpUrl'] as String?,
              'mp4Url': gifMetadata['mp4Url'] as String?,
            },
          },
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('✅ GIF message sent successfully');
        
        // Also emit private_message over socket so receiver updates in real-time
        try {
          final socket = sl<SocketService>();
          socket.sendMessage({
            'to': conversationId,
            'content': gifMetadata['giphyUrl'] as String,
            'messageType': 'gif',
            'status': 'sent',
            'giphyId': gifMetadata['giphyId'] as String,
            'metadata': {
              'isDisappearing': false,
              'isRead': false,
              'isViewOnce': false,
              'gif': {
                'giphyId': gifMetadata['giphyId'] as String,
                'giphyUrl': gifMetadata['giphyUrl'] as String,
                'giphyPreviewUrl': gifMetadata['giphyPreviewUrl'] as String? ?? gifMetadata['giphyUrl'] as String,
                'title': gifMetadata['title'] as String? ?? '',
                'width': gifMetadata['width'] as int? ?? 0,
                'height': gifMetadata['height'] as int? ?? 0,
                'size': gifMetadata['size'] as int? ?? 0,
                'webpUrl': gifMetadata['webpUrl'] as String?,
                'mp4Url': gifMetadata['mp4Url'] as String?,
              },
            }
          });
          AppLogger.info('✅ GIF private_message emitted successfully');
        } catch (e) {
          AppLogger.error('❌ Failed to emit private_message for GIF: $e');
        }
      } else {
        throw Exception('Failed to send GIF message: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending GIF message: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendStickerMessage(String conversationId, Map<String, dynamic> stickerMetadata) async {
    try {
      final response = await NetworkService.dio.post(
        '/messages',
        data: {
          'receiver': conversationId,
          'content': stickerMetadata['stickerUrl'] as String,
          'messageType': 'sticker',
          'giphyId': stickerMetadata['giphyId'] as String,
          'metadata': {
            'isDisappearing': false,
            'isRead': false,
            'isViewOnce': false,
            'sticker': {
              'giphyId': stickerMetadata['giphyId'] as String,
              'stickerUrl': stickerMetadata['stickerUrl'] as String,
              'title': stickerMetadata['title'] as String? ?? '',
              'width': stickerMetadata['width'] as int? ?? 0,
              'height': stickerMetadata['height'] as int? ?? 0,
              'size': stickerMetadata['size'] as int? ?? 0,
              'webpUrl': stickerMetadata['webpUrl'] as String?,
            },
          },
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('✅ Sticker message sent successfully');
        
        // Also emit private_message over socket so receiver updates in real-time
        try {
          final socket = sl<SocketService>();
          socket.sendMessage({
            'to': conversationId,
            'content': stickerMetadata['stickerUrl'] as String,
            'messageType': 'sticker',
            'status': 'sent',
            'giphyId': stickerMetadata['giphyId'] as String,
            'metadata': {
              'isDisappearing': false,
              'isRead': false,
              'isViewOnce': false,
              'sticker': {
                'giphyId': stickerMetadata['giphyId'] as String,
                'stickerUrl': stickerMetadata['stickerUrl'] as String,
                'title': stickerMetadata['title'] as String? ?? '',
                'width': stickerMetadata['width'] as int? ?? 0,
                'height': stickerMetadata['height'] as int? ?? 0,
                'size': stickerMetadata['size'] as int? ?? 0,
                'webpUrl': stickerMetadata['webpUrl'] as String?,
              },
            }
          });
          AppLogger.info('✅ Sticker private_message emitted successfully');
        } catch (e) {
          AppLogger.error('❌ Failed to emit private_message for sticker: $e');
        }
      } else {
        throw Exception('Failed to send sticker message: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending sticker message: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendImageMessage(String conversationId, String imagePath) async {
    try {
      AppLogger.info('debug disappearing: Starting image upload process');
      AppLogger.info('debug disappearing: Base URL from NetworkService: ${NetworkService.baseUrl}');
      
      // Create form data for the image upload
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'receiver': conversationId,
        'messageType': 'image',
        'isDisappearing': true,
        'disappearingTime': 5, // Default to 5 seconds
      });

      // Log the full URL that will be used
      final fullUrl = '${NetworkService.baseUrl}messages/upload-image';
      AppLogger.info('debug disappearing: Full URL for upload: $fullUrl');
      AppLogger.info('debug disappearing: Form data fields: ${formData.fields}');

      // Upload the image - use the full URL
      final response = await NetworkService.dio.post(
        'messages/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => true, // Accept all status codes for debugging
        ),
      );

      AppLogger.info('debug disappearing: Response status: ${response.statusCode}');
      AppLogger.info('debug disappearing: Response data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }

      // Log the complete response structure to understand what fields are available
      AppLogger.info('debug disappearing: Upload response data structure:');
      AppLogger.info('debug disappearing: - Response data type: ${response.data.runtimeType}');
      AppLogger.info('debug disappearing: - Response data keys: ${response.data.keys.toList()}');
      AppLogger.info('debug disappearing: - Full response data: ${response.data}');

      // The response should contain the image URL and message data
      final imageUrl = response.data['imageUrl'];
      final imageKey = response.data['imageKey'] ?? response.data['key'] ?? response.data['s3Key'];
      final imageSize = response.data['imageSize'] ?? response.data['size'] ?? response.data['fileSize'];
      final imageType = response.data['imageType'] ?? response.data['type'] ?? response.data['mimeType'] ?? response.data['contentType'];
      
      if (imageUrl == null) {
        throw Exception('No image URL in response');
      }

      AppLogger.info('debug disappearing: Extracted values:');
      AppLogger.info('debug disappearing: - imageUrl: $imageUrl');
      AppLogger.info('debug disappearing: - imageKey: $imageKey');
      AppLogger.info('debug disappearing: - imageSize: $imageSize');
      AppLogger.info('debug disappearing: - imageType: $imageType');

      // Provide fallback values if not provided by upload response
      final finalImageKey = imageKey ?? _extractImageKeyFromUrl(imageUrl);
      final finalImageSize = imageSize ?? await _getFileSize(imagePath);
      final finalImageType = imageType ?? _getMimeTypeFromExtension(imagePath);

      AppLogger.info('debug disappearing: Final values for POST /messages:');
      AppLogger.info('debug disappearing: - imageUrl: $imageUrl');
      AppLogger.info('debug disappearing: - imageKey: $finalImageKey');
      AppLogger.info('debug disappearing: - imageSize: $finalImageSize');
      AppLogger.info('debug disappearing: - imageType: $finalImageType');

      // Send the message with the image URL and metadata
      final messageUrl = '${NetworkService.baseUrl}messages';
      AppLogger.info('debug disappearing: Full URL for message: $messageUrl');
      
      final messageResponse = await NetworkService.dio.post(
        'messages',
        data: {
          'receiver': conversationId, // API expects 'receiver' field
          'content': '', // Can be empty for image messages
          'messageType': 'image',
          'imageUrl': imageUrl,
          'imageKey': finalImageKey,
          'imageSize': finalImageSize,
          'imageType': finalImageType,
          'isDisappearing': true,
          'disappearingTime': 5, // Default to 5 seconds
        },
        options: Options(
          validateStatus: (status) => true, // Accept all status codes for debugging
        ),
      );
      
      AppLogger.info('debug disappearing: Message creation response status: ${messageResponse.statusCode}');
      AppLogger.info('debug disappearing: Message creation response data: ${messageResponse.data}');
      
      if (messageResponse.statusCode != 200 && messageResponse.statusCode != 201) {
        AppLogger.info('debug disappearing: Failed to create message record: ${messageResponse.statusCode}');
        AppLogger.info('debug disappearing: Error response data: ${messageResponse.data}');
        AppLogger.info('debug disappearing: Request payload was: ${messageResponse.requestOptions.data}');
        throw Exception('Failed to create message record: ${messageResponse.statusMessage}');
      }
      
      AppLogger.info('debug disappearing: Message sent successfully');
    } on DioException catch (e) {
      AppLogger.info('debug disappearing: DioException details:');
      AppLogger.info('debug disappearing: - Type: ${e.type}');
      AppLogger.info('debug disappearing: - Message: ${e.message}');
      AppLogger.info('debug disappearing: - Response: ${e.response?.data}');
      AppLogger.info('debug disappearing: - Request: ${e.requestOptions.uri}');
      throw Exception('Failed to send image message: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      AppLogger.info('debug disappearing: General error: $e');
      throw Exception('Failed to send image message: An unexpected error occurred.');
    }
  }

  // Helper method to extract image key from URL
  String _extractImageKeyFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.path.split('/');
      // Extract the last two segments (messages/filename) as the image key
      if (pathSegments.length >= 2) {
        return pathSegments.sublist(pathSegments.length - 2).join('/');
      }
      return pathSegments.last;
    } catch (e) {
      AppLogger.info('debug disappearing: Failed to extract image key from URL: $e');
      return 'unknown';
    }
  }

  // Helper method to get file size
  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      AppLogger.info('debug disappearing: Failed to get file size: $e');
      return 0;
    }
  }

  // Helper method to get MIME type from file extension
  String _getMimeTypeFromExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    throw UnimplementedError('markMessageAsRead not implemented with API yet.');
  }

  @override
  Future<void> blockUser(String userId) async {
    try {
      AppLogger.info('🔵 Blocking user: $userId');
      
      final response = await NetworkService.dio.post(
        '/users/block/$userId',
      );

      AppLogger.info('🔵 Block response: ${response.statusCode}');
      AppLogger.info('🔵 Block response data: ${response.data}');

      if (response.statusCode == 200) {
        AppLogger.info('✅ Successfully blocked user: $userId');
        
        // Track user blocked
        try {
          final currentUser = await _authRepository.getCurrentUser();
          if (currentUser != null) {
            final analyticsService = di.sl<AnalyticsService>();
            analyticsService.logUserBlocked(
              blockedId: userId,
              blockerId: currentUser.id,
            );
          }
        } catch (e) {
          // Analytics failure shouldn't block the operation
          AppLogger.warning('Failed to track user blocked analytics: $e');
        }
      } else {
        throw Exception('Failed to block user: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Error blocking user: $e');
      if (e is DioException) {
        throw Exception('Failed to block user: ${e.response?.data?['message'] ?? e.message}');
      }
      throw Exception('Failed to block user: $e');
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    throw UnimplementedError('unblockUser not implemented with API yet.');
  }

  @override
  Future<void> muteConversation(String conversationId) async {
    throw UnimplementedError('muteConversation not implemented with API yet.');
  }

  @override
  Future<void> unmuteConversation(String conversationId) async {
    throw UnimplementedError('unmuteConversation not implemented with API yet.');
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    try {
      AppLogger.info('🔵 Leaving conversation (unmatching): $conversationId');
      
      final response = await NetworkService.dio.delete(
        '/users/unmatch/$conversationId',
      );

      AppLogger.info('🔵 Unmatch response: ${response.statusCode}');
      AppLogger.info('🔵 Unmatch response data: ${response.data}');

      if (response.statusCode == 200) {
        AppLogger.info('✅ Successfully unmatched with user: $conversationId');
      } else {
        throw Exception('Failed to unmatch: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Error leaving conversation (unmatching): $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw Exception('Profile not found or no match exists with this user');
        } else if (e.response?.statusCode == 500) {
          throw Exception('Server error during unmatch process');
        } else {
          throw Exception('Failed to unmatch: ${e.response?.data?['message'] ?? e.message}');
        }
      }
      throw Exception('Failed to unmatch: $e');
    }
  }

  // 
  // @override
  // Future<void> startAudioCall(String conversationId) async {
  //   throw UnimplementedError('startAudioCall not implemented with API yet.');
  // }

  // @override
  // Future<void> startVideoCall(String conversationId) async {
  //   throw UnimplementedError('startVideoCall not implemented with API yet.');
  // }

  // @override
  // Future<void> endCall(String conversationId) async {
  //   throw UnimplementedError('endCall not implemented with API yet.');
  // }

  @override
  Stream<List<Message>> listenToMessages(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId] = StreamController<List<Message>>.broadcast();
      AppLogger.info('listenToMessages for $conversationId is using a mock stream controller.');
    }
    return _messageControllers[conversationId]!.stream;
  }

  @override
  Future<Map<String, dynamic>> getMessages({
    required String participantId,
    int? page,
    String? cursor,
    required int pageSize,
  }) async {
    try {
      // Build query parameters - cursor-based pagination only
      final queryParameters = <String, dynamic>{
        'pageSize': pageSize,
      };
      
      // Always include cursor parameter (empty string for first page, actual cursor for subsequent)
      // API requires cursor parameter to trigger cursor-based pagination
      queryParameters['cursor'] = cursor ?? ''; // Empty string if null
      AppLogger.info('🔵 Using cursor-based pagination: cursor="${cursor ?? ''}"');
      
      final response = await NetworkService.dio.get(
        '/messages/chat/$participantId',
        queryParameters: queryParameters,
      );

      AppLogger.info('API Response data: ${response.data}');
      AppLogger.info('🔵 DEBUGGING API RESPONSE: Full API response structure');
      AppLogger.info('🔵 DEBUGGING API RESPONSE: - Response type: ${response.data.runtimeType}');
      AppLogger.info('🔵 DEBUGGING API RESPONSE: - Response keys: ${response.data.keys.toList()}');
      
      final data = response.data as Map<String, dynamic>;
      AppLogger.info('Messages data: ${data['messages']}');
      
      // Debug individual messages in the response
      if (data['messages'] is List) {
        final messagesList = data['messages'] as List;
        AppLogger.info('🔵 DEBUGGING API RESPONSE: Found ${messagesList.length} messages in response');
        for (int i = 0; i < messagesList.length; i++) {
          final msg = messagesList[i];
          AppLogger.info('🔵 DEBUGGING API RESPONSE: Message $i: $msg');
          if (msg is Map<String, dynamic>) {
            AppLogger.info('🔵 DEBUGGING API RESPONSE: - Message $i keys: ${msg.keys.toList()}');
            AppLogger.info('🔵 DEBUGGING API RESPONSE: - Message $i isDisappearing: ${msg['isDisappearing']}');
            AppLogger.info('🔵 DEBUGGING API RESPONSE: - Message $i disappearingTime: ${msg['disappearingTime']}');
          }
        }
      }
      
      // Get current user ID once
      final currentUser = await _authRepository.getCurrentUser();
      final currentUserId = currentUser?.id;
      
      final messages = await Future.wait((data['messages'] as List)
          .map((msg) async {
            AppLogger.info('Processing message: $msg');
            if (msg is! Map<String, dynamic>) {
              AppLogger.info('Warning: Message is not a Map: $msg');
              msg = {'id': DateTime.now().millisecondsSinceEpoch.toString(), 'content': msg.toString()};
            }
            
            // Ensure required fields are present
            final messageData = Map<String, dynamic>.from(msg);
            if (!messageData.containsKey('sender')) {
              messageData['sender'] = participantId; // Use participantId as sender if missing
            }
            if (!messageData.containsKey('receiver')) {
              messageData['receiver'] = currentUserId; // Use current user as receiver if missing
            }
            
            // Add debugging for disappearing fields
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: Processing message from getMessages method');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Message ID: ${messageData['_id']}');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Raw isDisappearing: ${messageData['isDisappearing']}');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Raw disappearingTime: ${messageData['disappearingTime']}');
            AppLogger.info('🔵 DEBUGGING GETMESSAGES: - Full messageData: $messageData');
            
            final message = Message.fromJson(messageData);
            
            // Decrypt message if it's encrypted
            return await _decryptMessageIfNeeded(message, participantId);
          }));

      return {
        'messages': messages,
        'pagination': data['pagination'],
      };
    } catch (e) {
      AppLogger.info('Error getting messages: $e');
      rethrow;
    }
  }

  void dispose() {
    for (var controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
  }

  /// Decrypt a message if it's encrypted
  Future<Message> _decryptMessageIfNeeded(Message message, String senderId, {String? conversationKey}) async {
    if (!message.isEncrypted || message.encryptionMetadata == null) {
      // Not encrypted, ensure encryption fields are cleared
      return message.copyWith(
        isEncrypted: false,
        encryptedContent: null,
        encryptionMetadata: null,
      );
    }

    if (_keyManagementService == null) {
      AppLogger.error('Key management service not available for decryption');
      return message.copyWith(
        content: '[DECRYPTION FAILED - NO KEY SERVICE]',
        isEncrypted: false,
        encryptedContent: null,
        encryptionMetadata: null,
        decryptionError: true,
      );
    }

    try {
      // Get conversation key (use provided key if available, otherwise fetch from API)
      final encryptionKey = await _keyManagementService!.getConversationKey(senderId, conversationKeyFromApi: conversationKey);
      
      // Create the proper encrypted data structure
      final encryptedData = {
        'iv': message.encryptionMetadata!['iv'],
        'encryptedContent': message.encryptedContent,
        'authTag': message.encryptionMetadata!['authTag'],
      };
      AppLogger.info('🔵 Decrypting message from repository: $encryptedData');
      
      // Try to decrypt with server key first, then fallback to deterministic key
      String decryptedContent;
      try {
        decryptedContent = E2EEUtils.decryptMessage(
          encryptedData,
          encryptionKey
        );
        AppLogger.info('✅ Message decrypted successfully with SERVER key');
      } catch (e) {
        AppLogger.warning('⚠️ Failed to decrypt with server key, trying deterministic key: $e');
        
        // Fallback: try with deterministic key for backward compatibility
        final currentUser = await _authRepository.getCurrentUser();
        final currentUserId = currentUser?.id ?? 'current_user';
        final deterministicKey = E2EEUtils.generateDeterministicKey(senderId, currentUserId);
        
        AppLogger.info('🔵 [REPOSITORY] Trying deterministic key: ${deterministicKey.substring(0, 10)}...');
        decryptedContent = E2EEUtils.decryptMessage(
          encryptedData,
          deterministicKey
        );
        AppLogger.info('✅ Message decrypted successfully with DETERMINISTIC key (backward compatibility)');
      }
      
      return message.copyWith(
        content: decryptedContent,
        isEncrypted: false,
        encryptedContent: null,
        encryptionMetadata: null,
        decryptionError: false,
      );
    } catch (error) {
      AppLogger.error('Error decrypting message: $error');
      return message.copyWith(
        content: '[DECRYPTION FAILED]',
        isEncrypted: false,
        encryptedContent: null,
        encryptionMetadata: null,
        decryptionError: true,
      );
    }
  }
} 