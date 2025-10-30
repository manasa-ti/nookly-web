import 'package:equatable/equatable.dart';
import 'package:nookly/core/utils/logger.dart';

// Metadata classes for different message types
class ImageMetadata {
  final String imageKey;
  final String imageUrl;
  final int imageSize;
  final String imageType;
  final String expiresAt;

  const ImageMetadata({
    required this.imageKey,
    required this.imageUrl,
    required this.imageSize,
    required this.imageType,
    required this.expiresAt,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      imageKey: json['imageKey'] as String,
      imageUrl: json['imageUrl'] as String,
      imageSize: json['imageSize'] as int,
      imageType: json['imageType'] as String,
      expiresAt: json['expiresAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageKey': imageKey,
      'imageUrl': imageUrl,
      'imageSize': imageSize,
      'imageType': imageType,
      'expiresAt': expiresAt,
    };
  }

  ImageMetadata copyWith({
    String? imageKey,
    String? imageUrl,
    int? imageSize,
    String? imageType,
    String? expiresAt,
  }) {
    return ImageMetadata(
      imageKey: imageKey ?? this.imageKey,
      imageUrl: imageUrl ?? this.imageUrl,
      imageSize: imageSize ?? this.imageSize,
      imageType: imageType ?? this.imageType,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class VoiceMetadata {
  final String voiceKey;
  final String voiceUrl;
  final int voiceSize;
  final String voiceType;
  final int voiceDuration; // in seconds
  final String expiresAt;

  const VoiceMetadata({
    required this.voiceKey,
    required this.voiceUrl,
    required this.voiceSize,
    required this.voiceType,
    required this.voiceDuration,
    required this.expiresAt,
  });

  factory VoiceMetadata.fromJson(Map<String, dynamic> json) {
    return VoiceMetadata(
      voiceKey: json['voiceKey'] as String,
      voiceUrl: json['voiceUrl'] as String,
      voiceSize: json['voiceSize'] as int,
      voiceType: json['voiceType'] as String,
      voiceDuration: json['voiceDuration'] as int,
      expiresAt: json['expiresAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voiceKey': voiceKey,
      'voiceUrl': voiceUrl,
      'voiceSize': voiceSize,
      'voiceType': voiceType,
      'voiceDuration': voiceDuration,
      'expiresAt': expiresAt,
    };
  }
}

class GifMetadata {
  final String giphyId;
  final String giphyUrl;
  final String giphyPreviewUrl;
  final int width;
  final int height;
  final String title;

  const GifMetadata({
    required this.giphyId,
    required this.giphyUrl,
    required this.giphyPreviewUrl,
    required this.width,
    required this.height,
    required this.title,
  });

  factory GifMetadata.fromJson(Map<String, dynamic> json) {
    return GifMetadata(
      giphyId: json['giphyId'] as String,
      giphyUrl: json['giphyUrl'] as String,
      giphyPreviewUrl: json['giphyPreviewUrl'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giphyId': giphyId,
      'giphyUrl': giphyUrl,
      'giphyPreviewUrl': giphyPreviewUrl,
      'width': width,
      'height': height,
      'title': title,
    };
  }
}

class StickerMetadata {
  final String giphyId;
  final String stickerUrl;
  final int width;
  final int height;
  final String title;

  const StickerMetadata({
    required this.giphyId,
    required this.stickerUrl,
    required this.width,
    required this.height,
    required this.title,
  });

  factory StickerMetadata.fromJson(Map<String, dynamic> json) {
    return StickerMetadata(
      giphyId: json['giphyId'] as String,
      stickerUrl: json['stickerUrl'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giphyId': giphyId,
      'stickerUrl': stickerUrl,
      'width': width,
      'height': height,
      'title': title,
    };
  }
}

class MessageMetadata {
  final bool isDisappearing;
  final int? disappearingTime;
  final bool isRead;
  final String? deliveredAt;
  final String? readAt;
  final bool isViewOnce;
  final ImageMetadata? image;
  final VoiceMetadata? voice;
  final GifMetadata? gif;
  final StickerMetadata? sticker;

  const MessageMetadata({
    required this.isDisappearing,
    this.disappearingTime,
    required this.isRead,
    this.deliveredAt,
    this.readAt,
    required this.isViewOnce,
    this.image,
    this.voice,
    this.gif,
    this.sticker,
  });

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    AppLogger.info('🔍 MessageMetadata.fromJson DEBUG:');
    AppLogger.info('  - Received json keys: ${json.keys.toList()}');
    AppLogger.info('  - json[\'isDisappearing\']: ${json['isDisappearing']} (type: ${json['isDisappearing'].runtimeType})');
    AppLogger.info('  - json[\'disappearingTime\']: ${json['disappearingTime']} (type: ${json['disappearingTime']?.runtimeType})');
    
    final isDisappearing = json['isDisappearing'] as bool? ?? false;
    final disappearingTime = json['disappearingTime'] as int?;
    
    AppLogger.info('  - Parsed isDisappearing: $isDisappearing');
    AppLogger.info('  - Parsed disappearingTime: $disappearingTime');
    
    return MessageMetadata(
      isDisappearing: isDisappearing,
      disappearingTime: disappearingTime,
      isRead: json['isRead'] as bool? ?? false,
      deliveredAt: json['deliveredAt'] as String?,
      readAt: json['readAt'] as String?,
      isViewOnce: json['isViewOnce'] as bool? ?? false,
      image: json['image'] != null ? ImageMetadata.fromJson(json['image'] as Map<String, dynamic>) : null,
      voice: json['voice'] != null ? VoiceMetadata.fromJson(json['voice'] as Map<String, dynamic>) : null,
      gif: json['gif'] != null ? GifMetadata.fromJson(json['gif'] as Map<String, dynamic>) : null,
      sticker: json['sticker'] != null ? StickerMetadata.fromJson(json['sticker'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDisappearing': isDisappearing,
      'disappearingTime': disappearingTime,
      'isRead': isRead,
      'deliveredAt': deliveredAt,
      'readAt': readAt,
      'isViewOnce': isViewOnce,
      'image': image?.toJson(),
      'voice': voice?.toJson(),
      'gif': gif?.toJson(),
      'sticker': sticker?.toJson(),
    };
  }

  MessageMetadata copyWith({
    bool? isDisappearing,
    int? disappearingTime,
    bool? isRead,
    String? deliveredAt,
    String? readAt,
    bool? isViewOnce,
    ImageMetadata? image,
    VoiceMetadata? voice,
    GifMetadata? gif,
    StickerMetadata? sticker,
  }) {
    return MessageMetadata(
      isDisappearing: isDisappearing ?? this.isDisappearing,
      disappearingTime: disappearingTime ?? this.disappearingTime,
      isRead: isRead ?? this.isRead,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isViewOnce: isViewOnce ?? this.isViewOnce,
      image: image ?? this.image,
      voice: voice ?? this.voice,
      gif: gif ?? this.gif,
      sticker: sticker ?? this.sticker,
    );
  }
}

enum MessageType {
  text,
  image,
  voice,
  file,
  gif,
  sticker,
  // Add other types if your API supports them directly by string name
}

class Message extends Equatable {
  final String id;
  final String sender;
  final String receiver;
  final String content;
  final DateTime timestamp; // Corresponds to API's createdAt
  final MessageType type;
  final String status; // sent, delivered, read
  final MessageMetadata? metadata;
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
    this.status = 'sent',
    this.metadata,
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
        status,
        metadata,
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
    String? status,
    MessageMetadata? metadata,
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
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
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
        case 'gif':
          parsedType = MessageType.gif;
          break;
        case 'sticker':
          parsedType = MessageType.sticker;
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

    // Parse metadata - handle both new nested structure and old flat structure
    MessageMetadata? metadata;
    DateTime? urlExpirationTime;
    
    try {
      // Handle hybrid structure: top-level isDisappearing/disappearingTime + nested metadata.image
      // This is common in backend responses
      final topLevelIsDisappearing = json['isDisappearing'] as bool?;
      final topLevelDisappearingTime = json['disappearingTime'] as int?;
      final topLevelIsRead = json['isRead'] as bool?;
      final topLevelDeliveredAt = json['deliveredAt'] as String?;
      final topLevelReadAt = json['readAt'] as String?;
      final topLevelIsViewOnce = json['isViewOnce'] as bool?;
      
      if (json['metadata'] != null) {
        final metadataJson = Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>);
        
        
        // Merge top-level fields into metadata if they exist (for hybrid structure support)
        AppLogger.info('🔍 Message.fromJson DEBUG - BEFORE MERGE:');
        AppLogger.info('  - Top-level isDisappearing: $topLevelIsDisappearing');
        AppLogger.info('  - Top-level disappearingTime: $topLevelDisappearingTime');
        AppLogger.info('  - Metadata original keys: ${metadataJson.keys.toList()}');
        AppLogger.info('  - Metadata original isDisappearing: ${metadataJson['isDisappearing']}');
        AppLogger.info('  - Metadata original disappearingTime: ${metadataJson['disappearingTime']}');
        
        if (topLevelIsDisappearing != null) {
          metadataJson['isDisappearing'] = topLevelIsDisappearing;
          AppLogger.info('  - ✅ Merged isDisappearing: $topLevelIsDisappearing');
        }
        if (topLevelDisappearingTime != null) {
          metadataJson['disappearingTime'] = topLevelDisappearingTime;
          AppLogger.info('  - ✅ Merged disappearingTime: $topLevelDisappearingTime');
        }
        if (topLevelIsRead != null) {
          metadataJson['isRead'] = topLevelIsRead;
        }
        if (topLevelDeliveredAt != null) {
          metadataJson['deliveredAt'] = topLevelDeliveredAt;
        }
        if (topLevelReadAt != null) {
          metadataJson['readAt'] = topLevelReadAt;
        }
        if (topLevelIsViewOnce != null) {
          metadataJson['isViewOnce'] = topLevelIsViewOnce;
        }
        
        AppLogger.info('🔍 Message.fromJson DEBUG - AFTER MERGE:');
        AppLogger.info('  - Final metadata isDisappearing: ${metadataJson['isDisappearing']}');
        AppLogger.info('  - Final metadata disappearingTime: ${metadataJson['disappearingTime']}');
        AppLogger.info('  - Final metadata keys: ${metadataJson.keys.toList()}');
        
        
        // Always use the new nested structure after merging
        metadata = MessageMetadata.fromJson(metadataJson);
        
        // Extract URL expiration time from appropriate metadata
        if (messageType == MessageType.image && metadata.image != null) {
          urlExpirationTime = DateTime.parse(metadata.image!.expiresAt);
        } else if (messageType == MessageType.voice && metadata.voice != null) {
          urlExpirationTime = DateTime.parse(metadata.voice!.expiresAt);
        }
      } else if (topLevelIsDisappearing != null || topLevelDisappearingTime != null) {
        // No metadata object, but top-level fields exist - create metadata from top-level fields
        metadata = MessageMetadata(
          isDisappearing: topLevelIsDisappearing ?? false,
          disappearingTime: topLevelDisappearingTime,
          isRead: topLevelIsRead ?? false,
          deliveredAt: topLevelDeliveredAt,
          readAt: topLevelReadAt,
          isViewOnce: topLevelIsViewOnce ?? false,
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error parsing metadata: $e');
      // Create default metadata if parsing fails
      metadata = const MessageMetadata(
        isDisappearing: false,
        isRead: false,
        isViewOnce: false,
      );
    }
      
      // Fallback: Extract expiration time from S3 URL if metadata is not available
      if (urlExpirationTime == null && json['content'] != null) {
      try {
        final content = json['content'] as String;
        if (content.contains('X-Amz-Expires=')) {
            final uri = Uri.parse(content);
            final expiresParam = uri.queryParameters['X-Amz-Expires'];
            if (expiresParam != null) {
              final expiresSeconds = int.parse(expiresParam);
              final createdAt = DateTime.parse(json['createdAt'] as String);
              urlExpirationTime = createdAt.add(Duration(seconds: expiresSeconds));
        }
      }
    } catch (e) {
        AppLogger.error('❌ Error extracting expiration from S3 URL: $e');
      }
    }



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
      status: status,
      metadata: metadata,
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
      'messageType': _getMessageTypeString(type),
      'status': status,
      'metadata': metadata?.toJson(),
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

  String _getMessageTypeString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.file:
        return 'file';
      case MessageType.gif:
        return 'gif';
      case MessageType.sticker:
        return 'sticker';
    }
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
        other.status == status &&
        other.metadata == metadata &&
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
        status,
        metadata,
        isExpired,
        urlExpirationTime,
        isAISuggested,
        aiSuggestionId,
      );
} 