# Push Notifications Testing Guide

## 🎯 Getting Heads-Up Notifications (Pop on Screen)

### Android Behavior:
By default, Android notifications appear in the tray but don't pop up on screen unless they're marked as **high priority**.

---

## 📱 Test via Firebase Console (Simple Method)

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **Nookly** project
3. Navigate to **Cloud Messaging** (left menu under "Engage")

### Step 2: Create a Test Notification
1. Click **"New campaign"** → **"Firebase Notification messages"**
2. Enter:
   - **Notification title**: "New Match!"
   - **Notification text**: "You have a new match 🎉"
   - **Notification image** (optional): Add image URL

3. Click **"Send test message"**
4. Paste your **FCM token** (from app logs)
5. Click **"Test"**

### Step 3: Test Different States
- ✅ **Foreground** (app open): Check logs
- ✅ **Background** (app minimized): Should see notification
- ✅ **Terminated** (app closed): Should see notification

---

## 🚀 Test via API (Advanced Method)

### For Heads-Up Notifications, use this payload:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_DEVICE_FCM_TOKEN",
    "priority": "high",
    "notification": {
      "title": "New Match!",
      "body": "You have a new match with Sarah 🎉",
      "sound": "default",
      "android_channel_id": "high_importance_channel"
    },
    "data": {
      "type": "match",
      "user_id": "12345",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  }'
```

**Key fields for heads-up notifications:**
- `"priority": "high"` - Makes notification high priority
- `"android_channel_id": "high_importance_channel"` - Uses the high-importance channel we created

---

## 🔧 After Installing the Update

### Step 1: Rebuild the App
```bash
flutter run
```

### Step 2: Test Heads-Up Notification
1. Minimize the app (don't close it)
2. Send a test notification from Firebase Console
3. **Expected**: Notification should **pop up** on the screen (heads-up)

### Step 3: Verify Channel Settings
On your Android device:
1. Go to **Settings** → **Apps** → **Nookly**
2. Tap **Notifications**
3. You should see:
   - ✅ **Important Notifications** (HIGH importance)
   - ✅ **General Notifications** (DEFAULT importance)
4. Make sure they're enabled

---

## 📊 Notification Importance Levels

| Level | Behavior | Use Case |
|-------|----------|----------|
| **HIGH** | 🔔 Pop on screen (heads-up)<br>🔊 Sound<br>📳 Vibrate | New messages, matches, likes |
| **DEFAULT** | 📥 Appear in tray only<br>🔊 Sound<br>📳 Vibrate | General updates, reminders |
| **LOW** | 📥 Appear in tray only<br>🔇 No sound | Background sync, non-urgent |

---

## 🎨 Customize Notification Channels

You can customize channels in `MainActivity.kt`:

```kotlin
val urgentChannel = NotificationChannel(
    "urgent_messages",
    "Urgent Messages",
    NotificationManager.IMPORTANCE_HIGH
).apply {
    description = "Time-sensitive messages"
    enableLights(true)
    lightColor = Color.RED
    enableVibration(true)
    vibrationPattern = longArrayOf(0, 500, 200, 500)
    setShowBadge(true)
}
```

---

## 🔍 Troubleshooting

### Heads-up notifications still not showing?

#### Check 1: App in Focus
- Heads-up notifications **don't show** when the app sending them is in the foreground
- **Test**: Minimize the app first

#### Check 2: Do Not Disturb
- Check if "Do Not Disturb" mode is enabled
- Disable it temporarily for testing

#### Check 3: Battery Optimization
- Some devices (Samsung, Xiaomi) have aggressive battery optimization
- Go to **Settings** → **Battery** → Exclude Nookly from optimization

#### Check 4: Notification Settings
- Settings → Apps → Nookly → Notifications
- Ensure "Important Notifications" is enabled and set to "High"

#### Check 5: Android Version
- Heads-up notifications work best on **Android 8.0+**
- Older versions may have limited support

---

## 💡 Best Practices

### 1. Use High Priority Sparingly
Only use `high_importance_channel` for:
- ✅ New messages from matches
- ✅ New matches
- ✅ New likes/super likes
- ✅ Time-sensitive events

### 2. Use Default Priority For
- General app updates
- Daily reminders
- Non-urgent notifications

### 3. User Control
Let users customize which notifications are high priority in app settings:

```dart
// Example settings
class NotificationPreferences {
  bool messagesHighPriority = true;
  bool matchesHighPriority = true;
  bool likesHighPriority = false;
  bool generalHighPriority = false;
}
```

---

## 📱 Testing Checklist

- [ ] Rebuild app with new notification channels
- [ ] Test notification in **foreground** (app open)
- [ ] Test notification in **background** (app minimized)
- [ ] Test notification when app is **terminated** (closed)
- [ ] Verify heads-up notification appears
- [ ] Test notification tap (opens correct screen)
- [ ] Test on both **WiFi** and **mobile data**
- [ ] Test on different Android versions
- [ ] Test iOS device (different behavior)

---

## 🍎 iOS Behavior (Different from Android)

On iOS, notifications behavior is simpler:
- **Foreground**: You control display (via your code)
- **Background/Terminated**: Always shows banner + sound (if permitted)
- **No channel system** like Android
- User controls all settings in iOS Settings app

---

## 📞 Support

If you still have issues:
1. Check FCM token is valid (fresh from logs)
2. Verify Firebase project settings
3. Check server key in Firebase Console
4. Review device notification settings
5. Test on different devices

---

## 🎯 Next Steps

1. **Rebuild and test** the updated app
2. **Configure backend** to send high-priority notifications
3. **Add custom notification handling** for different types
4. **Test on production** before release


