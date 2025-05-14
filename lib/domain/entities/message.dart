import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  voice,
  file,
  // Add other types if your API supports them directly by string name
}

class Message extends Equatable {
  final String id;
  final String senderId;
  // final String? receiverId; // Optional, if needed from API
  final String content;
  final DateTime timestamp; // Corresponds to API's createdAt
  final MessageType type;
  final bool? isRead; // Optional, from API's read status
  final Map<String, dynamic>? metadata; // For additional info like fileURL, duration for voice etc.
  // final bool? isDisappearing; // Optional
  // final String? disappearingTime; // Optional

  const Message({
    required this.id,
    required this.senderId,
    // this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead,
    this.metadata,
    // this.isDisappearing,
    // this.disappearingTime,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    MessageType messageType;
    try {
      // Robust mapping for MessageType from string
      final typeString = json['messageType'] as String? ?? 'text';
      messageType = MessageType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeString.toLowerCase(),
        orElse: () => MessageType.text, // Default to text if type string is unknown
      );
    } catch (e) {
      messageType = MessageType.text; // Fallback in case of any error
    }

    return Message(
      id: json['_id'] as String,
      senderId: json['sender'] as String, // from API's 'sender'
      // receiverId: json['receiver'] as String?, // from API's 'receiver'
      content: json['content'] as String? ?? '', // Ensure content is not null
      timestamp: DateTime.parse(json['createdAt'] as String), // from API's 'createdAt'
      type: messageType,
      isRead: json['read'] as bool?,
      // metadata can be constructed based on type if needed, e.g. for image/file URLs
      // isDisappearing: json['isDisappearing'] as bool?,
      // disappearingTime: json['disappearingTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': senderId,
      // 'receiver': receiverId,
      'content': content,
      'createdAt': timestamp.toIso8601String(),
      'messageType': type.name, // Use .name for enum to string
      'read': isRead,
      'metadata': metadata,
      // 'isDisappearing': isDisappearing,
      // 'disappearingTime': disappearingTime,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    // String? receiverId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
    Map<String, dynamic>? metadata,
    // bool? isDisappearing,
    // String? disappearingTime,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      // receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      // isDisappearing: isDisappearing ?? this.isDisappearing,
      // disappearingTime: disappearingTime ?? this.disappearingTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        // receiverId,
        content,
        timestamp,
        type,
        isRead,
        metadata,
        // isDisappearing,
        // disappearingTime,
      ];
} 