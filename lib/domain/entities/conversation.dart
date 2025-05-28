import 'package:equatable/equatable.dart';
import 'package:hushmate/domain/entities/message.dart';

class Conversation extends Equatable {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final List<Message> messages;
  final DateTime lastMessageTime;
  final bool isOnline;
  final int unreadCount;
  final bool isMuted;
  final bool isBlocked;
  final String userId;
  final Message? lastMessage;
  final DateTime updatedAt;
  final bool isTyping;

  const Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.messages,
    required this.lastMessageTime,
    required this.isOnline,
    required this.unreadCount,
    this.isMuted = false,
    this.isBlocked = false,
    required this.userId,
    this.lastMessage,
    required this.updatedAt,
    this.isTyping = false,
  });

  Conversation copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantAvatar,
    List<Message>? messages,
    DateTime? lastMessageTime,
    bool? isOnline,
    int? unreadCount,
    bool? isMuted,
    bool? isBlocked,
    String? userId,
    Message? lastMessage,
    DateTime? updatedAt,
    bool? isTyping,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      messages: messages ?? this.messages,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isOnline: isOnline ?? this.isOnline,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isBlocked: isBlocked ?? this.isBlocked,
      userId: userId ?? this.userId,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participantId,
        participantName,
        participantAvatar,
        messages,
        lastMessageTime,
        isOnline,
        unreadCount,
        isMuted,
        isBlocked,
        userId,
        lastMessage,
        updatedAt,
        isTyping,
      ];

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      participantId: json['participantId'],
      participantName: json['participantName'],
      participantAvatar: json['participantAvatar'],
      isOnline: json['isOnline'] ?? false,
      messages: [],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: 0,
      isMuted: false,
      isBlocked: false,
      userId: '',
      lastMessage: json['lastMessage'] != null ? Message.fromJson(json['lastMessage']) : null,
      updatedAt: DateTime.parse(json['updatedAt']),
      isTyping: json['isTyping'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatar': participantAvatar,
      'isOnline': isOnline,
      'messages': messages.map((e) => e.toJson()).toList(),
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isBlocked': isBlocked,
      'userId': userId,
      'lastMessage': lastMessage?.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
      'isTyping': isTyping,
    };
  }
} 