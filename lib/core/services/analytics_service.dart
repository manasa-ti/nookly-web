import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:nookly/core/config/environment_manager.dart';
import 'package:nookly/core/utils/logger.dart';

/// Service for tracking user analytics events using Firebase Analytics
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  bool _isEnabled = true;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance {
    // Enable analytics for all environments (separate Firebase projects per environment)
    _isEnabled = true;
    
    AppLogger.info('Analytics enabled for ${EnvironmentManager.currentEnvironment} environment');
  }

  /// Initialize analytics service
  Future<void> initialize() async {
    if (!_isEnabled) {
      return;
    }

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      AppLogger.info('Analytics service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize analytics', e);
    }
  }

  /// Log a custom event with optional parameters
  /// 
  /// [eventName] should be in snake_case (e.g., 'profile_viewed', 'message_sent')
  /// [parameters] should not contain PII (personally identifiable information)
  Future<void> logEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    if (!_isEnabled) {
      AppLogger.debug('Analytics event (disabled): $eventName');
      return;
    }

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      AppLogger.info('📊 Analytics event logged: $eventName${parameters != null && parameters.isNotEmpty ? ' (params: ${parameters.keys.join(", ")})' : ''}');
    } catch (e) {
      AppLogger.error('Failed to log analytics event: $eventName', e);
    }
  }

  /// Track a screen view
  /// 
  /// [screenName] should be descriptive (e.g., 'profile_page', 'chat_inbox')
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isEnabled) {
      AppLogger.debug('Screen view (disabled): $screenName');
      return;
    }

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      AppLogger.info('📊 Screen view logged: $screenName');
    } catch (e) {
      AppLogger.error('Failed to log screen view: $screenName', e);
    }
  }

  /// Set user property for segmentation
  /// 
  /// Common properties: user_id, subscription_status, user_type, etc.
  /// Should not contain PII
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_isEnabled) {
      AppLogger.debug('User property (disabled): $name = $value');
      return;
    }

    try {
      await _analytics.setUserProperty(name: name, value: value);
      AppLogger.debug('User property set: $name = $value');
    } catch (e) {
      AppLogger.error('Failed to set user property: $name', e);
    }
  }

  /// Set user ID for user-level tracking
  /// 
  /// Should be called after user login/signup
  /// Use anonymized user ID, not PII
  Future<void> setUserId(String? userId) async {
    if (!_isEnabled) {
      AppLogger.debug('User ID (disabled): $userId');
      return;
    }

    try {
      await _analytics.setUserId(id: userId);
      AppLogger.debug('User ID set: $userId');
    } catch (e) {
      AppLogger.error('Failed to set user ID', e);
    }
  }

  /// Reset user properties and ID (call on logout)
  Future<void> resetAnalyticsData() async {
    if (!_isEnabled) {
      return;
    }

    try {
      await _analytics.resetAnalyticsData();
      await _analytics.setUserId(id: null);
      AppLogger.info('Analytics data reset');
    } catch (e) {
      AppLogger.error('Failed to reset analytics data', e);
    }
  }

  // Convenience methods for common events

  /// Track login event
  Future<void> logLogin({String? method}) async {
    await logEvent(
      eventName: 'login',
      parameters: method != null ? {'method': method} : null,
    );
  }

  /// Track signup event
  Future<void> logSignUp({String? method}) async {
    await logEvent(
      eventName: 'sign_up',
      parameters: method != null ? {'method': method} : null,
    );
  }

  /// Track logout event
  Future<void> logLogout() async {
    await logEvent(eventName: 'logout');
  }

  /// Track profile view
  Future<void> logProfileView({String? profileId}) async {
    await logEvent(
      eventName: 'profile_viewed',
      parameters: profileId != null ? {'profile_id': profileId} : null,
    );
  }

  /// Track swipe action (like/pass)
  Future<void> logSwipe({
    required String action, // 'like' or 'pass'
    String? profileId,
  }) async {
    await logEvent(
      eventName: 'swipe_action',
      parameters: {
        'action': action,
        if (profileId != null) 'profile_id': profileId,
      },
    );
  }

  /// Track match event
  Future<void> logMatch({String? matchId}) async {
    await logEvent(
      eventName: 'match',
      parameters: matchId != null ? {'match_id': matchId} : null,
    );
  }

  /// Track message sent
  Future<void> logMessageSent({
    String? conversationId,
    String? messageType, // 'text', 'image', 'voice', etc.
  }) async {
    await logEvent(
      eventName: 'message_sent',
      parameters: {
        if (conversationId != null) 'conversation_id': conversationId,
        if (messageType != null) 'message_type': messageType,
      },
    );
  }

  /// Track purchase event
  Future<void> logPurchase({
    required String itemId,
    required double value,
    String? currency,
  }) async {
    await logEvent(
      eventName: 'purchase',
      parameters: {
        'item_id': itemId,
        'value': value,
        if (currency != null) 'currency': currency,
      },
    );
  }

  /// Track feature usage
  Future<void> logFeatureUsage({
    required String featureName,
    Map<String, Object>? additionalParams,
  }) async {
    final parameters = <String, Object>{
      'feature_name': featureName,
      if (additionalParams != null) ...additionalParams,
    };
    await logEvent(
      eventName: 'feature_used',
      parameters: parameters,
    );
  }

  /// Track API error
  Future<void> logApiError({
    required String endpoint,
    required int statusCode,
    String? errorMessage,
  }) async {
    await logEvent(
      eventName: 'api_error',
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }
}

