import 'package:flutter/material.dart';
import 'package:nookly/core/theme/app_colors.dart';
import 'package:nookly/core/theme/app_text_styles.dart';

class ContextualTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final TooltipPosition position;
  final VoidCallback? onDismiss;
  final bool showArrow;
  final IconData? icon; // Optional icon for games tutorial

  const ContextualTooltip({
    Key? key,
    required this.message,
    required this.child,
    this.position = TooltipPosition.bottom,
    this.onDismiss,
    this.showArrow = true,
    this.icon,
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
  double _tooltipWidth = 280; // Default width, will be adjusted

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
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate flexible width based on screen size and content
    final maxWidth = (screenWidth * 0.85).clamp(280.0, 320.0);
    final minWidth = 240.0;
    
    // Measure text to determine optimal width
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message,
        style: TextStyle(
          fontSize: AppTextStyles.getBodyFontSize(context),
          fontFamily: 'Nunito',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    textPainter.layout(maxWidth: maxWidth);
    
    final contentWidth = (textPainter.width + 48).clamp(minWidth, maxWidth); // 48 = padding
    _tooltipWidth = contentWidth;
    
    Offset tooltipPosition;
    Offset arrowPosition;
    double arrowRotation;
    
    switch (widget.position) {
      case TooltipPosition.top:
        tooltipPosition = Offset(
          position.dx + (size.width / 2) - (contentWidth / 2),
          position.dy - 120, // More space for content
        );
        arrowPosition = Offset(
          position.dx + (size.width / 2) - 8,
          position.dy - 20,
        );
        arrowRotation = 0;
        break;
      case TooltipPosition.bottom:
        tooltipPosition = Offset(
          position.dx + (size.width / 2) - (contentWidth / 2),
          position.dy + size.height + 20,
        );
        arrowPosition = Offset(
          position.dx + (size.width / 2) - 8,
          position.dy + size.height + 10,
        );
        arrowRotation = 3.14159; // 180 degrees
        break;
      case TooltipPosition.left:
        tooltipPosition = Offset(
          position.dx - contentWidth - 30,
          position.dy + (size.height / 2) - 50,
        );
        arrowPosition = Offset(
          position.dx - 10,
          position.dy + (size.height / 2) - 8,
        );
        arrowRotation = -1.5708; // -90 degrees
        break;
      case TooltipPosition.right:
        tooltipPosition = Offset(
          position.dx + size.width + 30,
          position.dy + (size.height / 2) - 50,
        );
        arrowPosition = Offset(
          position.dx + size.width + 10,
          position.dy + (size.height / 2) - 8,
        );
        arrowRotation = 1.5708; // 90 degrees
        break;
    }
    
    // Ensure tooltip stays within screen bounds
    final screenPadding = 16.0;
    if (tooltipPosition.dx < screenPadding) {
      tooltipPosition = Offset(screenPadding, tooltipPosition.dy);
    } else if (tooltipPosition.dx + contentWidth > screenWidth - screenPadding) {
      tooltipPosition = Offset(screenWidth - contentWidth - screenPadding, tooltipPosition.dy);
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
      width: _tooltipWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Dark blue theme color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white85.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Optional icon
          if (widget.icon != null) ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: AppColors.onSurface,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Message text with proper wrapping
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextStyles.getBodyFontSize(context),
              fontFamily: 'Nunito',
              color: AppColors.onSurface,
              height: 1.5,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            maxLines: null, // Allow unlimited lines for wrapping
            softWrap: true,
          ),
          
          const SizedBox(height: 16),
          
          // Got it button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _dismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onSurface, // White button
                foregroundColor: AppColors.surface, // Dark text on white
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Got it!',
                style: TextStyle(
                  fontSize: AppTextStyles.getBodyFontSize(context),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
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
      child: CustomPaint(
        painter: ArrowPainter(
          color: AppColors.surface,
          borderColor: AppColors.white85.withOpacity(0.2),
        ),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  ArrowPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
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
