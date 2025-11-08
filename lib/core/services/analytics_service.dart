import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:nookly/core/config/environment_manager.dart';
import 'package:nookly/core/utils/logger.dart';
import 'package:nookly/core/services/analytics_super_properties.dart';

/// Service for tracking user analytics events using Firebase Analytics
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final AnalyticsSuperProperties _superProperties;
  bool _isEnabled = true;

  AnalyticsService({
    FirebaseAnalytics? analytics,
    AnalyticsSuperProperties? superProperties,
  })  : _analytics = analytics ?? FirebaseAnalytics.instance,
        _superProperties = superProperties ?? AnalyticsSuperProperties() {
    // Enable analytics for all environments (separate Firebase projects per environment)
    _isEnabled = true;
    
    // Initialize platform
    _superProperties.initializePlatform();
    
    AppLogger.info('Analytics enabled for ${EnvironmentManager.currentEnvironment} environment');
  }

  /// Get super properties instance
  AnalyticsSuperProperties get superProperties => _superProperties;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (!_isEnabled) {
      return;
    }

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      // Enable debug mode in development for real-time viewing in DebugView
      if (kDebugMode) {
        await _analytics.setAnalyticsCollectionEnabled(true);
        AppLogger.info('Analytics service initialized (Debug mode enabled - use DebugView for real-time events)');
      } else {
        AppLogger.info('Analytics service initialized');
      }
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

  /// Log a custom event with super properties automatically included
  /// 
  /// This method automatically merges super properties (platform, location, gender, user_id)
  /// with the provided parameters. Super properties take precedence if there's a conflict.
  Future<void> logEventWithSuperProperties({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    // Merge super properties with event parameters
    final allParameters = <String, Object>{
      ..._superProperties.allProperties,
      if (parameters != null) ...parameters,
    };

    await logEvent(
      eventName: eventName,
      parameters: allParameters.isNotEmpty ? allParameters : null,
    );
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
    String? errorCode,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'api_error',
      parameters: {
        'error_code': errorCode ?? statusCode.toString(),
        'error_message': errorMessage ?? 'Unknown error',
      },
    );
  }

  /// Track network request
  Future<void> logNetworkRequest({
    required String name,
    required int responseTime,
    required int statusCode,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'network_request',
      parameters: {
        'name': name,
        'response_time': responseTime,
        'status_code': statusCode,
      },
    );
  }

  /// Track profile viewed (other user's profile)
  Future<void> logProfileViewed() async {
    await logEventWithSuperProperties(
      eventName: 'profile_viewed',
    );
  }

  /// Track game selected
  Future<void> logGameSelected({
    required String gameName,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'game_selected',
      parameters: {
        'game_name': gameName,
      },
    );
  }

  /// Track game invite sent
  Future<void> logGameInviteSent({
    required String gameName,
    required String recipientUserId,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'game_invite_sent',
      parameters: {
        'game_name': gameName,
        'recipient_user_id': recipientUserId,
      },
    );
  }

  /// Track game started
  Future<void> logGameStarted({
    required String gameName,
    required String user1Id,
    required String user2Id,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'game_started',
      parameters: {
        'game_name': gameName,
        'user_1_id': user1Id,
        'user_2_id': user2Id,
      },
    );
  }

  /// Track game ended
  Future<void> logGameEnded({
    required String gameName,
    required int turnsPlayed,
    required int gameDuration, // in seconds
  }) async {
    await logEventWithSuperProperties(
      eventName: 'game_ended',
      parameters: {
        'game_name': gameName,
        'turns_played': turnsPlayed,
        'game_duration': gameDuration,
      },
    );
  }

  /// Track image sent
  Future<void> logImageSent({
    required String recipientId,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'image_sent',
      parameters: {
        'recipient_id': recipientId,
      },
    );
  }

  /// Track image viewed
  Future<void> logImageViewed() async {
    await logEventWithSuperProperties(
      eventName: 'image_viewed',
    );
  }

  /// Track GIF sent
  Future<void> logGifSent({
    required String recipientId,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'GIF_sent',
      parameters: {
        'recipient_id': recipientId,
      },
    );
  }

  /// Track sticker sent
  Future<void> logStickerSent({
    required String recipientId,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'sticker_sent',
      parameters: {
        'recipient_id': recipientId,
      },
    );
  }

  /// Track open up clicked
  Future<void> logOpenUpClicked() async {
    await logEventWithSuperProperties(
      eventName: 'open_up_clicked',
    );
  }

  /// Track get close clicked
  Future<void> logGetCloseClicked() async {
    await logEventWithSuperProperties(
      eventName: 'get_close_clicked',
    );
  }

  /// Track heat up clicked
  Future<void> logHeatUpClicked() async {
    await logEventWithSuperProperties(
      eventName: 'heat_up_clicked',
    );
  }

  /// Track conversation starter selected
  Future<void> logConversationStarterSelected() async {
    await logEventWithSuperProperties(
      eventName: 'conversation_starter_selected',
    );
  }

  /// Track audio call clicked
  Future<void> logAudioCallClicked() async {
    await logEventWithSuperProperties(
      eventName: 'audio_call_clicked',
    );
  }

  /// Track video call clicked
  Future<void> logVideoCallClicked() async {
    await logEventWithSuperProperties(
      eventName: 'video_call_clicked',
    );
  }

  /// Track audio call joined
  Future<void> logAudioCallJoined({
    required String user1Id,
    required String user2Id,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'audio_call_joined',
      parameters: {
        'user_1_id': user1Id,
        'user_2_id': user2Id,
      },
    );
  }

  /// Track video call joined
  Future<void> logVideoCallJoined({
    required String user1Id,
    required String user2Id,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'video_call_joined',
      parameters: {
        'user_1_id': user1Id,
        'user_2_id': user2Id,
      },
    );
  }

  /// Track report clicked
  Future<void> logReportClicked() async {
    await logEventWithSuperProperties(
      eventName: 'report_clicked',
    );
  }

  /// Track user reported
  Future<void> logUserReported({
    required String reporteeId,
    required String reporterId,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'user_reported',
      parameters: {
        'reportee_id': reporteeId,
        'reporter': reporterId,
      },
    );
  }

  /// Track user blocked
  Future<void> logUserBlocked({
    required String blockedId,
    required String blockerId,
  }) async {
    await logEventWithSuperProperties(
      eventName: 'user_blocked',
      parameters: {
        'blocked_id': blockedId,
        'blocker_id': blockerId,
      },
    );
  }

  /// Track block clicked
  Future<void> logBlockClicked() async {
    await logEventWithSuperProperties(
      eventName: 'block_clicked',
    );
  }
}

