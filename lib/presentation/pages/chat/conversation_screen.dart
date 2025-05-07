
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_event.dart';
import 'package:hushmate/presentation/bloc/conversation/conversation_state.dart';
import 'package:hushmate/presentation/widgets/message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;

  const ConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isAttachingFile = false;

  @override
  void initState() {
    super.initState();
    context.read<ConversationBloc>().add(LoadConversation(widget.conversationId));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    if (!mounted) return;
    context.read<ConversationBloc>().add(
      SendTextMessage(widget.conversationId, content),
    );

    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath ?? '',
        );
        
        if (!mounted) return;
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        // Get audio duration
        final duration = await _audioPlayer.setFilePath(path).then((_) => _audioPlayer.duration?.inSeconds ?? 0);
        
        // Send voice message
        if (!mounted) return;
        context.read<ConversationBloc>().add(
          SendVoiceMessage(widget.conversationId, path, Duration(seconds: duration)),
        );
        
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        context.read<ConversationBloc>().add(
          SendImageMessage(widget.conversationId, image.path),
        );
        
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      if (!mounted) return;
      setState(() {
        _isAttachingFile = true;
      });
      
      final result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        final path = file.path;
        final name = file.name;
        final size = file.size;
        
        if (path != null) {
          context.read<ConversationBloc>().add(
            SendFileMessage(widget.conversationId, path, name, size),
          );
          
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAttachingFile = false;
        });
      }
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Send Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('Send File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Leave Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBlockConfirmation() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: const Text('Are you sure you want to block this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.mounted) {
                  final state = context.read<ConversationBloc>().state;
                  if (state is ConversationLoaded) {
                    context.read<ConversationBloc>().add(
                      BlockUser(state.conversation.participantId),
                    );
                  }
                }
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveConfirmation() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Chat'),
          content: const Text('Are you sure you want to leave this chat?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.mounted) {
                  context.read<ConversationBloc>().add(
                    LeaveConversation(widget.conversationId),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationBloc, ConversationState>(
      listener: (BuildContext context, ConversationState state) {
        if (state is ConversationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (BuildContext context, ConversationState state) {
        if (state is ConversationLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (state is ConversationLoaded) {
          final conversation = state.conversation;
          final messages = state.messages;
          final isCallActive = state.isCallActive;
          final isAudioCall = state.isAudioCall;
          
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: conversation.participantAvatar != null
                        ? NetworkImage(conversation.participantAvatar!)
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: conversation.participantAvatar == null
                        ? Text(conversation.participantName[0])
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(conversation.participantName),
                      Text(
                        conversation.isMuted ? 'Muted' : 'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: conversation.isMuted ? Colors.grey : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                if (!isCallActive) ...[
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                      context.read<ConversationBloc>().add(
                        StartAudioCall(widget.conversationId),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () {
                      context.read<ConversationBloc>().add(
                        StartVideoCall(widget.conversationId),
                      );
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showOptionsMenu,
                ),
              ],
            ),
            body: Column(
              children: [
                if (isCallActive)
                  Container(
                    color: Colors.red,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAudioCall ? Icons.mic : Icons.videocam,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isAudioCall ? 'Audio' : 'Video'} Call in Progress',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.white),
                          onPressed: () {
                            context.read<ConversationBloc>().add(
                              EndCall(widget.conversationId),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final message = messages[index];
                      final isMe = message.senderId == conversation.userId;
                      
                      // Group messages by date
                      final showDate = index == 0 || 
                          !_isSameDay(messages[index - 1].timestamp, message.timestamp);
                      
                      return Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _formatDate(message.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          MessageBubble(
                            message: message,
                            isMe: isMe,
                            onTap: () {
                              if (message.type == MessageType.voice) {
                                _playVoiceMessage(message);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (conversation.isBlocked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.red[50],
                    child: const Center(
                      child: Text(
                        'You have blocked this user',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha:0.2),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: _isRecording ? Colors.red : null,
                          ),
                          onPressed: _isRecording ? _stopRecording : _startRecording,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendTextMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: _isAttachingFile ? null : _pickFile,
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendTextMessage,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
        
        return const Scaffold(
          body: Center(
            child: Text('Something went wrong. Please try again.'),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  Future<void> _playVoiceMessage(Message message) async {
    try {
      await _audioPlayer.setFilePath(message.content);
      await _audioPlayer.play();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play voice message: $e')),
      );
    }
  }
} 