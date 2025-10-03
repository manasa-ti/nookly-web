import 'package:flutter/material.dart';

class ContextualTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final TooltipPosition position;
  final VoidCallback? onDismiss;
  final bool showArrow;

  const ContextualTooltip({
    Key? key,
    required this.message,
    required this.child,
    this.position = TooltipPosition.bottom,
    this.onDismiss,
    this.showArrow = true,
  }) : super(key: key);

  @override
  State<ContextualTooltip> createState() => _ContextualTooltipState();
}

class _ContextualTooltipState extends State<ContextualTooltip>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!_isVisible) return;
    
    setState(() {
      _isVisible = false;
    });
    
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 TOOLTIP: ContextualTooltip build called - _isVisible: $_isVisible');
    if (!_isVisible) {
      print('🔵 TOOLTIP: Not visible, returning child only');
      return widget.child;
    }

    print('🔵 TOOLTIP: Building tooltip with Stack');
    return Stack(
      clipBehavior: Clip.hardEdge, // Changed from Clip.none to prevent overflow
      children: [
        widget.child,
        // Removed Positioned.fill GestureDetector to avoid competing with button taps
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            print('🔵 TOOLTIP: AnimatedBuilder building tooltip');
            return _buildTooltip();
          },
        ),
      ],
    );
  }

  Widget _buildTooltip() {
    print('🔵 TOOLTIP: _buildTooltip called with position: ${widget.position}');
    switch (widget.position) {
      case TooltipPosition.top:
        return Positioned(
          bottom: 50,
          left: 8,
          right: 8,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildTooltipContent(),
            ),
          ),
        );
      case TooltipPosition.bottom:
        return Positioned(
          top: 50, // Position below the button (button is 44px + some margin)
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildTooltipContent(),
            ),
          ),
        );
      case TooltipPosition.left:
        return Positioned(
          right: 50,
          top: 8,
          bottom: 8,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildTooltipContent(),
            ),
          ),
        );
      case TooltipPosition.right:
        return Positioned(
          left: 50,
          top: 8,
          bottom: 8,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildTooltipContent(),
            ),
          ),
        );
    }
  }

  Widget _buildTooltipContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available space more conservatively
        final availableWidth = constraints.maxWidth - 16; // Reduced padding
        final maxWidth = availableWidth > 260 ? 260 : availableWidth;
        final minWidth = availableWidth > 120 ? 120.0 : availableWidth * 0.8; // Dynamic min width
        
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth.toDouble(),
              minWidth: minWidth.toDouble(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Nunito',
                    color: Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}
