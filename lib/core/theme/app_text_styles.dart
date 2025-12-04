import 'package:flutter/material.dart';

/// Centralized text style system for the Nookly app
/// 
/// This file provides adaptive font sizes that automatically adjust
/// based on screen size, with reduced sizes for screens < 6 inches.
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  /// Threshold width in logical pixels for small screens (< 6 inches)
  /// Typical 6" phone has width ~360-400dp, using 400 as threshold
  static const double _smallScreenThreshold = 360.0;

  /// Check if the current screen is considered small (< 6 inches)
  /// 
  /// Uses screen width as a proxy for screen size:
  /// - Screens with width < 400dp are considered small
  /// - This corresponds to phones with diagonal < 6 inches
  static bool isSmallScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < _smallScreenThreshold;
  }

  /// Get adaptive font size for body text (used in message bubbles, etc.)
  /// 
  /// - Small screens (< 6 inches): (width * 0.035).clamp(11.0, 14.0)
  /// - Larger screens: (width * 0.04).clamp(13.0, 16.0)
  static double getBodyFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      // Smaller font for screens < 6 inches
      return (width * 0.035).clamp(11.0, 14.0);
    } else {
      // Normal font size for larger screens
      return (width * 0.04).clamp(13.0, 16.0);
    }
  }

  /// Get adaptive font size for title text
  /// 
  /// - Small screens: (width * 0.05).clamp(16.0, 20.0)
  /// - Larger screens: (width * 0.06).clamp(18.0, 24.0)
  static double getTitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.05).clamp(16.0, 20.0);
    } else {
      return (width * 0.06).clamp(18.0, 24.0);
    }
  }

  /// Get adaptive font size for subtitle text
  /// 
  /// - Small screens: (width * 0.04).clamp(12.0, 15.0)
  /// - Larger screens: (width * 0.045).clamp(14.0, 18.0)
  static double getSubtitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.04).clamp(12.0, 15.0);
    } else {
      return (width * 0.045).clamp(14.0, 18.0);
    }
  }

  /// Get adaptive font size for caption text (timestamps, labels, etc.)
  /// 
  /// - Small screens: (width * 0.03).clamp(10.0, 12.0)
  /// - Larger screens: (width * 0.032).clamp(11.0, 13.0)
  static double getCaptionFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.03).clamp(10.0, 12.0);
    } else {
      return (width * 0.032).clamp(11.0, 13.0);
    }
  }

  /// Get adaptive font size for small caption text (very small labels)
  /// 
  /// - Small screens: (width * 0.025).clamp(9.0, 11.0)
  /// - Larger screens: (width * 0.028).clamp(10.0, 12.0)
  static double getSmallCaptionFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.025).clamp(9.0, 11.0);
    } else {
      return (width * 0.028).clamp(10.0, 12.0);
    }
  }

  /// Get adaptive font size for section headers (0.04 multiplier pattern)
  /// 
  /// - Small screens: (width * 0.035).clamp(12.0, 14.0)
  /// - Larger screens: (width * 0.04).clamp(14.0, 16.0)
  static double getSectionHeaderFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.035).clamp(12.0, 14.0);
    } else {
      return (width * 0.04).clamp(14.0, 16.0);
    }
  }

  /// Get adaptive font size for dialog titles
  /// 
  /// - Small screens: (width * 0.038).clamp(13.0, 15.0)
  /// - Larger screens: (width * 0.042).clamp(15.0, 17.0)
  /// 
  /// This is between section header and app bar title sizes.
  static double getDialogTitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.038).clamp(13.0, 15.0);
    } else {
      return (width * 0.042).clamp(15.0, 17.0);
    }
  }

  /// Get adaptive font size for app bar titles (0.045 multiplier pattern)
  /// 
  /// - Small screens: (width * 0.04).clamp(13.0, 16.0)
  /// - Larger screens: (width * 0.045).clamp(14.0, 18.0)
  static double getAppBarTitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.04).clamp(13.0, 16.0);
    } else {
      return (width * 0.045).clamp(14.0, 18.0);
    }
  }

  /// Get adaptive font size for chip text (0.035 multiplier pattern)
  /// 
  /// - Small screens: (width * 0.03).clamp(11.0, 13.0)
  /// - Larger screens: (width * 0.035).clamp(12.0, 15.0)
  static double getChipFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.03).clamp(11.0, 13.0);
    } else {
      return (width * 0.035).clamp(12.0, 15.0);
    }
  }

  /// Get adaptive font size for age/label text (0.032 multiplier pattern)
  /// 
  /// - Small screens: (width * 0.028).clamp(10.0, 12.0)
  /// - Larger screens: (width * 0.032).clamp(11.0, 14.0)
  static double getLabelFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.028).clamp(10.0, 12.0);
    } else {
      return (width * 0.032).clamp(11.0, 14.0);
    }
  }

  /// Get adaptive font size for large titles (0.05 multiplier pattern)
  /// 
  /// - Small screens: (width * 0.044).clamp(14.0, 18.0)
  /// - Larger screens: (width * 0.05).clamp(16.0, 20.0)
  static double getLargeTitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      return (width * 0.044).clamp(14.0, 18.0);
    } else {
      return (width * 0.05).clamp(16.0, 20.0);
    }
  }

  /// Get adaptive font size with custom multiplier and clamp values
  /// 
  /// This is a flexible method for custom font sizes that still respect
  /// the small screen reduction pattern. Applies ~87.5% reduction for small screens.
  /// 
  /// [largeScreenMultiplier] - Multiplier for large screens
  /// [largeScreenMin] - Minimum size for large screens
  /// [largeScreenMax] - Maximum size for large screens
  static double getCustomFontSize(
    BuildContext context, {
    required double largeScreenMultiplier,
    required double largeScreenMin,
    required double largeScreenMax,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < _smallScreenThreshold;
    
    if (isSmall) {
      // Apply ~87.5% reduction for small screens
      final smallMultiplier = largeScreenMultiplier * 0.875;
      final smallMin = largeScreenMin * 0.875;
      final smallMax = largeScreenMax * 0.875;
      return (width * smallMultiplier).clamp(smallMin, smallMax);
    } else {
      return (width * largeScreenMultiplier).clamp(largeScreenMin, largeScreenMax);
    }
  }
}

