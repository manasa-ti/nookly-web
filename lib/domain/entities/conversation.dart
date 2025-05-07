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
      ];
} 