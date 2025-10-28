import 'package:equatable/equatable.dart';
import 'package:nookly/core/utils/logger.dart';

enum MessageType {
  text,
  image,
  voice,
  file,
  // Add other types if your API supports them directly by string name
}

class Message extends Equatable {
  final String id;
  final String sender;
  final String receiver;
  final String content;
  final DateTime timestamp; // Corresponds to API's createdAt
  final MessageType type;
  final bool isRead;
  final Map<String, String>? metadata;
  final String status; // sent, delivered, read
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isDisappearing; // Whether the message should disappear
  final int? disappearingTime; // Time in seconds before message disappears
  final bool isExpired;
  final DateTime? urlExpirationTime; // Add this field
  
  // AI suggestion fields
  final bool isAISuggested;
  final String? aiSuggestionId;
  
  // E2EE fields
  final bool isEncrypted;
  final String? encryptedContent;
  final Map<String, dynamic>? encryptionMetadata;
  final bool decryptionError;

  const Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.metadata,
    this.status = 'sent',
    this.deliveredAt,
    this.readAt,
    this.isDisappearing = false,
    this.disappearingTime,
    this.isExpired = false,
    this.urlExpirationTime, // Add this parameter
    this.isAISuggested = false,
    this.aiSuggestionId,
    this.isEncrypted = false,
    this.encryptedContent,
    this.encryptionMetadata,
    this.decryptionError = false,
  });

  @override
  List<Object?> get props => [
        id,
        sender,
        receiver,
        content,
        timestamp,
        type,
        isRead,
        metadata,
        status,
        deliveredAt,
        readAt,
        isDisappearing,
        disappearingTime,
        isExpired,
        urlExpirationTime, // Add to props
        isAISuggested,
        aiSuggestionId,
        isEncrypted,
        encryptedContent,
        encryptionMetadata,
        decryptionError,
      ];

  Message copyWith({
    String? id,
    String? sender,
    String? receiver,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
    Map<String, String>? metadata,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isDisappearing,
    int? disappearingTime,
    bool? isExpired,
    DateTime? urlExpirationTime, // Add to copyWith
    bool? isAISuggested,
    String? aiSuggestionId,
    bool? isEncrypted,
    String? encryptedContent,
    Map<String, dynamic>? encryptionMetadata,
    bool? decryptionError,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isDisappearing: isDisappearing ?? this.isDisappearing,
      disappearingTime: disappearingTime ?? this.disappearingTime,
      isExpired: isExpired ?? this.isExpired,
      urlExpirationTime: urlExpirationTime ?? this.urlExpirationTime, // Add to copyWith
      isAISuggested: isAISuggested ?? this.isAISuggested,
      aiSuggestionId: aiSuggestionId ?? this.aiSuggestionId,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      encryptionMetadata: encryptionMetadata ?? this.encryptionMetadata,
      decryptionError: decryptionError ?? this.decryptionError,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String? ?? '';
    final sender = json['sender'] as String? ?? json['from'] as String? ?? '';
    final receiver = json['receiver'] as String? ?? json['to'] as String? ?? '';
    
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(json['createdAt'] as String);
    } catch (e) {
      timestamp = DateTime.now();
    }

    MessageType messageType;
    try {
      // Check for both 'messageType' (socket events) and 'type' (API responses)
      final typeStr = json['messageType'] as String? ?? json['type'] as String? ?? 'text';
      AppLogger.info('🔵 Parsing message type from JSON: "$typeStr"');
      AppLogger.info('🔵 Raw JSON fields: messageType=${json['messageType']}, type=${json['type']}');
      
      // More robust message type parsing
      MessageType parsedType;
      switch (typeStr.toLowerCase()) {
        case 'image':
          parsedType = MessageType.image;
          break;
        case 'voice':
          parsedType = MessageType.voice;
          break;
        case 'file':
          parsedType = MessageType.file;
          break;
        case 'text':
        default:
          parsedType = MessageType.text;
          break;
      }
      
      messageType = parsedType;
      AppLogger.info('🔵 Parsed message type: ${messageType.toString().split('.').last}');
    } catch (e) {
      AppLogger.error('❌ Error parsing message type: $e');
      messageType = MessageType.text;
    }

    String status = 'sent';
    try {
      status = json['status'] as String? ?? 'sent';
    } catch (e) {
      status = 'sent';
    }

    DateTime? deliveredAt;
    try {
      if (json['deliveredAt'] != null) {
        deliveredAt = DateTime.parse(json['deliveredAt'] as String);
      }
    } catch (e) {
      AppLogger.info('Error parsing deliveredAt: $e');
    }

    DateTime? readAt;
    try {
      if (json['readAt'] != null) {
        readAt = DateTime.parse(json['readAt'] as String);
      }
    } catch (e) {
      AppLogger.info('Error parsing readAt: $e');
    }

    int? disappearingTime;
    try {
      // Check for disappearingTime in metadata first, then at root level
      if (json['metadata'] != null && json['metadata']['disappearingTime'] != null) {
        disappearingTime = json['metadata']['disappearingTime'] as int;
      } else if (json['disappearingTime'] != null) {
        disappearingTime = json['disappearingTime'] as int;
      }
    } catch (e) {
      AppLogger.info('Error parsing disappearingTime: $e');
    }

    // Parse URL expiration time from metadata.expiresAt or root level urlExpirationTime
    DateTime? urlExpirationTime;
    try {
      AppLogger.info('🔵 DEBUGGING EXPIRATION: Parsing URL expiration time from JSON');
      AppLogger.info('🔵 DEBUGGING EXPIRATION: JSON metadata: ${json['metadata']}');
      AppLogger.info('🔵 DEBUGGING EXPIRATION: JSON metadata type: ${json['metadata']?.runtimeType}');
      
      if (json['metadata'] != null) {
        AppLogger.info('🔵 DEBUGGING EXPIRATION: Metadata exists, checking for expiresAt');
        AppLogger.info('🔵 DEBUGGING EXPIRATION: Metadata keys: ${(json['metadata'] as Map<String, dynamic>).keys.toList()}');
        AppLogger.info('🔵 DEBUGGING EXPIRATION: expiresAt value in metadata: ${json['metadata']['expiresAt']}');
        AppLogger.info('🔵 DEBUGGING EXPIRATION: urlExpirationTime value in metadata: ${json['metadata']['urlExpirationTime']}');
        AppLogger.info('🔵 DEBUGGING EXPIRATION: imageExpiresAt value in metadata: ${json['metadata']['imageExpiresAt']}');
        AppLogger.info('🔵 DEBUGGING EXPIRATION: imageExpirationTime value in metadata: ${json['metadata']['imageExpirationTime']}');
        
        // Try multiple possible field names in metadata
        if (json['metadata']['expiresAt'] != null) {
          urlExpirationTime = DateTime.parse(json['metadata']['expiresAt'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Successfully parsed expiresAt from metadata: $urlExpirationTime');
        } else if (json['metadata']['urlExpirationTime'] != null) {
          urlExpirationTime = DateTime.parse(json['metadata']['urlExpirationTime'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Successfully parsed urlExpirationTime from metadata: $urlExpirationTime');
        } else if (json['metadata']['imageExpiresAt'] != null) {
          urlExpirationTime = DateTime.parse(json['metadata']['imageExpiresAt'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Successfully parsed imageExpiresAt from metadata: $urlExpirationTime');
        } else if (json['metadata']['imageExpirationTime'] != null) {
          urlExpirationTime = DateTime.parse(json['metadata']['imageExpirationTime'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Successfully parsed imageExpirationTime from metadata: $urlExpirationTime');
        } else {
          AppLogger.warning('🔵 DEBUGGING EXPIRATION: No expiration time found in metadata');
        }
      } else {
        AppLogger.warning('🔵 DEBUGGING EXPIRATION: No metadata in JSON');
      }
      
      // Check root level fields if not found in metadata
      if (urlExpirationTime == null) {
        if (json['expiresAt'] != null) {
          urlExpirationTime = DateTime.parse(json['expiresAt'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Parsed expiresAt from root: $urlExpirationTime');
        } else if (json['urlExpirationTime'] != null) {
          urlExpirationTime = DateTime.parse(json['urlExpirationTime'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Parsed urlExpirationTime from root: $urlExpirationTime');
        } else if (json['imageExpiresAt'] != null) {
          urlExpirationTime = DateTime.parse(json['imageExpiresAt'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Parsed imageExpiresAt from root: $urlExpirationTime');
        } else if (json['imageExpirationTime'] != null) {
          urlExpirationTime = DateTime.parse(json['imageExpirationTime'] as String);
          AppLogger.info('🔵 DEBUGGING EXPIRATION: Parsed imageExpirationTime from root: $urlExpirationTime');
        }
      }
      
      AppLogger.info('🔵 DEBUGGING EXPIRATION: Final urlExpirationTime: $urlExpirationTime');
      
      // Fallback: Extract expiration time from S3 URL if metadata is not available
      if (urlExpirationTime == null && json['content'] != null) {
        AppLogger.info('🔵 DEBUGGING EXPIRATION: Attempting fallback extraction from S3 URL');
        final content = json['content'] as String;
        if (content.contains('X-Amz-Expires=')) {
          try {
            final uri = Uri.parse(content);
            final expiresParam = uri.queryParameters['X-Amz-Expires'];
            if (expiresParam != null) {
              final expiresSeconds = int.parse(expiresParam);
              final createdAt = DateTime.parse(json['createdAt'] as String);
              urlExpirationTime = createdAt.add(Duration(seconds: expiresSeconds));
              AppLogger.info('🔵 DEBUGGING EXPIRATION: Extracted expiration from S3 URL: $urlExpirationTime');
            }
          } catch (e) {
            AppLogger.error('❌ DEBUGGING EXPIRATION: Error extracting expiration from S3 URL: $e');
          }
        }
      }
    } catch (e) {
      AppLogger.error('❌ DEBUGGING EXPIRATION: Error parsing urlExpirationTime: $e');
      AppLogger.info('Error parsing urlExpirationTime: $e');
    }

    // Parse isDisappearing from metadata first, then root level
    // If disappearingTime is present, infer isDisappearing as true regardless of explicit value
    bool isDisappearing = false;
    try {
      // First check if disappearingTime is present (this should make the message disappearing)
      // But only for image messages - text messages should never be disappearing
      if (disappearingTime != null && messageType == MessageType.image) {
        isDisappearing = true;
        // Inferring isDisappearing=true because disappearingTime is present for image message
      } else if (disappearingTime != null && messageType == MessageType.text) {
        // Text messages should never be disappearing, even if disappearingTime is present
        isDisappearing = false;
        AppLogger.warning('Ignoring disappearingTime=$disappearingTime for text message - text messages should not disappear');
      } else {
        // Only check explicit isDisappearing field if no disappearingTime is present
        if (json['metadata'] != null && json['metadata']['isDisappearing'] != null) {
          isDisappearing = json['metadata']['isDisappearing'] as bool;
        } else if (json['isDisappearing'] != null) {
          isDisappearing = json['isDisappearing'] as bool;
        }
      }
    } catch (e) {
      AppLogger.info('Error parsing isDisappearing: $e');
    }

    // Parse disappearing fields from JSON

    // Parse other metadata fields
    Map<String, String> metadata = {};
    if (json['metadata'] != null) {
      final metadataMap = json['metadata'] as Map<String, dynamic>;
      metadataMap.forEach((key, value) {
        if (value != null) {
          metadata[key] = value.toString();
        }
      });
    }
    // Add root level fields to metadata if they exist
    if (json['isDisappearing'] != null) metadata['isDisappearing'] = json['isDisappearing'].toString();
    if (json['updatedAt'] != null) metadata['updatedAt'] = json['updatedAt'].toString();

    // Parse AI suggestion fields
    final isAISuggested = json['isAISuggested'] as bool? ?? false;
    final aiSuggestionId = json['aiSuggestionId'] as String?;

    // Parse E2EE fields
    final isEncrypted = json['encryptedContent'] != null || json['encryptionMetadata'] != null;
    final encryptedContent = json['encryptedContent'] as String?;
    final encryptionMetadata = json['encryptionMetadata'] as Map<String, dynamic>?;
    final decryptionError = json['decryptionError'] as bool? ?? false;

    return Message(
      id: id,
      sender: sender,
      receiver: receiver,
      content: json['content'] as String? ?? '',
      timestamp: timestamp,
      type: messageType,
      isRead: json['isRead'] as bool? ?? false,
      metadata: metadata,
      status: status,
      deliveredAt: deliveredAt,
      readAt: readAt,
      isDisappearing: isDisappearing,
      disappearingTime: disappearingTime,
      isExpired: false,
      urlExpirationTime: urlExpirationTime,
      isAISuggested: isAISuggested,
      aiSuggestionId: aiSuggestionId,
      isEncrypted: isEncrypted,
      encryptedContent: encryptedContent,
      encryptionMetadata: encryptionMetadata,
      decryptionError: decryptionError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'createdAt': timestamp.toIso8601String(),
      'messageType': type == MessageType.image ? 'image' : 'text',
      'isRead': isRead,
      'metadata': metadata,
      'status': status,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isDisappearing': isDisappearing,
      'disappearingTime': disappearingTime,
      'isExpired': isExpired,
      'urlExpirationTime': urlExpirationTime?.toIso8601String(),
      'isAISuggested': isAISuggested,
      'aiSuggestionId': aiSuggestionId,
      'isEncrypted': isEncrypted,
      'encryptedContent': encryptedContent,
      'encryptionMetadata': encryptionMetadata,
      'decryptionError': decryptionError,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.sender == sender &&
        other.receiver == receiver &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.type == type &&
        other.isRead == isRead &&
        other.status == status &&
        other.deliveredAt == deliveredAt &&
        other.readAt == readAt &&
        other.isDisappearing == isDisappearing &&
        other.disappearingTime == disappearingTime &&
        other.isExpired == isExpired &&
        other.urlExpirationTime == urlExpirationTime &&
        other.isAISuggested == isAISuggested &&
        other.aiSuggestionId == aiSuggestionId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sender,
        receiver,
        content,
        timestamp,
        type,
        isRead,
        status,
        deliveredAt,
        readAt,
        isDisappearing,
        disappearingTime,
        isExpired,
        urlExpirationTime,
        isAISuggested,
        aiSuggestionId,
      );
} 