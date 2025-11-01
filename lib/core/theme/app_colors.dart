import 'package:flutter/material.dart';

/// Centralized color system for the Nookly app
/// 
/// This file contains all color definitions used throughout the app.
/// Colors are organized by semantic meaning and usage context.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ===== PRIMARY BRAND COLORS =====
  
  /// Primary brand color - used for main actions, buttons, and highlights
  static const Color primary = Color(0xFF4C5C8A);
  
  /// Primary variant - used for hover states and secondary actions
  static const Color primaryVariant = Color(0xFF35548b);
  
  /// Secondary brand color - used for accents and highlights
  static const Color secondary = Color(0xFFFF4B6A);
  
  /// Secondary variant - used for secondary hover states
  static const Color secondaryVariant = Color(0xFFf4656f);

  // ===== BACKGROUND COLORS =====
  
  /// Main app background color
  static const Color background = Color(0xFF2e4781);
  
  /// Surface color for cards, dialogs, and elevated elements
  static const Color surface = Color(0xFF35548b);
  
  /// Surface variant for different elevation levels
  static const Color surfaceVariant = Color(0xFF2D4B8A);

  // ===== TEXT COLORS =====
  
  /// Primary text color
  static const Color onPrimary = Colors.white;
  
  /// Text color on background
  static const Color onBackground = Colors.white;
  
  /// Text color on surface
  static const Color onSurface = Colors.white;
  
  /// Secondary text color for less important text
  static const Color onSurfaceVariant = Color(0xFFD6D9E6);
  
  /// Muted text color for placeholders and disabled text
  static const Color onSurfaceMuted = Color(0xFF8FA3C8);

  // ===== INTERACTION COLORS =====
  
  /// Color for selected states and active elements
  static const Color selected = Color(0xFF4C5C8A);
  
  /// Color for unselected/inactive states
  static const Color unselected = Color(0xFF8FA3C8);
  
  /// Color for borders and dividers
  static const Color border = Color(0xFF8FA3C8);
  
  /// Color for error states
  static const Color error = Color(0xFFf4656f);

  // ===== AVATAR COLORS =====
  
  /// Purple shades for avatar backgrounds
  static const List<Color> avatarPurpleShades = [
    Color(0xFF585b8a),
    Color(0xFF575a89),
    Color(0xFF545c96),
    Color(0xFF505a90),
  ];

  /// Blue shades for avatar backgrounds
  static const List<Color> avatarBlueShades = [
    Color(0xFF445f93),
    Color(0xFF59719f),
    Color(0xFF6d82ab),
    Color(0xFF425690),
  ];

  // ===== GRADIENT COLORS =====
  
  /// Gradient colors for backgrounds
  static const List<Color> backgroundGradient = [
    Color(0xFF2e4781), // #2e4781
    Color(0xFF2D4B8A), // #2D4B8A
    Color(0xFF5A4B7A), // #5A4B7A
  ];

  /// Gradient colors for logo
  static const List<Color> logoGradient = [
    Color(0xFF2e4781), // #2e4781
    Color(0xFF5A4B7A), // #5A4B7A
  ];

  // ===== LEGACY COLORS (for backward compatibility) =====
  
  /// @deprecated Use AppColors.primary instead
  static const Color primaryColor = Color(0xFFFF4B6A);
  
  /// @deprecated Use AppColors.secondary instead
  static const Color secondaryColor = Color(0xFF6C63FF);
  
  /// @deprecated Use AppColors.background instead
  static const Color backgroundColor = Color(0xFFF5F5F5);
  
  /// @deprecated Use AppColors.onSurfaceVariant instead
  static const Color textColor = Color(0xFF333333);
  
  /// @deprecated Use AppColors.onSurfaceMuted instead
  static const Color greyColor = Color(0xFF9E9E9E);
}

