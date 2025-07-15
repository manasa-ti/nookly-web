import 'package:flutter/material.dart';

class GenericAvatar extends StatelessWidget {
  final String? gender;
  final double size;
  final double? fontSize;

  const GenericAvatar({
    super.key,
    this.gender,
    this.size = 80,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = gender?.toLowerCase() == 'm' || gender?.toLowerCase() == 'male';
    final isFemale = gender?.toLowerCase() == 'f' || gender?.toLowerCase() == 'female';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF234481), // Brand blue
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isMale ? Icons.person : (isFemale ? Icons.person_outline : Icons.person),
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
} 