import 'package:flutter/material.dart';
import 'package:hushmate/presentation/pages/chat/chat_page.dart';
import 'package:intl/intl.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'Sarah',
      'lastMessage': 'Hey, how are you doing?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'unreadCount': 2,
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Michael',
      'lastMessage': 'I saw you like photography too! What kind of camera do you use?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'id': '3',
      'name': 'Jessica',
      'lastMessage': 'That sounds like a great plan! Let me know when you\'re free.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 0,
      'isOnline': true,
    },
    // Add more sample conversations
  ];

  void _onConversationTap(int index) {
    // Navigate to chat detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: _conversations[index]['id'],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you match with someone, you can start chatting here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final hasUnread = conversation['unreadCount'] > 0;
        final isOnline = conversation['isOnline'] as bool;

        return ListTile(
          onTap: () => _onConversationTap(index),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, color: Colors.grey[600], size: 40),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            conversation['name'],
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            conversation['lastMessage'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread ? Colors.black : Colors.grey[600],
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimestamp(conversation['timestamp']),
                style: TextStyle(
                  color: hasUnread ? Colors.black : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    conversation['unreadCount'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
} 