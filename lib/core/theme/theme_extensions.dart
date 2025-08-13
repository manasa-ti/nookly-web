import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extensions on BuildContext to easily access theme colors and properties
extension ThemeExtensions on BuildContext {
  /// Get the color scheme from the current theme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Get the text theme from the current theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Get the primary color from the theme
  Color get primaryColor => colorScheme.primary;
  
  /// Get the secondary color from the theme
  Color get secondaryColor => colorScheme.secondary;
  
  /// Get the background color from the theme
  Color get backgroundColor => colorScheme.background;
  
  /// Get the surface color from the theme
  Color get surfaceColor => colorScheme.surface;
  
  /// Get the on primary color from the theme
  Color get onPrimaryColor => colorScheme.onPrimary;
  
  /// Get the on surface color from the theme
  Color get onSurfaceColor => colorScheme.onSurface;
  
  /// Get the on background color from the theme
  Color get onBackgroundColor => colorScheme.onBackground;
  
  /// Get the on surface variant color from the theme
  Color get onSurfaceVariantColor => colorScheme.onSurfaceVariant;
  
  /// Get the error color from the theme
  Color get errorColor => colorScheme.error;
  
  /// Get the border color (custom property)
  Color get borderColor => AppColors.border;
  
  /// Get the selected color (custom property)
  Color get selectedColor => AppColors.selected;
  
  /// Get the unselected color (custom property)
  Color get unselectedColor => AppColors.unselected;
}

/// Extensions on ColorScheme for additional color properties
extension ColorSchemeExtensions on ColorScheme {
  /// Get the border color
  Color get border => AppColors.border;
  
  /// Get the selected color
  Color get selected => AppColors.selected;
  
  /// Get the unselected color
  Color get unselected => AppColors.unselected;
  
  /// Get the muted text color
  Color get muted => AppColors.onSurfaceMuted;
}

