import 'package:flutter/material.dart';
import 'package:hushmate/domain/entities/message.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:hushmate/core/services/image_url_service.dart';
import 'package:hushmate/core/utils/logger.dart';

class MessageBubble extends StatefulWidget {
  final Message? message;
  final bool isMe;
  final VoidCallback? onTap;
  final bool showAvatar;
  final String? avatarUrl;
  final Widget? statusWidget;
  final bool isTyping;
  final VoidCallback? onImageTap;
  final Function(String)? onImageUrlReady;
  final int? disappearingTime;
  final ValueNotifier<int>? timerNotifier;

  const MessageBubble({
    Key? key,
    this.message,
    required this.isMe,
    this.onTap,
    this.showAvatar = false,
    this.avatarUrl,
    this.statusWidget,
    this.isTyping = false,
    this.onImageTap,
    this.onImageUrlReady,
    this.disappearingTime,
    this.timerNotifier,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isVisible = true;
  Timer? _disappearTimer;
  int? _remainingTime;
  String? _currentImageUrl;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: MessageBubble initState for message: ${widget.message?.id}');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Is disappearing: ${widget.message?.isDisappearing}');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Disappearing time: ${widget.message?.disappearingTime}');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Metadata: ${widget.message?.metadata}');
    
    // Add specific logging for disappearing image messages
    if (widget.message?.type == MessageType.image && widget.message?.isDisappearing == true) {
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: Image message with disappearing time detected');
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Message ID: ${widget.message?.id}');
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Disappearing time: ${widget.message?.disappearingTime} seconds');
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Has viewedAt metadata: ${widget.message?.metadata?.containsKey('viewedAt')}');
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - ViewedAt value: ${widget.message?.metadata?['viewedAt']}');
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Widget disappearingTime: ${widget.disappearingTime}');
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Widget timerNotifier: ${widget.timerNotifier != null ? 'Available' : 'Not available'}');
    }
    
    if (widget.message?.isDisappearing == true && widget.message?.disappearingTime != null) {
      _remainingTime = widget.message?.disappearingTime;
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message is disappearing, initial remaining time: $_remainingTime');
      
      // If message has been viewed (has viewedAt in metadata), start the timer
      if (widget.message?.metadata?.containsKey('viewedAt') == true) {
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message has viewedAt metadata, starting timer');
        final viewedAt = DateTime.parse(widget.message!.metadata!['viewedAt']!);
        final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
        _remainingTime = (_remainingTime! - elapsedSeconds).clamp(0, widget.message!.disappearingTime!);
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Viewed at: $viewedAt');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Elapsed seconds: $elapsedSeconds');
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Calculated remaining time: $_remainingTime');
        
        if (_remainingTime! > 0) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Starting timer with remaining time: $_remainingTime');
          _startTimer();
        } else {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: No time remaining, hiding message');
          _isVisible = false;
        }
      } else {
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message does not have viewedAt metadata, timer will start when viewed');
      }
    } else {
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message is not disappearing or has no disappearing time');
    }

    // Initialize image URL if it's an image message
    if (widget.message?.type == MessageType.image) {
      _loadImageUrl();
    }
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: MessageBubble didUpdateWidget');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Old message ID: ${oldWidget.message?.id}');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - New message ID: ${widget.message?.id}');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Old metadata: ${oldWidget.message?.metadata}');
    AppLogger.info('🔵 DEBUGGING MESSAGE ID: - New metadata: ${widget.message?.metadata}');
    
    // Log message state changes
    if (widget.message?.id != oldWidget.message?.id ||
        widget.message?.metadata != oldWidget.message?.metadata) {
      AppLogger.info('🔵 MessageBubble updated:');
      AppLogger.info('  - Message ID: ${widget.message?.id}');
      AppLogger.info('  - Is disappearing: ${widget.message?.isDisappearing}');
      AppLogger.info('  - Disappearing time: ${widget.message?.disappearingTime}');
      AppLogger.info('  - Metadata: ${widget.message?.metadata}');
      AppLogger.info('  - Is expired: ${widget.message?.metadata?['isExpired']}');
    }
    
    // Handle image URL changes
    if (widget.message?.type == MessageType.image &&
        widget.message?.content != oldWidget.message?.content) {
      _loadImageUrl();
    }

    // Handle disappearing message updates
    if (widget.message?.isDisappearing == true && 
        widget.message?.disappearingTime != null &&
        widget.message?.metadata?.containsKey('viewedAt') == true) {
      
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Processing disappearing message update');
      
      // Check if viewedAt was just added or updated
      final oldViewedAt = oldWidget.message?.metadata?['viewedAt'];
      final newViewedAt = widget.message?.metadata?['viewedAt'];
      
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: - Old viewedAt: $oldViewedAt');
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: - New viewedAt: $newViewedAt');
      
      if (newViewedAt != null && (oldViewedAt == null || oldViewedAt != newViewedAt)) {
        AppLogger.info('🔵 Message was just viewed, starting timer');
        AppLogger.info('🔵 Message ID: ${widget.message?.id}');
        AppLogger.info('🔵 Viewed at: $newViewedAt');
        AppLogger.info('🔵 Disappearing time: ${widget.message?.disappearingTime} seconds');
        
        final viewedAt = DateTime.parse(newViewedAt);
        final elapsedSeconds = DateTime.now().difference(viewedAt).inSeconds;
        _remainingTime = (widget.message!.disappearingTime! - elapsedSeconds).clamp(0, widget.message!.disappearingTime!);
        
        AppLogger.info('🔵 Calculated remaining time: $_remainingTime seconds');
        
        if (_remainingTime! > 0) {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: Starting timer with remaining time: $_remainingTime');
          _startTimer();
        } else {
          AppLogger.info('🔵 DEBUGGING MESSAGE ID: No time remaining, hiding message');
          setState(() => _isVisible = false);
        }
      } else {
        AppLogger.info('🔵 DEBUGGING MESSAGE ID: viewedAt not changed, no timer action needed');
      }
    } else {
      AppLogger.info('🔵 DEBUGGING MESSAGE ID: Message is not disappearing or has no viewedAt metadata');
    }

    // Handle expired state
    if (widget.message?.metadata?['isExpired'] == 'true' && 
        oldWidget.message?.metadata?['isExpired'] != 'true') {
      AppLogger.info('🔵 Message marked as expired, updating UI');
      setState(() {
        _isVisible = false;
        _disappearTimer?.cancel();
      });
    }
  }

  Future<void> _loadImageUrl() async {
    if (widget.message?.type != MessageType.image) return;

    AppLogger.info('🔵 Loading image URL for message: ${widget.message!.id}');
    AppLogger.info('🔵 Message content (URL): ${widget.message!.content}');
    AppLogger.info('🔵 URL expiration time: ${widget.message!.urlExpirationTime}');

    setState(() {
      _isLoadingImage = true;
    });

    try {
      // First check if we have a valid URL expiration time
      if (widget.message?.urlExpirationTime != null) {
        final expirationTime = widget.message!.urlExpirationTime!;
        if (expirationTime.isAfter(DateTime.now())) {
          AppLogger.info('🔵 Using existing URL, valid until: $expirationTime');
          setState(() {
            _currentImageUrl = widget.message!.content;
            _isLoadingImage = false;
          });
          widget.onImageUrlReady?.call(widget.message!.content);
          return;
        } else {
          AppLogger.info('🔵 URL has expired at: $expirationTime, requesting new URL');
        }
      } else {
        AppLogger.info('🔵 No expiration time available, using original URL');
        setState(() {
          _currentImageUrl = widget.message!.content;
          _isLoadingImage = false;
        });
        widget.onImageUrlReady?.call(widget.message!.content);
        return;
      }
      
      // Only proceed with URL refresh if the current URL has expired
      AppLogger.info('🔵 Attempting to parse URL: ${widget.message!.content}');
      final uri = Uri.parse(widget.message!.content);
      final pathSegments = uri.path.split('/');
      AppLogger.info('🔵 Path segments: $pathSegments');
      
      if (pathSegments.length < 2) {
        AppLogger.error('❌ URL does not have expected path structure: ${widget.message!.content}');
        // Fallback to using original URL
        setState(() {
          _currentImageUrl = widget.message!.content;
          _isLoadingImage = false;
        });
        return;
      }
      
      final imageKey = pathSegments.sublist(pathSegments.length - 2).join('/'); // Get last two segments: messages/filename
      AppLogger.info('🔵 Extracted image key: $imageKey');
      AppLogger.info('🔵 Original content URL: ${widget.message!.content}');
      
      final imageUrl = await ImageUrlService().getValidImageUrl(imageKey);
      AppLogger.info('🔵 Got pre-signed URL: $imageUrl');
      
      if (mounted) {
        setState(() {
          _currentImageUrl = imageUrl;
          _isLoadingImage = false;
        });
        // Notify parent about the new URL
        widget.onImageUrlReady?.call(imageUrl);
        AppLogger.info('🔵 Updated image URL in state and notified parent');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to load image URL: $e');
      AppLogger.error('❌ Error details: ${e.toString()}');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  void _startTimer() {
    _disappearTimer?.cancel();
    _disappearTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime != null) {
            _remainingTime = (_remainingTime! - 1).clamp(0, widget.message!.disappearingTime!);
            AppLogger.info('🔵 Timer tick - remaining time: $_remainingTime seconds');
            AppLogger.info('🔵 DEBUGGING COUNTDOWN: Message ID: ${widget.message?.id}, Remaining time: $_remainingTime seconds');
            
            if (_remainingTime == 0) {
              AppLogger.info('🔵 Timer finished');
              timer.cancel();
              _isVisible = false;
            }
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _disappearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe && widget.showAvatar) _buildAvatar(),
            if (!widget.isMe && widget.showAvatar) const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message?.isDisappearing == true && widget.message?.disappearingTime != null)
                      Builder(
                        builder: (context) {
                          // Log when timer is being displayed
                          if (widget.message?.type == MessageType.image) {
                            AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: Displaying timer for image message: ${widget.message?.id}');
                            AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Using timerNotifier: ${widget.timerNotifier != null}');
                            AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Widget disappearingTime: ${widget.disappearingTime}');
                            AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Message disappearingTime: ${widget.message?.disappearingTime}');
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: widget.timerNotifier != null
                                ? ValueListenableBuilder<int>(
                                    valueListenable: widget.timerNotifier!,
                                    builder: (context, time, child) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            size: 12,
                                            color: widget.isMe ? Colors.white70 : Colors.black54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${time}s',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: widget.isMe ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 12,
                                        color: widget.isMe ? Colors.white70 : Colors.black54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.disappearingTime ?? widget.message!.disappearingTime}s',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isMe ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    if (widget.message?.type == MessageType.image)
                      GestureDetector(
                        onTap: widget.onImageTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _isLoadingImage
                              ? const SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : Image.network(
                                  _currentImageUrl ?? widget.message!.content,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    final url = _currentImageUrl ?? widget.message!.content;
                                    AppLogger.error('❌ Failed to load image: $error');
                                    AppLogger.error('❌ Image URL: $url');
                                    AppLogger.error('❌ Current image URL: $_currentImageUrl');
                                    AppLogger.error('❌ Message content: ${widget.message!.content}');
                                    return const SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Center(
                                        child: Icon(Icons.error_outline, size: 40),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    if (widget.message?.type == MessageType.text)
                      Text(
                        widget.message!.content,
                        style: TextStyle(
                          color: widget.isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    if (widget.statusWidget != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: widget.statusWidget!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
      child: widget.avatarUrl == null ? const Icon(Icons.person) : null,
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (widget.message == null) {
      return const SizedBox.shrink();
    }

    switch (widget.message!.type) {
      case MessageType.text:
        return Text(
          widget.message!.content,
          style: TextStyle(
            color: widget.isMe ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        if (_isLoadingImage) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_currentImageUrl == null) {
          AppLogger.warning('⚠️ No image URL available for message: ${widget.message!.id}');
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline),
          );
        }

        return GestureDetector(
          onTap: () {
            AppLogger.info('🔵 Image tapped');
            final urlToUse = _currentImageUrl ?? widget.message!.content;
            AppLogger.info('🔵 Using image URL: $urlToUse');
            if (widget.onImageTap != null) {
              widget.onImageTap!();
              AppLogger.info('🔵 Called onImageTap callback');
            } else {
              AppLogger.warning('⚠️ Cannot open image: onImageTap callback is null');
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _currentImageUrl ?? widget.message!.content,
              fit: BoxFit.cover,
              headers: const {
                'Accept': '*/*',
              },
              errorBuilder: (context, error, stackTrace) {
                AppLogger.error('❌ Image load error: $error');
                // If we get a 400 or 403 error, try to refresh the URL
                if (error.toString().contains('400') || error.toString().contains('403')) {
                  AppLogger.info('🔵 Got ${error.toString().contains('400') ? '400' : '403'} error, refreshing URL');
                  _loadImageUrl();
                }
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error_outline),
                );
              },
            ),
          ),
        );
      case MessageType.voice:
        final duration = widget.message!.metadata?['duration'] as int? ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              color: widget.isMe ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(duration),
              style: TextStyle(
                color: widget.isMe ? Colors.white : Colors.black,
              ),
            ),
          ],
        );
      case MessageType.file:
        final fileName = widget.message!.metadata?['fileName'] as String? ?? 'File';
        final fileSize = widget.message!.metadata?['fileSize'] as int? ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              color: widget.isMe ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: widget.isMe ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatFileSize(fileSize),
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return Text(
          widget.message!.content,
          style: TextStyle(
            color: widget.isMe ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        );
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 