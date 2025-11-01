# Analytics Events Tracking

This document lists all analytics events currently tracked in the app and how to view them in Firebase Analytics.

## 📊 Custom Events Tracked

### Authentication Events
- **`login`** - Tracks user login
  - Parameters: `method` ('email' or 'google')
  - Triggered: When user successfully logs in via email or Google

- **`sign_up`** - Tracks user signup
  - Parameters: `method` ('email' or 'otp')
  - Triggered: When user successfully signs up via email or OTP verification

- **`logout`** - Tracks user logout
  - Triggered: When user logs out

### Engagement Events
- **`match`** - Tracks when users match
  - Parameters: `match_id` (the like/conversation ID)
  - Triggered: When user accepts a received like

- **`message_sent`** - Tracks message sending
  - Parameters: 
    - `conversation_id` (optional)
    - `message_type` ('text', 'image', or 'voice')
  - Triggered: When user sends a text, image, or voice message

### Screen Tracking
- **`screen_view`** - Custom event for screen views (logged in addition to Firebase's standard screen_view)
  - Parameters: `screen_name` (the formatted screen name, e.g., 'chat_page', 'profile_hub')
  - Triggered: Automatically via `AnalyticsRouteObserver` on all navigation
  - Also tracked via Firebase's standard `logScreenView()` API

## 🔍 How to View Events in Firebase Analytics

### In Firebase Console:

1. **Navigate to Analytics Dashboard**
   - Go to Firebase Console → Your Project → Analytics → Events

2. **View All Events**
   - All custom events appear in the "Events" section
   - Standard Firebase events (first_open, session_start, user_engagement, screen_view) appear automatically

3. **Event Delay**
   - ⚠️ **Important**: Custom events can take 24-48 hours to appear in the dashboard
   - Real-time events can be viewed in "DebugView" (see below)

4. **View Screen Names**
   - Screen views appear in the "Screen views" section
   - Custom `screen_view` events with `screen_name` parameter show up in Events tab
   - You can filter by `screen_name` parameter to see individual screens

### Debug View (Real-time Testing)

To see events in real-time during development:

1. **Enable Debug Mode** (Android):
   ```bash
   adb shell setprop debug.firebase.analytics.app com.nookly.app
   ```

2. **Enable Debug Mode** (iOS):
   - In Xcode: Edit Scheme → Run → Arguments
   - Add: `-FIRDebugEnabled`

3. **View in Firebase Console**
   - Go to Analytics → DebugView
   - Events appear in real-time (no delay)

### Where Events Are Logged

- **Authentication Events**: `lib/presentation/bloc/auth/auth_bloc.dart`
- **Match Events**: `lib/presentation/bloc/received_likes/received_likes_bloc.dart`
- **Message Events**: `lib/presentation/bloc/conversation/conversation_bloc.dart`
- **Screen Views**: `lib/core/services/analytics_route_observer.dart` (automatic)

## 🐛 Troubleshooting

### Events Not Appearing?

1. **Check Logs**: Look for `📊 Analytics event logged:` messages in app logs
2. **Wait Time**: Events can take 24-48 hours in production; use DebugView for immediate testing
3. **Verify Firebase Config**: Ensure correct `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in place
4. **Check Environment**: Make sure you're viewing the correct Firebase project (dev vs production)

### Screen Names Not Showing?

1. **Route Names**: Ensure routes have proper names when using `Navigator.push()`
2. **Check Logs**: Look for `📊 Analytics: Screen view - <screen_name>` in app logs
3. **Route Observer**: Verify `AnalyticsRouteObserver` is registered in `MaterialApp.navigatorObservers`

## 📱 Current Status

**Active Events (Currently Tracked)**:
- ✅ login
- ✅ sign_up  
- ✅ logout
- ✅ match
- ✅ message_sent
- ✅ screen_view (automatic + custom)

**Available but Not Yet Implemented**:
- ⏳ profile_viewed
- ⏳ swipe_action
- ⏳ purchase
- ⏳ feature_used
- ⏳ api_error

## 🔄 Performance Tracking

- **App Startup Time**: Tracked automatically via Firebase Performance
- **Network Requests**: All API calls are tracked with duration, status codes, and payload sizes
- **Custom Traces**: Can be added for specific user flows

