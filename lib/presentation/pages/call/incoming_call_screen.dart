import 'package:flutter/material.dart';
import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/presentation/widgets/custom_avatar.dart';

/// Incoming Call Screen - Shows incoming call notification UI
/// 
/// Features:
/// - Animated caller avatar
/// - Call type indicator (audio/video)
/// - Accept/reject buttons
/// - Clean, modern UI
class IncomingCallScreen extends StatefulWidget {
  final String roomId;
  final String callerName;
  final String? callerAvatar;
  final String callType;
  final Function(String) onCallAccepted;
  final Function(String) onCallRejected;

  const IncomingCallScreen({
    Key? key,
    required this.roomId,
    required this.callerName,
    this.callerAvatar,
    required this.callType,
    required this.onCallAccepted,
    required this.onCallRejected,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Initialize slide animation for screen entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // Start animations
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                
                // Caller Avatar with pulse animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white85,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CustomAvatar(
                        name: widget.callerName,
                        size: 120,
                        imageUrl: widget.callerAvatar,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Caller Name
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: AppColors.white85,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 10),
                
                // Call Type
                Text(
                  'Incoming ${widget.callType == 'video' ? 'Video' : 'Audio'} Call',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Call Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject Button
                    _buildControlButton(
                      icon: Icons.call_end,
                      backgroundColor: Colors.red,
                      label: 'Decline',
                      onPressed: () {
                        widget.onCallRejected(widget.roomId);
                        Navigator.of(context).pop();
                      },
                    ),
                    
                    // Accept Button
                    _buildControlButton(
                      icon: widget.callType == 'video' 
                          ? Icons.videocam 
                          : Icons.call,
                      backgroundColor: Colors.green,
                      label: 'Accept',
                      onPressed: () {
                        widget.onCallAccepted(widget.roomId);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: AppColors.white85),
            onPressed: onPressed,
            iconSize: 30,
            padding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white85,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

