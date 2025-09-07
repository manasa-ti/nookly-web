import 'package:flutter/material.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';
import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/core/services/image_url_service.dart';
import 'package:nookly/core/utils/logger.dart';

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
  final Function(String messageId, String newImageUrl, DateTime newExpirationTime, Map<String, dynamic> additionalData)? onImageUrlRefreshed;
  final String? timestamp;

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
    this.onImageUrlRefreshed,
    this.timestamp,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
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
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Message url expiry: ${widget.message?.urlExpirationTime}');
      AppLogger.info('🔵 DEBUGGING DISAPPEARING TIME: - Message type: ${widget.message?.type}');
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
          AppLogger.info('🔵 DEBUGGING image url: loading image url  ${widget.message?.content}');
      _loadImageUrl();
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
      
      // Call the actual refresh API
      final imageData = await ImageUrlService().getValidImageUrlWithExpiration(imageKey);
      final imageUrl = imageData['imageUrl'] as String;
      final expiresAt = imageData['expiresAt'] as String;
      AppLogger.info('🔵 Got pre-signed URL: $imageUrl');
      AppLogger.info('🔵 Expires at: $expiresAt');
      
      if (mounted) {
        setState(() {
          _currentImageUrl = imageUrl;
          _isLoadingImage = false;
        });
        
        // Notify parent about the new URL
        widget.onImageUrlReady?.call(imageUrl);
        
        // Update message in bloc state with new image data
        if (widget.onImageUrlRefreshed != null && widget.message != null) {
          try {
            final expirationTime = DateTime.parse(expiresAt);
            AppLogger.info('🔵 Updating message with refreshed image data');
            AppLogger.info('🔵 New image URL: $imageUrl');
            AppLogger.info('🔵 New expiration time: $expirationTime');
            
            widget.onImageUrlRefreshed!(
              widget.message!.id,
              imageUrl,
              expirationTime,
              {'imageKey': imageKey}, // Additional data
            );
          } catch (e) {
            AppLogger.error('❌ Failed to update message with refreshed image data: $e');
          }
        }
        
        AppLogger.info('🔵 Updated image URL in state and notified parent');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to load image URL: $e');
      AppLogger.error('❌ Error details: ${e.toString()}');
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
          // Use fallback URL to prevent infinite retries
          _currentImageUrl = 'https://via.placeholder.com/200x200?text=Image+Unavailable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if message is expired (handled by external timer management)
    if (widget.message?.metadata?['isExpired'] == 'true') {
      AppLogger.info('🔵 Message marked as expired, hiding: ${widget.message?.id}');
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isMe && widget.showAvatar) _buildAvatar(),
                if (!widget.isMe && widget.showAvatar) const SizedBox(width: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isMe ? const Color(0xFFf9666c) : const Color(0xFF585b8c),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.message?.isDisappearing == true && 
                              widget.message?.disappearingTime != null &&
                              widget.message?.type == MessageType.image)
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
                                                  color: widget.isMe ? Colors.white : Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${time}s',
                                                  style: TextStyle(
                                                    fontSize: (MediaQuery.of(context).size.width * 0.025).clamp(10.0, 12.0),
                                                    fontFamily: 'Nunito',
                                                    color: widget.isMe ? Colors.white : Colors.white70,
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
                                              color: widget.isMe ? Colors.white : Colors.white70,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${widget.disappearingTime ?? widget.message!.disappearingTime}s',
                                              style: TextStyle(
                                                fontSize: (MediaQuery.of(context).size.width * 0.025).clamp(10.0, 12.0),
                                                fontFamily: 'Nunito',
                                                color: widget.isMe ? Colors.white : Colors.white70,
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
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      )
                                    : _buildImageContent(),
                              ),
                            ),
                          if (widget.message?.type == MessageType.text)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message!.content,
                                  style: TextStyle(
                                    color: widget.isMe ? Colors.white : Colors.white,
                                    fontFamily: 'Nunito',
                                    fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(13.0, 16.0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                                if (widget.message?.isAISuggested == true) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        size: 12,
                                        color: widget.isMe ? Colors.white70 : Colors.white60,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'AI suggested',
                                        style: TextStyle(
                                          color: widget.isMe ? Colors.white70 : Colors.white60,
                                          fontFamily: 'Nunito',
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Display timestamp outside the bubble
            if (widget.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                child: Text(
                  widget.timestamp!,
                  style: TextStyle(
                    fontSize: (MediaQuery.of(context).size.width * 0.03).clamp(10.0, 12.0),
                    fontFamily: 'Nunito',
                    color: Colors.white60,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // Check if this is a disappearing image that hasn't been viewed yet
    final isDisappearingUnviewed = widget.message?.isDisappearing == true && 
                                   widget.message?.disappearingTime != null &&
                                   widget.message?.metadata?['viewedAt'] == null;
    
    if (isDisappearingUnviewed) {
      // Show animated frame preview for disappearing images
      return _buildAnimatedPreview();
    } else {
      // Show normal image for viewed disappearing images or regular images
      return Image.network(
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF234481)),
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
              child: Icon(Icons.error_outline, size: 40, color: Color(0xFF234481)),
            ),
          );
        },
      );
    }
  }

  Widget _buildAnimatedPreview() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF234481).withOpacity(0.3 + (0.2 * value)),
                const Color(0xFF4CAF50).withOpacity(0.3 + (0.2 * value)),
                const Color(0xFF234481).withOpacity(0.3 + (0.2 * value)),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.5 + (0.3 * value)),
              width: 2 + (2 * value),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF234481).withOpacity(0.3 * value),
                blurRadius: 10 + (10 * value),
                spreadRadius: 2 * value,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.visibility,
              size: 40 + (20 * value),
              color: Colors.white.withOpacity(0.8 + (0.2 * value)),
            ),
          ),
        );
      },
      onEnd: () {
        // Restart the animation for continuous effect
        setState(() {});
      },
    );
  }

  Widget _buildAvatar() {
    return CustomAvatar(
      name: widget.avatarUrl, // Using avatarUrl as name for initials
      size: 32,
    );
  }


} 