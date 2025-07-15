import 'package:flutter/material.dart';

class CustomIcons {
  // Discover Icon - Three circles in a triangular pattern
  static Widget discoverIcon({double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: DiscoverIconPainter(),
      ),
    );
  }

  // Likes Icon - Two overlapping hearts
  static Widget likesIcon({double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: LikesIconPainter(),
      ),
    );
  }

  // Chats Icon - Message bubble with dots
  static Widget chatsIcon({double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ChatsIconPainter(),
      ),
    );
  }

  // Premium Icon - Star
  static Widget premiumIcon({double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PremiumIconPainter(),
      ),
    );
  }

  // Profile Icon - Person silhouette
  static Widget profileIcon({double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ProfileIconPainter(),
      ),
    );
  }
}

// Discover Icon Painter - Simplified
class DiscoverIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw three circles in a triangular pattern
    // Top left - Blue
    paint.color = const Color(0xFF3b82f6);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), size.width * 0.15, paint);
    
    // Top right - Purple  
    paint.color = const Color(0xFF8b5cf6);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), size.width * 0.12, paint);
    
    // Bottom center - Green
    paint.color = const Color(0xFF10b981);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), size.width * 0.15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Likes Icon Painter - Simplified
class LikesIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw a simple heart shape
    paint.color = const Color(0xFFdc2626);
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.8);
    path.cubicTo(
      size.width * 0.2, size.height * 0.6,
      size.width * 0.1, size.height * 0.3,
      size.width * 0.5, size.height * 0.2
    );
    path.cubicTo(
      size.width * 0.9, size.height * 0.3,
      size.width * 0.8, size.height * 0.6,
      size.width * 0.5, size.height * 0.8
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Chats Icon Painter - Simplified
class ChatsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw a simple message bubble
    paint.color = Colors.white;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.6
      ),
      Radius.circular(size.width * 0.1),
    );
    canvas.drawRRect(rect, paint);
    
    // Blue border
    paint.color = const Color(0xFF3b82f6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.02;
    canvas.drawRRect(rect, paint);
    
    // Three dots
    paint.style = PaintingStyle.fill;
    final dotRadius = size.width * 0.04;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.5), dotRadius, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), dotRadius, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.5), dotRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Premium Icon Painter (Star)
class PremiumIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 28;
    canvas.save();
    canvas.scale(scale);

    // Star path - Orange
    final orangePaint = Paint()
      ..color = const Color(0xFFd97706)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(8.0, 4.8);
    path.lineTo(9.0, 6.8);
    path.lineTo(11.2, 6.8);
    path.lineTo(9.6, 8.4);
    path.lineTo(10.0, 10.4);
    path.lineTo(8.0, 9.2);
    path.lineTo(6.0, 10.4);
    path.lineTo(6.4, 8.4);
    path.lineTo(4.8, 6.8);
    path.lineTo(7.0, 6.8);
    path.close();
    canvas.drawPath(path, orangePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Profile Icon Painter - Simplified
class ProfileIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw a simple person silhouette
    // Head circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      size.width * 0.2,
      paint
    );
    
    // Body (rounded rectangle)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.4
      ),
      Radius.circular(size.width * 0.1),
    );
    canvas.drawRRect(bodyRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 