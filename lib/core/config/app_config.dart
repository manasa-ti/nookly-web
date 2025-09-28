import 'package:flutter/material.dart';
import 'environment_manager.dart';

class AppConfig {
  static const String appName = 'Nookly';
  static const String appVersion = '1.0.2';
  
  // API Configuration
  static String get baseUrl => EnvironmentManager.baseUrl;
  static String get socketUrl => EnvironmentManager.socketUrl;
  static const int apiTimeout = 30000; // 30 seconds
  
  // Cache Configuration
  static const int cacheValidDuration = 7; // 7 days
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Sizes
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultIconSize = 24.0;
  
  // Colors - DEPRECATED: Use AppColors from lib/core/theme/app_colors.dart instead
  // These are kept for backward compatibility but should be migrated
  @deprecated
  static const Color primaryColor = Color(0xFFFF4B6A);
  @deprecated
  static const Color secondaryColor = Color(0xFF6C63FF);
  @deprecated
  static const Color backgroundColor = Color(0xFFF5F5F5);
  @deprecated
  static const Color textColor = Color(0xFF333333);
  @deprecated
  static const Color greyColor = Color(0xFF9E9E9E);
  

} 