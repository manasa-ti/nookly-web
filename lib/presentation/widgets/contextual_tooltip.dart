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
  OverlayEntry? _overlayEntry;
  final GlobalKey _childKey = GlobalKey();

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
    
    // Show overlay after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlayTooltip(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _dismiss() {
    if (!_isVisible) return;
    
    setState(() {
      _isVisible = false;
    });
    
    _animationController.reverse().then((_) {
      _removeOverlay();
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _childKey,
      child: widget.child,
    );
  }

  Widget _buildOverlayTooltip() {
    if (!_isVisible) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              _buildTooltip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip() {
    final RenderBox? renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    Offset tooltipPosition;
    Offset arrowPosition;
    double arrowRotation;
    
    switch (widget.position) {
      case TooltipPosition.top:
        tooltipPosition = Offset(
          position.dx + (size.width / 2) - 100, // Center the tooltip (200px width / 2)
          position.dy - 100, // Position above the button with more space
        );
        arrowPosition = Offset(
          position.dx + (size.width / 2) - 8, // Center arrow horizontally
          position.dy - 20, // Position arrow at bottom of tooltip
        );
        arrowRotation = 0; // Point down
        break;
      case TooltipPosition.bottom:
        tooltipPosition = Offset(
          position.dx + (size.width / 2) - 100, // Center the tooltip (200px width / 2)
          position.dy + size.height + 20, // Position below the button with more space
        );
        arrowPosition = Offset(
          position.dx + (size.width / 2) - 8, // Center arrow horizontally
          position.dy + size.height + 10, // Position arrow at top of tooltip
        );
        arrowRotation = 3.14159; // Point up (180 degrees)
        break;
      case TooltipPosition.left:
        tooltipPosition = Offset(
          position.dx - 230, // Position to the left (200px width + 30px margin)
          position.dy + (size.height / 2) - 40, // Center vertically
        );
        arrowPosition = Offset(
          position.dx - 10, // Position arrow at right edge of tooltip
          position.dy + (size.height / 2) - 8, // Center arrow vertically
        );
        arrowRotation = -1.5708; // Point right (-90 degrees)
        break;
      case TooltipPosition.right:
        tooltipPosition = Offset(
          position.dx + size.width + 30, // Position to the right with margin
          position.dy + (size.height / 2) - 40, // Center vertically
        );
        arrowPosition = Offset(
          position.dx + size.width + 10, // Position arrow at left edge of tooltip
          position.dy + (size.height / 2) - 8, // Center arrow vertically
        );
        arrowRotation = 1.5708; // Point left (90 degrees)
        break;
    }
    
    return Stack(
      children: [
        // Tooltip content
        Positioned(
          left: tooltipPosition.dx,
          top: tooltipPosition.dy,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildTooltipContent(),
            ),
          ),
        ),
        // Arrow pointer
        if (widget.showArrow)
          Positioned(
            left: arrowPosition.dx,
            top: arrowPosition.dy,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.rotate(
                angle: arrowRotation,
                child: _buildArrow(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTooltipContent() {
    return Container(
      width: 200, // Fixed width to ensure visibility
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
              fontSize: 14,
              fontFamily: 'Nunito',
              color: Colors.black87,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: CustomPaint(
        painter: ArrowPainter(),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}
