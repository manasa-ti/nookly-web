import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nookly/presentation/pages/chat/chat_page.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();
  
  // Navigation key for global navigation
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Callback for token updates
  Function(String)? onTokenRefresh;
  
  // Callback for foreground messages
  Function(RemoteMessage)? onMessageReceived;
  
  // Callback for notification tap
  Function(RemoteMessage)? onNotificationTap;
  
  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request notification permissions (iOS)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _logger.i('⚠️ User granted provisional notification permission');
      } else {
        _logger.w('❌ User declined or has not accepted notification permission');
        return;
      }
      
      // Get FCM token
      String? token = await getToken();
      if (token != null) {
        _logger.i('📱 FCM Token: $token');
        // TODO: Send this token to your backend server
        // Example: await yourApiService.registerFCMToken(token);
      } else {
        _logger.w('⚠️ FCM token not available - may be iOS simulator');
      }
      
      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _logger.i('🔄 FCM Token refreshed: $newToken');
        onTokenRefresh?.call(newToken);
        // TODO: Send updated token to your backend server
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.i('🚀 App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }
      
      _logger.i('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      _logger.e('❌ Error initializing Firebase Messaging: $e');
    }
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('📬 Foreground message received');
    _logger.i('Message ID: ${message.messageId}');
    _logger.i('From: ${message.from}');
    
    if (message.data.isNotEmpty) {
      _logger.i('Data payload: ${message.data}');
    }
    
    if (message.notification != null) {
      _logger.i('Notification Title: ${message.notification?.title}');
      _logger.i('Notification Body: ${message.notification?.body}');
      
      // You can show a local notification or in-app notification here
      // For example, show a snackbar or custom notification widget
    }
    
    // Call custom callback
    onMessageReceived?.call(message);
  }
  
  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('👆 Notification tapped');
    _logger.i('Message ID: ${message.messageId}');
    _logger.i('Data: ${message.data}');
    
    // Navigate based on notification type
    final type = message.data['type'];
    
    switch (type) {
      case 'message':
        _navigateToChat(message.data);
        break;
      case 'match':
        _navigateToMatch(message.data);
        break;
      case 'like':
        _navigateToLikes(message.data);
        break;
      case 'profile_view':
        _navigateToProfileViews(message.data);
        break;
      case 'recommendations':
        _navigateToDiscover();
        break;
      case 'promotion':
        _navigateToPromotion(message.data);
        break;
      case 'call':
        _handleIncomingCall(message.data);
        break;
      default:
        _navigateToHome();
    }
    
    // Call custom callback
    onNotificationTap?.call(message);
  }
  
  /// Navigate to chat screen
  void _navigateToChat(Map<String, dynamic> data) async {
    final senderId = data['sender_id'];
    final senderName = data['sender_name'] ?? 'User';
    final senderAvatar = data['sender_avatar'];
    final isOnline = data['is_online'] == 'true';
    final lastSeen = data['last_seen'];
    
    if (navigatorKey?.currentContext == null) {
      _logger.w('⚠️ Navigator context is null, cannot navigate');
      return;
    }
    
    final context = navigatorKey!.currentContext!;
    
    _logger.i('📱 Navigating to chat with $senderName (ID: $senderId)');
    _logger.i('📱 Participant data - Online: $isOnline, Avatar: ${senderAvatar != null ? "Available" : "None"}');
    
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            conversationId: senderId, // ChatPage uses participantId
            participantName: senderName,
            participantAvatar: senderAvatar,
            isOnline: isOnline,
            lastSeen: lastSeen,
            connectionStatus: isOnline ? 'online' : null,
          ),
        ),
      );
      
      _logger.i('✅ Successfully navigated to chat');
    } catch (e) {
      _logger.e('❌ Error navigating to chat: $e');
      // Fallback: navigate to inbox
      _navigateToInbox();
    }
  }
  
  /// Navigate to main home/inbox - where user can see chats
  void _navigateToInbox() {
    if (navigatorKey?.currentContext != null) {
      final context = navigatorKey!.currentContext!;
      
      // Pop all routes and go to home
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      _logger.i('📱 Navigated to inbox');
    }
  }
  
  /// Navigate to likes screen - show likes tab
  void _navigateToLikes(Map<String, dynamic> data) {
    _navigateToInbox(); // For now, navigate to inbox where they can see likes
    _logger.i('📱 Navigate to likes - user can check likes tab');
  }
  
  /// Navigate to profile views screen
  void _navigateToProfileViews(Map<String, dynamic> data) {
    _navigateToInbox();
    _logger.i('📱 Navigate to profile views - check in app');
  }
  
  /// Navigate to discover/recommendations screen
  void _navigateToDiscover() {
    _navigateToInbox();
    _logger.i('📱 Navigate to discover - check discover tab');
  }
  
  /// Navigate to match screen
  void _navigateToMatch(Map<String, dynamic> data) {
    _navigateToInbox();
    _logger.i('📱 Navigate to match - check chats/matches');
  }
  
  /// Navigate to promotion screen
  void _navigateToPromotion(Map<String, dynamic> data) {
    _navigateToInbox();
    _logger.i('📱 Navigate to promotions - check premium features');
  }
  
  /// Handle incoming call
  void _handleIncomingCall(Map<String, dynamic> data) {
    _navigateToInbox();
    _logger.i('📱 Incoming call notification - navigate to inbox');
  }
  
  /// Navigate to home screen
  void _navigateToHome() {
    _navigateToInbox();
  }
  
  /// Get the current FCM token
  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      // This is expected on iOS simulators - APNS tokens only work on real devices
      if (e.toString().contains('apns-token-not-set')) {
        _logger.w('⚠️ APNS token not available (iOS simulator or no permission)');
        _logger.i('ℹ️ FCM tokens only work on real iOS devices');
        return null;
      }
      _logger.e('❌ Error getting FCM token: $e');
      return null;
    }
  }
  
  /// Delete the FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _logger.i('✅ FCM token deleted');
    } catch (e) {
      _logger.e('Error deleting FCM token: $e');
    }
  }
  
  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('✅ Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Error subscribing to topic: $e');
    }
  }
  
  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Error unsubscribing from topic: $e');
    }
  }
  
  /// Set badge count (iOS only)
  Future<void> setBadgeCount(int count) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _firebaseMessaging.setAutoInitEnabled(true);
        // Note: Badge count management varies by platform
        _logger.i('✅ Badge count set to: $count');
      }
    } catch (e) {
      _logger.e('Error setting badge count: $e');
    }
  }
}

