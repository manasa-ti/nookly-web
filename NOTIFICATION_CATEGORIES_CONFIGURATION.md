# Notification Categories Configuration for Nookly Dating App

## 🎯 Recommended Notification Types

For a dating app like Nookly, I recommend **5 main notification categories** with different priority levels:

| Category | Priority | Use Case | User Impact |
|----------|----------|----------|-------------|
| **1. Messages** | HIGH | New chat messages | Immediate, time-sensitive |
| **2. Matches & Likes** | HIGH | New matches, likes, super likes | Exciting, important |
| **3. Social Activity** | MEDIUM | Profile views, who's interested | Informative, engaging |
| **4. App Updates** | MEDIUM | Features, tips, reminders | Helpful, not urgent |
| **5. Promotions** | LOW | Deals, events, premium features | Optional, can wait |

---

## 📱 Android: Notification Channels Configuration

### Step 1: Update MainActivity.kt

Replace the current `createNotificationChannels()` method with this comprehensive version:

```kotlin
// android/app/src/main/kotlin/com/nookly/app/MainActivity.kt
package com.nookly.app

import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // Create channel groups for better organization
            createChannelGroups(notificationManager)
            
            // Create individual channels
            createMessagesChannel(notificationManager)
            createMatchesAndLikesChannel(notificationManager)
            createSocialActivityChannel(notificationManager)
            createAppUpdatesChannel(notificationManager)
            createPromotionsChannel(notificationManager)
        }
    }
    
    private fun createChannelGroups(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Group 1: Core Dating Features
            val coreGroup = NotificationChannelGroup(
                "core_features",
                "Dating Features"
            )
            
            // Group 2: Engagement
            val engagementGroup = NotificationChannelGroup(
                "engagement",
                "Engagement & Updates"
            )
            
            notificationManager.createNotificationChannelGroups(listOf(coreGroup, engagementGroup))
        }
    }
    
    /**
     * Channel 1: Messages (CRITICAL)
     * - New chat messages
     * - Voice messages
     * - Photo shares
     */
    private fun createMessagesChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "messages",
                "Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "New messages from your matches"
                group = "core_features"
                
                // Visual settings
                enableLights(true)
                lightColor = Color.parseColor("#667eea") // Nookly primary color
                
                // Sound settings
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250) // Short, attention-grabbing
                
                // Badge
                setShowBadge(true)
                
                // Lock screen
                lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
                
                // Sound
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_COMMUNICATION_INSTANT)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Channel 2: Matches & Likes (HIGH PRIORITY)
     * - New matches
     * - New likes
     * - Super likes
     * - Mutual interests
     */
    private fun createMatchesAndLikesChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "matches_likes",
                "Matches & Likes",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "New matches, likes, and super likes"
                group = "core_features"
                
                // Visual settings
                enableLights(true)
                lightColor = Color.parseColor("#FF1493") // Hot pink for romance
                
                // Sound settings
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 100, 100, 100, 100, 100) // Exciting pattern
                
                // Badge
                setShowBadge(true)
                
                // Lock screen
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC // Can show
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Channel 3: Social Activity (MEDIUM PRIORITY)
     * - Profile views
     * - Who's interested
     * - Profile completion tips
     * - Ice breaker suggestions
     */
    private fun createSocialActivityChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "social_activity",
                "Social Activity",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Profile views, interests, and social updates"
                group = "engagement"
                
                // Visual settings
                enableLights(true)
                lightColor = Color.parseColor("#4CAF50") // Green for positive
                
                // Sound settings - subtle
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 200) // Single gentle vibration
                
                // Badge
                setShowBadge(true)
                
                // Lock screen
                lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Channel 4: App Updates (MEDIUM PRIORITY)
     * - Daily recommendations
     * - Activity reminders
     * - Feature announcements
     * - Tips and tricks
     */
    private fun createAppUpdatesChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "app_updates",
                "App Updates & Tips",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Daily recommendations, reminders, and helpful tips"
                group = "engagement"
                
                // Visual settings
                enableLights(false) // No lights for updates
                
                // Sound settings - silent by default
                enableVibration(false)
                setSound(null, null) // Silent
                
                // Badge
                setShowBadge(true)
                
                // Lock screen
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Channel 5: Promotions (LOW PRIORITY)
     * - Premium features
     * - Special offers
     * - Events
     * - Boost promotions
     */
    private fun createPromotionsChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "promotions",
                "Promotions & Offers",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Special offers, premium features, and events"
                group = "engagement"
                
                // Visual settings - minimal
                enableLights(false)
                
                // Sound settings - silent
                enableVibration(false)
                setSound(null, null)
                
                // Badge
                setShowBadge(false) // Don't add to badge count
                
                // Lock screen
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
}
```

---

## 🍎 iOS: Notification Categories Configuration

### Step 1: Update AppDelegate.swift

```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import Firebase
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Configure notification categories
        configureNotificationCategories()
        
        // Request notification permissions
        requestNotificationPermissions(application)
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func configureNotificationCategories() {
        // Category 1: Message Notifications with Actions
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [.authenticationRequired],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a message..."
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_MESSAGE",
            title: "View",
            options: [.foreground]
        )
        
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE",
            actions: [replyAction, viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Category 2: Match Notifications with Actions
        let sayHiAction = UNNotificationAction(
            identifier: "SAY_HI",
            title: "Say Hi! 👋",
            options: [.foreground]
        )
        
        let viewProfileAction = UNNotificationAction(
            identifier: "VIEW_PROFILE",
            title: "View Profile",
            options: [.foreground]
        )
        
        let matchCategory = UNNotificationCategory(
            identifier: "MATCH",
            actions: [sayHiAction, viewProfileAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Category 3: Like Notifications
        let likeBackAction = UNNotificationAction(
            identifier: "LIKE_BACK",
            title: "Like Back ❤️",
            options: []
        )
        
        let viewLikerAction = UNNotificationAction(
            identifier: "VIEW_LIKER",
            title: "View",
            options: [.foreground]
        )
        
        let likeCategory = UNNotificationCategory(
            identifier: "LIKE",
            actions: [likeBackAction, viewLikerAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Category 4: Social Activity (View only)
        let socialCategory = UNNotificationCategory(
            identifier: "SOCIAL",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Category 5: Promotions (Dismissible)
        let promotionCategory = UNNotificationCategory(
            identifier: "PROMOTION",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register all categories
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([
            messageCategory,
            matchCategory,
            likeCategory,
            socialCategory,
            promotionCategory
        ])
    }
    
    private func requestNotificationPermissions(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { granted, error in
                    if granted {
                        print("✅ Notification permission granted")
                    } else {
                        print("❌ Notification permission denied")
                    }
                }
            )
        }
        
        application.registerForRemoteNotifications()
    }
    
    // Handle notification actions
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Handle different actions
        switch actionIdentifier {
        case "REPLY_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                handleReply(text: textResponse.userText, userInfo: userInfo)
            }
            
        case "VIEW_MESSAGE", "VIEW_PROFILE", "VIEW_LIKER":
            handleViewAction(userInfo: userInfo)
            
        case "SAY_HI":
            handleSayHi(userInfo: userInfo)
            
        case "LIKE_BACK":
            handleLikeBack(userInfo: userInfo)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleReply(text: String, userInfo: [AnyHashable: Any]) {
        // Send reply to backend
        print("Reply: \(text)")
    }
    
    private func handleViewAction(userInfo: [AnyHashable: Any]) {
        // Open specific screen
        print("View action triggered")
    }
    
    private func handleSayHi(userInfo: [AnyHashable: Any]) {
        // Send quick greeting
        print("Say Hi triggered")
    }
    
    private func handleLikeBack(userInfo: [AnyHashable: Any]) {
        // Like back the user
        print("Like back triggered")
    }
}
```

---

## 🔧 Backend: Sending Notifications with Categories

### Updated NotificationService with Categories

```javascript
// services/notificationService.js

class NotificationService {
  
  /**
   * Send message notification
   */
  async sendMessageNotification(recipientId, senderName, messageText, senderId, conversationId) {
    return await this.sendToUser(recipientId, {
      title: senderName,
      body: messageText.substring(0, 100),
      imageUrl: await this.getUserProfilePicture(senderId),
      priority: 'high',
      category: 'MESSAGE', // iOS category
      data: {
        type: 'message',
        sender_id: senderId.toString(),
        conversation_id: conversationId.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        channelId: 'messages', // Android channel
        priority: 'high',
        notification: {
          channelId: 'messages',
          sound: 'default',
          priority: 'high',
          tag: `message_${conversationId}`, // Group messages by conversation
          color: '#667eea'
        }
      }
    });
  }
  
  /**
   * Send match notification
   */
  async sendMatchNotification(userId, matchedUserName, matchedUserId) {
    return await this.sendToUser(userId, {
      title: "It's a Match! 🎉",
      body: `You and ${matchedUserName} liked each other!`,
      imageUrl: await this.getUserProfilePicture(matchedUserId),
      priority: 'high',
      category: 'MATCH', // iOS category
      data: {
        type: 'match',
        user_id: matchedUserId.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        channelId: 'matches_likes', // Android channel
        priority: 'high',
        notification: {
          channelId: 'matches_likes',
          sound: 'default',
          priority: 'high',
          color: '#FF1493'
        }
      }
    });
  }
  
  /**
   * Send like notification
   */
  async sendLikeNotification(userId, likerName, likerId) {
    return await this.sendToUser(userId, {
      title: 'New Like! ❤️',
      body: `${likerName} liked your profile`,
      imageUrl: await this.getUserProfilePicture(likerId),
      priority: 'high',
      category: 'LIKE', // iOS category
      data: {
        type: 'like',
        liker_id: likerId.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        channelId: 'matches_likes',
        priority: 'high',
        notification: {
          channelId: 'matches_likes',
          sound: 'default',
          priority: 'high',
          color: '#FF1493'
        }
      }
    });
  }
  
  /**
   * Send profile view notification
   */
  async sendProfileViewNotification(userId, viewerName, viewerId) {
    return await this.sendToUser(userId, {
      title: 'Someone viewed your profile 👀',
      body: `${viewerName} checked out your profile`,
      priority: 'default',
      category: 'SOCIAL',
      data: {
        type: 'profile_view',
        viewer_id: viewerId.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        channelId: 'social_activity',
        notification: {
          channelId: 'social_activity',
          sound: 'default',
          color: '#4CAF50'
        }
      }
    });
  }
  
  /**
   * Send daily recommendations
   */
  async sendDailyRecommendations(userId, count) {
    return await this.sendToUser(userId, {
      title: 'New Profiles to Discover! 🔥',
      body: `${count} new people nearby match your preferences`,
      priority: 'default',
      category: 'SOCIAL',
      data: {
        type: 'recommendations',
        count: count.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        channelId: 'app_updates',
        notification: {
          channelId: 'app_updates',
          color: '#667eea'
        }
      }
    });
  }
  
  /**
   * Send promotion notification
   */
  async sendPromotionNotification(userId, title, message, promoType) {
    return await this.sendToUser(userId, {
      title: title,
      body: message,
      priority: 'low',
      category: 'PROMOTION',
      data: {
        type: 'promotion',
        promo_type: promoType,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        channelId: 'promotions',
        notification: {
          channelId: 'promotions',
          color: '#667eea'
        }
      }
    });
  }
  
  /**
   * Helper: Get user profile picture URL
   */
  async getUserProfilePicture(userId) {
    // Fetch from database
    const user = await db.query('SELECT profile_picture_url FROM users WHERE id = $1', [userId]);
    return user.rows[0]?.profile_picture_url || null;
  }
}

module.exports = new NotificationService();
```

---

## 📊 Channel Configuration Summary

### Android Channels

| Channel ID | Name | Importance | Heads-Up | Sound | Vibration | Badge | Use Case |
|------------|------|------------|----------|-------|-----------|-------|----------|
| `messages` | Messages | HIGH | ✅ Yes | ✅ Yes | ✅ Pattern | ✅ Yes | Chat messages |
| `matches_likes` | Matches & Likes | HIGH | ✅ Yes | ✅ Yes | ✅ Pattern | ✅ Yes | Matches, likes |
| `social_activity` | Social Activity | DEFAULT | ❌ No | ✅ Yes | ✅ Simple | ✅ Yes | Profile views |
| `app_updates` | App Updates | DEFAULT | ❌ No | ❌ Silent | ❌ No | ✅ Yes | Recommendations |
| `promotions` | Promotions | LOW | ❌ No | ❌ Silent | ❌ No | ❌ No | Offers, events |

### iOS Categories

| Category | Actions | Use Case |
|----------|---------|----------|
| `MESSAGE` | Reply (text input), View | Chat messages |
| `MATCH` | Say Hi, View Profile | New matches |
| `LIKE` | Like Back, View | New likes |
| `SOCIAL` | View | Profile views, activity |
| `PROMOTION` | (Dismissible) | Promotions |

---

## 🎨 User Preferences (Optional Enhancement)

Allow users to customize notification settings:

```dart
// lib/data/models/notification_preferences.dart
class NotificationPreferences {
  bool messagesEnabled;
  bool matchesEnabled;
  bool likesEnabled;
  bool profileViewsEnabled;
  bool recommendationsEnabled;
  bool promotionsEnabled;
  
  // Quiet hours
  bool quietHoursEnabled;
  TimeOfDay? quietHoursStart;
  TimeOfDay? quietHoursEnd;
  
  // Sound settings
  bool soundEnabled;
  bool vibrationEnabled;
  
  NotificationPreferences({
    this.messagesEnabled = true,
    this.matchesEnabled = true,
    this.likesEnabled = true,
    this.profileViewsEnabled = true,
    this.recommendationsEnabled = true,
    this.promotionsEnabled = false, // Off by default
    this.quietHoursEnabled = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });
}
```

---

## ✅ Implementation Checklist

### Android:
- [ ] Update `MainActivity.kt` with all 5 channels
- [ ] Test each channel by sending notifications
- [ ] Verify heads-up notifications for high priority
- [ ] Check notification grouping
- [ ] Test channel settings in Android Settings

### iOS:
- [ ] Update `AppDelegate.swift` with categories
- [ ] Implement action handlers
- [ ] Test notification actions on real device
- [ ] Verify category associations

### Backend:
- [ ] Update notification service with channel IDs
- [ ] Add category field to iOS payloads
- [ ] Test each notification type
- [ ] Verify correct channels/categories are used

### Testing:
- [ ] Send test notification for each type
- [ ] Verify priority levels work correctly
- [ ] Test on both Android and iOS
- [ ] Check user experience (sounds, vibrations, heads-up)

---

## 🎯 Best Practices

1. **Keep it Simple**: 5 categories is optimal - not too few, not too many
2. **Clear Names**: Users should understand what each category is for
3. **Respect Priority**: Don't overuse HIGH priority
4. **Silent Promotions**: Marketing notifications should be subtle
5. **Group Related**: Use channel groups on Android for organization
6. **Test Thoroughly**: Each category should feel appropriate for its content

---

## 📈 Recommended Usage

### Daily Distribution:
- **Messages**: 0-50 per day (user-generated)
- **Matches & Likes**: 0-10 per day
- **Social Activity**: 0-20 per day
- **App Updates**: 0-2 per day (max!)
- **Promotions**: 0-1 per day (max!)

### Priority Guidelines:
- Use HIGH only for time-sensitive, user-expected notifications
- Use MEDIUM for informative but not urgent updates
- Use LOW for optional content

---

Your notification system is now professionally configured with appropriate categories for a dating app! 🎉


