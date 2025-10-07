import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAvatar extends StatelessWidget {
  final String? name;
  final double size;
  final bool isOnline;
  final String? imageUrl; // Optional: for future use if needed

  // Predefined color shades
  static const List<Color> purpleShades = [
    Color(0xFF585b8a),
    Color(0xFF575a89),
    Color(0xFF545c96),
    Color(0xFF505a90),
  ];

  static const List<Color> blueShades = [
    Color(0xFF445f93),
    Color(0xFF59719f),
    Color(0xFF6d82ab),
    Color(0xFF425690),
  ];

  const CustomAvatar({
    Key? key,
    required this.name,
    this.size = 40,
    this.isOnline = false,
    this.imageUrl,
  }) : super(key: key);

  // Generate consistent color based on name
  Color _getBackgroundColor() {
    if (name == null || name!.isEmpty) {
      return blueShades[0];
    }
    
    // Use name hash to generate consistent color from the specified shades
    final hash = name!.hashCode;
    final allColors = [...purpleShades, ...blueShades];
    final colorIndex = hash.abs() % allColors.length;
    
    // Debug: Print the color being used for this name
    print('Avatar for "$name": Using color index $colorIndex (${allColors[colorIndex]})');
    
    return allColors[colorIndex];
  }

  // Get single initial from name
  String _getInitial() {
    if (name == null || name!.isEmpty) {
      return '?';
    }
    
    final nameParts = name!.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    
    // Return only the first letter of the first name
    return nameParts[0].substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging for online status
    print('🔵 CustomAvatar for "$name": isOnline = $isOnline, imageUrl = $imageUrl');
    
    return Stack(
      children: [
        // Profile picture or initials fallback
        if (imageUrl != null && imageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl!,
            width: size,
            height: size,
            imageBuilder: (context, imageProvider) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            placeholder: (context, url) => _buildInitialsAvatar(),
            errorWidget: (context, url, error) => _buildInitialsAvatar(),
          )
        else
          _buildInitialsAvatar(),
        
        // Online status indicator
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitial(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.32, // Reduced from 0.4 to 0.32 for smaller letter
            fontWeight: FontWeight.w500,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }
} 