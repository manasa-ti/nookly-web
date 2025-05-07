import 'package:hushmate/domain/entities/chat_conversation.dart';

class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.id,
    required super.name,
    required super.profilePicture,
    required super.lastMessage,
    required super.timestamp,
    required super.unreadCount,
    required super.isOnline,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePicture: json['profilePicture'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profilePicture': profilePicture,
      'lastMessage': lastMessage,
      'timestamp': timestamp.toIso8601String(),
      'unreadCount': unreadCount,
      'isOnline': isOnline,
    };
  }
} 