/// Firebase Messaging Usage Examples
/// 
/// This file contains examples of how to use Firebase Messaging Service
/// in your application. These are reference examples - adapt them to your needs.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nookly/core/services/firebase_messaging_service.dart';

/// Example 1: Basic Setup
/// 
/// Initialize Firebase Messaging in your app:
/// 
/// ```dart
/// final messagingService = FirebaseMessagingService();
/// await messagingService.initialize();
/// ```

/// Example 2: Get FCM Token
/// 
/// Get the device's FCM token to send to your backend:
/// 
/// ```dart
/// String? token = await messagingService.getToken();
/// if (token != null) {
///   // Send this token to your backend server
///   await yourApiService.registerFCMToken(userId, token);
/// }
/// ```

/// Example 3: Handle Token Refresh
/// 
/// Listen for token updates (e.g., when token expires):
/// 
/// ```dart
/// messagingService.onTokenRefresh = (newToken) {
///   // Send updated token to your backend
///   yourApiService.updateFCMToken(userId, newToken);
/// };
/// ```

/// Example 4: Handle Foreground Messages
/// 
/// Process messages when app is in foreground:
/// 
/// ```dart
/// messagingService.onMessageReceived = (RemoteMessage message) {
///   // Show in-app notification or update UI
///   if (message.data['type'] == 'new_message') {
///     showInAppNotification(
///       title: message.notification?.title ?? 'New Message',
///       body: message.notification?.body ?? '',
///     );
///   }
/// };
/// ```

/// Example 5: Handle Notification Tap
/// 
/// Navigate to specific screen when user taps notification:
/// 
/// ```dart
/// messagingService.onNotificationTap = (RemoteMessage message) {
///   // Navigate based on notification data
///   String? type = message.data['type'];
///   
///   switch (type) {
///     case 'chat':
///       String chatId = message.data['chat_id'];
///       Navigator.pushNamed(context, '/chat', arguments: chatId);
///       break;
///     case 'match':
///       String userId = message.data['user_id'];
///       Navigator.pushNamed(context, '/profile', arguments: userId);
///       break;
///     case 'like':
///       Navigator.pushNamed(context, '/likes');
///       break;
///     default:
///       Navigator.pushNamed(context, '/home');
///   }
/// };
/// ```

/// Example 6: Subscribe to Topics
/// 
/// Subscribe users to notification topics:
/// 
/// ```dart
/// // Subscribe to general announcements
/// await messagingService.subscribeToTopic('announcements');
/// 
/// // Subscribe to user's location-based notifications
/// await messagingService.subscribeToTopic('location_${userCity}');
/// 
/// // Unsubscribe when needed
/// await messagingService.unsubscribeFromTopic('announcements');
/// ```

/// Example 7: Logout - Delete Token
/// 
/// Delete FCM token when user logs out:
/// 
/// ```dart
/// Future<void> logout() async {
///   // Delete FCM token
///   await messagingService.deleteToken();
///   
///   // Clear user session
///   await authService.logout();
/// }
/// ```

/// Example 8: Integration with Dependency Injection
/// 
/// Register FirebaseMessagingService with GetIt:
/// 
/// In your `injection_container.dart`:
/// ```dart
/// // Register as singleton
/// sl.registerLazySingleton(() => FirebaseMessagingService());
/// 
/// // Initialize in main.dart
/// final messagingService = sl<FirebaseMessagingService>();
/// await messagingService.initialize();
/// ```

/// Example 9: Backend Integration
/// 
/// Send FCM token to your backend API:
/// 
/// ```dart
/// class NotificationRepository {
///   final ApiService apiService;
///   
///   Future<void> registerDevice(String fcmToken) async {
///     await apiService.post('/api/devices/register', {
///       'fcm_token': fcmToken,
///       'platform': Platform.isIOS ? 'ios' : 'android',
///       'device_id': deviceId,
///     });
///   }
///   
///   Future<void> unregisterDevice(String fcmToken) async {
///     await apiService.post('/api/devices/unregister', {
///       'fcm_token': fcmToken,
///     });
///   }
/// }
/// ```

/// Example 10: Notification Payload Format
/// 
/// Expected notification payload from your backend:
/// 
/// ```json
/// {
///   "notification": {
///     "title": "New Match!",
///     "body": "You have a new match with Sarah",
///     "sound": "default"
///   },
///   "data": {
///     "type": "match",
///     "user_id": "12345",
///     "timestamp": "2025-10-08T10:30:00Z",
///     "click_action": "FLUTTER_NOTIFICATION_CLICK"
///   },
///   "priority": "high",
///   "content_available": true
/// }
/// ```

/// Example 11: Testing Push Notifications
/// 
/// Using Firebase Console:
/// 1. Go to Firebase Console > Cloud Messaging
/// 2. Click "Send your first message"
/// 3. Enter notification title and text
/// 4. Click "Send test message"
/// 5. Paste your FCM token (from app logs)
/// 6. Click "Test"
/// 
/// Using curl (from your backend):
/// ```bash
/// curl -X POST https://fcm.googleapis.com/fcm/send \
///   -H "Authorization: key=YOUR_SERVER_KEY" \
///   -H "Content-Type: application/json" \
///   -d '{
///     "to": "DEVICE_FCM_TOKEN",
///     "notification": {
///       "title": "Test Notification",
///       "body": "This is a test message"
///     },
///     "data": {
///       "type": "test",
///       "custom_field": "custom_value"
///     }
///   }'
/// ```

/// Example 12: Handle Different Notification Types
/// 
/// Process different types of notifications:
/// 
/// ```dart
/// void handleNotification(RemoteMessage message) {
///   String? type = message.data['type'];
///   
///   switch (type) {
///     case 'chat_message':
///       // Update chat list, show badge
///       chatBloc.add(NewMessageReceived(message.data['message_id']));
///       break;
///       
///     case 'new_like':
///       // Update likes count
///       likesBloc.add(FetchReceivedLikes());
///       break;
///       
///     case 'new_match':
///       // Show match animation
///       showMatchDialog(message.data['user_id']);
///       break;
///       
///     case 'profile_view':
///       // Update profile views
///       profileBloc.add(IncrementProfileViews());
///       break;
///   }
/// }
/// ```

/// Best Practices:
/// 
/// 1. Always handle null values for notification data
/// 2. Store FCM token in secure storage
/// 3. Update token on app launch and when it refreshes
/// 4. Delete token on logout for privacy
/// 5. Subscribe/unsubscribe from topics based on user preferences
/// 6. Handle notification permissions gracefully
/// 7. Test on both iOS and Android
/// 8. Test all notification states: foreground, background, terminated
/// 9. Keep notification payloads small (max 4KB)
/// 10. Use data messages for silent notifications


