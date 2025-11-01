import 'package:flutter/material.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/di/injection_container.dart' as di;
import 'package:nookly/core/utils/logger.dart';

/// Mixin to automatically track screen views for StatefulWidget pages
/// 
/// Usage:
/// ```dart
/// class MyPage extends StatefulWidget {
///   const MyPage({super.key});
/// }
/// 
/// class _MyPageState extends State<MyPage> with AnalyticsScreenTracker {
///   @override
///   String get screenName => 'my_page'; // Override with your screen name
/// }
/// ```
mixin AnalyticsScreenTracker<T extends StatefulWidget> on State<T> {
  late final AnalyticsService _analyticsService = di.sl<AnalyticsService>();
  
  /// Override this to provide a custom screen name
  /// Defaults to formatted widget class name
  String? get screenName {
    final className = widget.runtimeType.toString();
    return _formatClassName(className);
  }
  
  @override
  void initState() {
    super.initState();
    // Track screen view after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackScreenView();
    });
  }
  
  void _trackScreenView() {
    final name = screenName;
    if (name != null && name.isNotEmpty) {
      AppLogger.info('📊 Analytics: Screen view - $name');
      _analyticsService.logScreenView(
        screenName: name,
        screenClass: name,
      );
      // Also log as custom event for better visibility
      _analyticsService.logEvent(
        eventName: 'screen_view',
        parameters: {
          'screen_name': name,
        },
      );
    }
  }
  
  String _formatClassName(String className) {
    // Remove "Page" suffix if present
    String formatted = className;
    if (formatted.endsWith('Page')) {
      formatted = formatted.substring(0, formatted.length - 4);
    }
    
    // Convert PascalCase to snake_case
    formatted = formatted.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
    
    // Remove leading underscore
    if (formatted.startsWith('_')) {
      formatted = formatted.substring(1);
    }
    
    return formatted;
  }
}
