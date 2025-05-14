import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/core/di/injection_container.dart';
import 'package:hushmate/domain/entities/conversation.dart';
import 'package:hushmate/domain/entities/user.dart';
import 'package:hushmate/domain/repositories/auth_repository.dart';
import 'package:hushmate/presentation/bloc/inbox/inbox_bloc.dart';
import 'package:hushmate/presentation/pages/chat/chat_page.dart';
import 'package:intl/intl.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  InboxBloc? _inboxBloc;
  User? _currentUser;
  bool _isLoadingCurrentUser = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndInitBloc();
  }

  Future<void> _loadCurrentUserAndInitBloc() async {
    try {
      final authRepository = sl<AuthRepository>();
      final user = await authRepository.getCurrentUser();
      if (mounted) {
        if (user != null) {
          setState(() {
            _currentUser = user;
            _inboxBloc = sl<InboxBloc>(param1: _currentUser!.id);
            _inboxBloc!.add(LoadInbox());
            _isLoadingCurrentUser = false;
          });
        } else {
          setState(() {
            _initializationError = 'Failed to load user. Please try again.';
            _isLoadingCurrentUser = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = 'Error initializing: ${e.toString()}';
          _isLoadingCurrentUser = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _inboxBloc?.close();
    super.dispose();
  }

  void _onConversationTap(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversation.id, // This is correct (participant's ID)
          participantName: conversation.participantName,
          participantAvatar: conversation.participantAvatar,
          isOnline: conversation.isOnline,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

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

  Widget _buildAvatar(Conversation conversation) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          backgroundImage: conversation.participantAvatar != null && conversation.participantAvatar!.isNotEmpty
              ? NetworkImage(conversation.participantAvatar!)
              : null,
          child: conversation.participantAvatar == null || conversation.participantAvatar!.isEmpty
              ? Icon(Icons.person, color: Colors.grey[600], size: 40)
              : null,
        ),
        if (conversation.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCurrentUser) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_initializationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_initializationError', textAlign: TextAlign.center),
        ),
      );
    }

    if (_inboxBloc == null) {
      // This case should ideally not be hit if _loadCurrentUserAndInitBloc completes
      return const Center(child: Text('Bloc not initialized.'));
    }

    return BlocProvider.value(
      value: _inboxBloc!,
      child: BlocBuilder<InboxBloc, InboxState>(
        builder: (context, state) {
          if (state is InboxLoading || state is InboxInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InboxError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Failed to load conversations: ${state.message}', textAlign: TextAlign.center),
            ));
          }
          if (state is InboxLoaded) {
            if (state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No conversations yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('When you match with someone, you can start chatting here', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                final hasUnread = conversation.unreadCount > 0;
                final lastMessageText = conversation.messages.isNotEmpty 
                    ? conversation.messages.first.content 
                    : 'No messages yet.';

                return ListTile(
                  onTap: () => _onConversationTap(conversation),
                  leading: _buildAvatar(conversation),
                  title: Text(
                    conversation.participantName,
                    style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal),
                  ),
                  subtitle: Text(
                    lastMessageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: hasUnread ? Colors.black : Colors.grey[600], fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTimestamp(conversation.lastMessageTime),
                        style: TextStyle(color: hasUnread ? Colors.black : Colors.grey[600], fontSize: 12, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Something went wrong.')); // Fallback for unhandled state
        },
      ),
    );
  }
} 