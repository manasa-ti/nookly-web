class ChatConversation {
  final String id;
  final String name;
  final String profilePicture;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;

  const ChatConversation({
    required this.id,
    required this.name,
    required this.profilePicture,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
  });
} 