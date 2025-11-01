import 'package:flutter/material.dart';
import 'package:nookly/core/services/analytics_service.dart';
import 'package:nookly/core/di/injection_container.dart' as di;
import 'package:nookly/core/utils/logger.dart';

/// RouteObserver that automatically tracks screen views for analytics
class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final AnalyticsService _analyticsService;

  AnalyticsRouteObserver({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService ?? di.sl<AnalyticsService>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackScreenView(previousRoute);
    }
  }

  void _trackScreenView(Route<dynamic> route) {
    if (route is! PageRoute) {
      return;
    }

    final screenName = _getScreenName(route);
    if (screenName != null && screenName.isNotEmpty && screenName != 'null') {
      AppLogger.info('📊 Analytics: Screen view - $screenName');
      // Use both logScreenView (Firebase standard) and logEvent for better visibility
      _analyticsService.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      // Also log as a custom event with screen name as parameter for better tracking
      _analyticsService.logEvent(
        eventName: 'screen_view',
        parameters: {
          'screen_name': screenName,
        },
      );
    }
  }

  String? _getScreenName(Route<dynamic> route) {
    final routeSettings = route.settings;
    
    // Priority 1: Use route settings name if available
    if (routeSettings.name != null && routeSettings.name!.isNotEmpty) {
      final name = routeSettings.name!;
      if (name != '/' && name.isNotEmpty) {
        return _formatRouteName(name);
      }
    }
    
    // Priority 2: Extract from MaterialPageRoute widget type
    if (route is MaterialPageRoute) {
      final routeString = route.toString();
      // Extract widget class name from route string
      // Pattern: MaterialPageRoute<WidgetClassName>(...)
      final classMatch = RegExp(r'MaterialPageRoute<(\w+Page?)>').firstMatch(routeString);
      if (classMatch != null) {
        return _formatRouteName(classMatch.group(1)!);
      }
      
      // Try alternative pattern
      final altMatch = RegExp(r'<(\w+Page?)>').firstMatch(routeString);
      if (altMatch != null) {
        return _formatRouteName(altMatch.group(1)!);
      }
      
      // Try to extract from builder if available
      try {
        final builderString = route.builder.toString();
        final builderMatch = RegExp(r'(\w+Page)').firstMatch(builderString);
        if (builderMatch != null) {
          return _formatRouteName(builderMatch.group(1)!);
        }
      } catch (e) {
        // Ignore errors in builder inspection
      }
    }
    
    // Priority 3: Extract from CupertinoPageRoute
    if (route.toString().contains('CupertinoPageRoute')) {
      final cupertinoMatch = RegExp(r'CupertinoPageRoute<(\w+Page?)>').firstMatch(route.toString());
      if (cupertinoMatch != null) {
        return _formatRouteName(cupertinoMatch.group(1)!);
      }
    }
    
    // Priority 4: Try to get from route type itself
    final routeTypeMatch = RegExp(r'(\w+Page)').firstMatch(route.runtimeType.toString());
    if (routeTypeMatch != null) {
      return _formatRouteName(routeTypeMatch.group(1)!);
    }
    
    // Last resort: use a sanitized version of route.toString()
    final routeStr = route.toString();
    if (routeStr.isNotEmpty && routeStr != 'null') {
      // Extract any meaningful identifier
      final anyMatch = RegExp(r'[A-Z][a-zA-Z]*').firstMatch(routeStr);
      if (anyMatch != null) {
        return _formatRouteName(anyMatch.group(0)!);
      }
    }
    
    return null;
  }

  String _formatRouteName(String name) {
    // Convert camelCase/PascalCase to snake_case for analytics
    // e.g., "ChatPage" -> "chat_page", "/login" -> "login"
    String formatted = name;
    
    // Remove leading slash
    if (formatted.startsWith('/')) {
      formatted = formatted.substring(1);
    }
    
    // Remove "Page" suffix if present
    if (formatted.endsWith('Page')) {
      formatted = formatted.substring(0, formatted.length - 4);
    }
    
    // Convert to snake_case
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

