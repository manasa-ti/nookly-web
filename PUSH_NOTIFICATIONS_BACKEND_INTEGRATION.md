# Push Notifications Backend Integration Guide

## 🎯 Overview

Now that Firebase Push Notifications are configured on the frontend, you need to integrate with your backend to:
1. Store user FCM tokens
2. Send targeted notifications to specific users
3. Handle different notification types (messages, matches, likes, etc.)

---

## 📋 Backend Requirements

### What Your Backend Needs:

1. **Database Schema** - Store FCM tokens per user
2. **API Endpoints** - Register/unregister devices
3. **Firebase Admin SDK** - Send notifications from server
4. **Notification Service** - Handle different notification types

---

## 🗄️ Step 1: Database Schema

### Add FCM Token Storage

```sql
-- Create devices table to store FCM tokens
CREATE TABLE user_devices (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token VARCHAR(255) NOT NULL UNIQUE,
    platform VARCHAR(10) NOT NULL, -- 'ios' or 'android'
    device_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Index for faster lookups
CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX idx_user_devices_fcm_token ON user_devices(fcm_token);
CREATE INDEX idx_user_devices_active ON user_devices(is_active);
```

---

## 🔧 Step 2: Backend API Endpoints

### 2.1 Register Device Token

**Endpoint**: `POST /api/notifications/register-device`

**Request Body**:
```json
{
  "fcm_token": "dXXXX...your-fcm-token",
  "platform": "android" | "ios",
  "device_id": "optional-device-identifier"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Device registered successfully"
}
```

**Backend Implementation (Node.js/Express Example)**:
```javascript
// routes/notifications.js
router.post('/register-device', authenticateToken, async (req, res) => {
  try {
    const { fcm_token, platform, device_id } = req.body;
    const userId = req.user.id; // from authentication middleware
    
    // Validate input
    if (!fcm_token || !platform) {
      return res.status(400).json({ 
        success: false, 
        message: 'FCM token and platform are required' 
      });
    }
    
    // Check if token already exists for this user
    const existingDevice = await db.query(
      'SELECT * FROM user_devices WHERE user_id = $1 AND fcm_token = $2',
      [userId, fcm_token]
    );
    
    if (existingDevice.rows.length > 0) {
      // Update existing device
      await db.query(
        `UPDATE user_devices 
         SET last_active = CURRENT_TIMESTAMP, is_active = TRUE, updated_at = CURRENT_TIMESTAMP
         WHERE user_id = $1 AND fcm_token = $2`,
        [userId, fcm_token]
      );
    } else {
      // Insert new device
      await db.query(
        `INSERT INTO user_devices (user_id, fcm_token, platform, device_id)
         VALUES ($1, $2, $3, $4)`,
        [userId, fcm_token, platform, device_id]
      );
    }
    
    res.json({ success: true, message: 'Device registered successfully' });
  } catch (error) {
    console.error('Error registering device:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});
```

### 2.2 Unregister Device Token (Logout)

**Endpoint**: `POST /api/notifications/unregister-device`

**Request Body**:
```json
{
  "fcm_token": "dXXXX...your-fcm-token"
}
```

**Backend Implementation**:
```javascript
router.post('/unregister-device', authenticateToken, async (req, res) => {
  try {
    const { fcm_token } = req.body;
    const userId = req.user.id;
    
    await db.query(
      'UPDATE user_devices SET is_active = FALSE WHERE user_id = $1 AND fcm_token = $2',
      [userId, fcm_token]
    );
    
    res.json({ success: true, message: 'Device unregistered successfully' });
  } catch (error) {
    console.error('Error unregistering device:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});
```

---

## 🔥 Step 3: Firebase Admin SDK Setup

### 3.1 Install Firebase Admin SDK

```bash
npm install firebase-admin
```

### 3.2 Download Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project → Settings (⚙️) → Service accounts
3. Click **"Generate new private key"**
4. Download the JSON file
5. **Keep it secure!** Never commit to Git

### 3.3 Initialize Firebase Admin

```javascript
// config/firebase-admin.js
const admin = require('firebase-admin');
const serviceAccount = require('./path-to-your-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

module.exports = admin;
```

---

## 📤 Step 4: Send Notifications from Backend

### 4.1 Notification Service

Create a reusable notification service:

```javascript
// services/notificationService.js
const admin = require('../config/firebase-admin');
const db = require('../config/database');

class NotificationService {
  
  /**
   * Send notification to a specific user
   */
  async sendToUser(userId, notification) {
    try {
      // Get all active FCM tokens for this user
      const result = await db.query(
        'SELECT fcm_token, platform FROM user_devices WHERE user_id = $1 AND is_active = TRUE',
        [userId]
      );
      
      if (result.rows.length === 0) {
        console.log(`No active devices found for user ${userId}`);
        return { success: false, message: 'No active devices' };
      }
      
      const tokens = result.rows.map(row => row.fcm_token);
      
      // Send to all user's devices
      return await this.sendToTokens(tokens, notification);
    } catch (error) {
      console.error('Error sending notification to user:', error);
      return { success: false, error: error.message };
    }
  }
  
  /**
   * Send notification to specific tokens
   */
  async sendToTokens(tokens, notification) {
    try {
      const message = {
        tokens: tokens,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl || undefined
        },
        data: notification.data || {},
        android: {
          priority: 'high',
          notification: {
            channelId: notification.priority === 'high' ? 'high_importance_channel' : 'default_channel',
            sound: 'default',
            priority: 'high'
          }
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body
              },
              sound: 'default',
              badge: notification.badge || 1
            }
          }
        }
      };
      
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`Successfully sent ${response.successCount} notifications`);
      console.log(`Failed to send ${response.failureCount} notifications`);
      
      // Clean up invalid tokens
      if (response.failureCount > 0) {
        await this.cleanupInvalidTokens(tokens, response.responses);
      }
      
      return { 
        success: true, 
        successCount: response.successCount,
        failureCount: response.failureCount
      };
    } catch (error) {
      console.error('Error sending notification:', error);
      return { success: false, error: error.message };
    }
  }
  
  /**
   * Remove invalid/expired tokens from database
   */
  async cleanupInvalidTokens(tokens, responses) {
    for (let i = 0; i < responses.length; i++) {
      const response = responses[i];
      if (!response.success) {
        const errorCode = response.error?.code;
        
        // Remove tokens that are invalid or unregistered
        if (errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered') {
          const invalidToken = tokens[i];
          await db.query(
            'DELETE FROM user_devices WHERE fcm_token = $1',
            [invalidToken]
          );
          console.log(`Removed invalid token: ${invalidToken}`);
        }
      }
    }
  }
  
  /**
   * Send notification for new message
   */
  async sendNewMessageNotification(recipientUserId, senderName, messagePreview) {
    return await this.sendToUser(recipientUserId, {
      title: `New message from ${senderName}`,
      body: messagePreview,
      priority: 'high',
      data: {
        type: 'chat_message',
        sender_id: recipientUserId.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    });
  }
  
  /**
   * Send notification for new match
   */
  async sendNewMatchNotification(userId, matchedUserName, matchedUserId) {
    return await this.sendToUser(userId, {
      title: 'New Match! 🎉',
      body: `You matched with ${matchedUserName}!`,
      priority: 'high',
      data: {
        type: 'new_match',
        user_id: matchedUserId.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    });
  }
  
  /**
   * Send notification for new like
   */
  async sendNewLikeNotification(userId, likerName) {
    return await this.sendToUser(userId, {
      title: 'Someone likes you! 💖',
      body: `${likerName} liked your profile`,
      priority: 'high',
      data: {
        type: 'new_like',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    });
  }
  
  /**
   * Send notification for profile view
   */
  async sendProfileViewNotification(userId, viewerName) {
    return await this.sendToUser(userId, {
      title: 'Profile View 👀',
      body: `${viewerName} viewed your profile`,
      priority: 'default',
      data: {
        type: 'profile_view',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    });
  }
}

module.exports = new NotificationService();
```

### 4.2 Use Notification Service

```javascript
// Example: Send notification when user receives a message
const notificationService = require('./services/notificationService');

// In your message sending endpoint
router.post('/messages/send', authenticateToken, async (req, res) => {
  try {
    const { recipient_id, message_text } = req.body;
    const senderId = req.user.id;
    
    // Save message to database
    const message = await saveMessage(senderId, recipient_id, message_text);
    
    // Send push notification to recipient
    const senderName = req.user.name;
    await notificationService.sendNewMessageNotification(
      recipient_id,
      senderName,
      message_text.substring(0, 50) // Preview
    );
    
    res.json({ success: true, message });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});
```

---

## 📱 Step 5: Flutter App Integration

### 5.1 Create Notification Repository

```dart
// lib/data/repositories/notification_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  final Dio _dio;
  
  NotificationRepository(this._dio);
  
  /// Register device FCM token with backend
  Future<bool> registerDevice(String fcmToken, String platform) async {
    try {
      final response = await _dio.post(
        '/api/notifications/register-device',
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
          'device_id': await _getDeviceId(), // Optional
        },
      );
      
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Error registering device: $e');
      return false;
    }
  }
  
  /// Unregister device FCM token (logout)
  Future<bool> unregisterDevice(String fcmToken) async {
    try {
      final response = await _dio.post(
        '/api/notifications/unregister-device',
        data: {
          'fcm_token': fcmToken,
        },
      );
      
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('Error unregistering device: $e');
      return false;
    }
  }
  
  Future<String?> _getDeviceId() async {
    // You can use device_info_plus package to get device ID
    return null; // Implement if needed
  }
}
```

### 5.2 Register Token on Login

```dart
// lib/presentation/bloc/auth/auth_bloc.dart
import 'dart:io';
import 'package:nookly/core/services/firebase_messaging_service.dart';
import 'package:nookly/data/repositories/notification_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final NotificationRepository _notificationRepository;
  final FirebaseMessagingService _messagingService;
  
  // ... existing code ...
  
  Future<void> _onLoginSuccess(LoginSuccess event, Emitter<AuthState> emit) async {
    // ... existing login logic ...
    
    // Register FCM token with backend
    await _registerFCMToken();
  }
  
  Future<void> _registerFCMToken() async {
    try {
      final fcmToken = await _messagingService.getToken();
      if (fcmToken != null) {
        final platform = Platform.isIOS ? 'ios' : 'android';
        final success = await _notificationRepository.registerDevice(
          fcmToken,
          platform,
        );
        
        if (success) {
          print('✅ FCM token registered with backend');
        } else {
          print('❌ Failed to register FCM token with backend');
        }
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }
  
  Future<void> _onLogout(Logout event, Emitter<AuthState> emit) async {
    try {
      // Unregister FCM token from backend
      final fcmToken = await _messagingService.getToken();
      if (fcmToken != null) {
        await _notificationRepository.unregisterDevice(fcmToken);
      }
      
      // Delete local FCM token
      await _messagingService.deleteToken();
      
      // ... existing logout logic ...
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
```

### 5.3 Handle Token Refresh

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... Firebase initialization ...
  
  final messagingService = FirebaseMessagingService();
  await messagingService.initialize();
  
  // Handle token refresh
  messagingService.onTokenRefresh = (newToken) async {
    print('🔄 FCM Token refreshed: $newToken');
    
    // Send updated token to backend
    final notificationRepo = sl<NotificationRepository>();
    final platform = Platform.isIOS ? 'ios' : 'android';
    await notificationRepo.registerDevice(newToken, platform);
  };
  
  runApp(const MyApp());
}
```

---

## 🎯 Step 6: Handle Notification Navigation

### Update Firebase Messaging Service

```dart
// In lib/core/services/firebase_messaging_service.dart
import 'package:nookly/core/services/navigation_service.dart';

class FirebaseMessagingService {
  final NavigationService _navigationService;
  
  // ... existing code ...
  
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('👆 Notification tapped');
    
    final type = message.data['type'];
    
    switch (type) {
      case 'chat_message':
        final senderId = message.data['sender_id'];
        _navigationService.navigateTo('/chat', arguments: senderId);
        break;
        
      case 'new_match':
        final userId = message.data['user_id'];
        _navigationService.navigateTo('/profile', arguments: userId);
        break;
        
      case 'new_like':
        _navigationService.navigateTo('/likes');
        break;
        
      case 'profile_view':
        _navigationService.navigateTo('/profile-views');
        break;
        
      default:
        _navigationService.navigateTo('/home');
    }
  }
}
```

---

## ✅ Implementation Checklist

### Backend:
- [ ] Add `user_devices` table to database
- [ ] Create `/register-device` endpoint
- [ ] Create `/unregister-device` endpoint
- [ ] Install Firebase Admin SDK
- [ ] Download service account key
- [ ] Create NotificationService
- [ ] Integrate notifications into existing endpoints

### Flutter App:
- [ ] Create NotificationRepository
- [ ] Register FCM token on login
- [ ] Unregister FCM token on logout
- [ ] Handle token refresh
- [ ] Handle notification navigation
- [ ] Test with backend

### Testing:
- [ ] Test token registration
- [ ] Test sending notifications from backend
- [ ] Test notification tap navigation
- [ ] Test token refresh
- [ ] Test on real devices (iOS & Android)

---

## 🚀 Next Steps Summary

1. **Implement Backend API** (2-3 hours)
   - Add database schema
   - Create API endpoints
   - Set up Firebase Admin SDK

2. **Integrate with Flutter** (1-2 hours)
   - Create NotificationRepository
   - Update AuthBloc
   - Handle navigation

3. **Test End-to-End** (1 hour)
   - Test on Android
   - Test on real iPhone
   - Test all notification types

4. **Production Deployment**
   - Monitor notification delivery rates
   - Set up error tracking
   - Implement analytics

---

## 📚 Additional Resources

- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [FCM Server Integration](https://firebase.google.com/docs/cloud-messaging/server)
- [Send Notifications from Backend](https://firebase.google.com/docs/cloud-messaging/send-message)

---

Ready to implement! Let me know if you need help with any specific part! 🎉


