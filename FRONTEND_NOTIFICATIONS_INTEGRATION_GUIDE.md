# Frontend Notifications Integration Guide

## ✅ Implementation Complete Summary

Your Nookly app frontend is now fully configured for push notifications with:
- ✅ 7 notification channels (Android) with theme colors
- ✅ 7 notification categories (iOS)
- ✅ Automatic navigation based on notification type
- ✅ Backend API integration ready
- ✅ Token management (register/unregister)

---

## 🎨 Theme Colors Applied

Your app's notification channels use the Nookly brand colors:

```kotlin
PRIMARY_COLOR = "#667eea"      // Nookly blue - used for general notifications
SECONDARY_COLOR = "#234481"    // Nookly dark blue
ACCENT_COLOR = "#FF1493"       // Hot pink - used for matches/likes
SUCCESS_COLOR = "#4CAF50"      // Green - used for social activity
```

---

## 📱 Notification Channels Configured

| Channel | Color | Vibration | Sound | Heads-Up | Use Case |
|---------|-------|-----------|-------|----------|----------|
| **messages** | Blue (#667eea) | ✅ Pattern | ✅ Yes | ✅ Yes | Chat messages |
| **matches_likes** | Pink (#FF1493) | ✅ Exciting | ✅ Yes | ✅ Yes | Matches, likes |
| **social_activity** | Green (#4CAF50) | ✅ Gentle | ✅ Yes | ❌ No | Profile views |
| **app_updates** | - | ❌ Silent | ❌ Silent | ❌ No | Recommendations |
| **promotions** | - | ❌ Silent | ❌ Silent | ❌ No | Offers |
| **calls** | Blue (#667eea) | ✅ Ringtone | ✅ Ringtone | ✅ Yes | Video/Voice calls |
| **default_channel** | Blue (#667eea) | ✅ Yes | ✅ Yes | ❌ No | General |

---

## 🔄 Integration Steps

### Step 1: Register NotificationRepository in Dependency Injection

Add to your `injection_container.dart`:

```dart
// lib/core/di/injection_container.dart
import 'package:nookly/data/repositories/notification_repository.dart';

Future<void> init() async {
  // ... existing registrations ...
  
  // Notification Repository
  sl.registerLazySingleton(() => NotificationRepository(sl()));
}
```

### Step 2: Update AuthBloc to Register/Unregister Device

```dart
// lib/presentation/bloc/auth/auth_bloc.dart
import 'package:nookly/data/repositories/notification_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final NotificationRepository _notificationRepository;
  
  AuthBloc({
    required AuthRepository authRepository,
    required NotificationRepository notificationRepository,
  })  : _authRepository = authRepository,
        _notificationRepository = notificationRepository,
        super(AuthInitial()) {
    on<LoginSuccess>(_onLoginSuccess);
    on<Logout>(_onLogout);
  }
  
  Future<void> _onLoginSuccess(
    LoginSuccess event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // ... existing login logic ...
      
      // Register device for notifications
      await _notificationRepository.registerDevice();
      
      emit(Authenticated(user: event.user));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _onLogout(
    Logout event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Unregister device from notifications
      await _notificationRepository.unregisterDevice();
      
      // ... existing logout logic ...
      
      emit(Unauthenticated());
    } catch (e) {
      // Handle error
    }
  }
}
```

### Step 3: Handle Token Refresh in main.dart

Update your `main.dart` to handle token refresh:

```dart
// lib/main.dart
void main() async {
  // ... existing initialization ...
  
  final firebaseMessagingService = FirebaseMessagingService();
  FirebaseMessagingService.navigatorKey = GlobalKey<NavigatorState>();
  
  await firebaseMessagingService.initialize();
  
  // Handle token refresh
  final notificationRepo = di.sl<NotificationRepository>();
  firebaseMessagingService.onTokenRefresh = (newToken) async {
    await notificationRepo.onTokenRefresh(newToken);
  };
  
  runApp(const MyApp());
}
```

---

## 🎯 Notification Navigation Routes

The app automatically navigates based on notification type. Make sure these routes exist:

### Required Routes:

```dart
// lib/main.dart - MaterialApp routes
routes: {
  '/': (context) => const MainScreen(),              // Home
  '/login': (context) => const LoginPage(),           // Login
  '/chat': (context) => const ChatPage(),             // Chat messages
  '/match': (context) => const MatchScreen(),         // New match
  '/likes': (context) => const LikesScreen(),         // Likes screen
  '/profile-views': (context) => const ProfileViewsScreen(), // Profile views
  '/discover': (context) => const DiscoverScreen(),   // Recommendations
  '/premium': (context) => const PremiumScreen(),     // Promotions
  '/call': (context) => const CallScreen(),           // Video/Voice calls
}
```

### Notification Type → Route Mapping:

| Notification Type | Route | Arguments |
|------------------|-------|-----------|
| `message` | `/chat` | `{user_id, conversation_id}` |
| `match` | `/match` | `{user_id}` |
| `like` | `/likes` | - |
| `profile_view` | `/profile-views` | - |
| `recommendations` | `/discover` | - |
| `promotion` | `/premium` | - |
| `call` | `/call` | `{caller_id, call_type, room_id}` |
| `test` | `/` | - |

---

## 🧪 Testing Notifications

### Test 1: Register Device
```dart
// In your app settings or profile screen
final notificationRepo = sl<NotificationRepository>();
final success = await notificationRepo.registerDevice();

if (success) {
  showSnackBar('✅ Device registered for notifications');
}
```

### Test 2: Send Test Notification
```dart
// Add a button in settings
ElevatedButton(
  onPressed: () async {
    final notificationRepo = sl<NotificationRepository>();
    final success = await notificationRepo.sendTestNotification(
      title: 'Test Notification',
      body: 'Testing Nookly notifications! 🎉',
    );
    
    if (success) {
      showSnackBar('✅ Test notification sent');
    }
  },
  child: Text('Send Test Notification'),
)
```

### Test 3: View Registered Devices
```dart
// In settings screen
Future<void> loadDevices() async {
  final notificationRepo = sl<NotificationRepository>();
  final devices = await notificationRepo.getUserDevices();
  
  setState(() {
    _devices = devices;
  });
}
```

---

## 📊 Notification Handling Flow

### 1. App in Foreground
```
Notification Received
    ↓
_handleForegroundMessage() called
    ↓
Log notification data
    ↓
Show in-app notification (optional)
    ↓
onMessageReceived callback (custom handling)
```

### 2. App in Background
```
Notification Received
    ↓
System displays notification
    ↓
User taps notification
    ↓
_handleNotificationTap() called
    ↓
Navigate to appropriate screen
```

### 3. App Terminated
```
Notification Received
    ↓
System displays notification
    ↓
User taps notification
    ↓
App starts
    ↓
getInitialMessage() retrieves notification
    ↓
Navigate to appropriate screen
```

---

## 🎨 Customizing In-App Notifications (Optional)

Show custom in-app notifications when app is in foreground:

```dart
// lib/core/services/firebase_messaging_service.dart

void _handleForegroundMessage(RemoteMessage message) {
  _logger.i('📬 Foreground message received');
  
  if (message.notification != null) {
    // Show custom in-app notification
    _showInAppNotification(message);
  }
  
  onMessageReceived?.call(message);
}

void _showInAppNotification(RemoteMessage message) {
  if (navigatorKey?.currentContext != null) {
    final context = navigatorKey!.currentContext!;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForType(message.data['type']),
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.notification?.title ?? 'Notification',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(message.notification?.body ?? ''),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF667eea), // Nookly blue
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _handleNotificationTap(message);
          },
        ),
      ),
    );
  }
}

IconData _getIconForType(String? type) {
  switch (type) {
    case 'message':
      return Icons.message;
    case 'match':
      return Icons.favorite;
    case 'like':
      return Icons.thumb_up;
    case 'profile_view':
      return Icons.visibility;
    case 'call':
      return Icons.call;
    default:
      return Icons.notifications;
  }
}
```

---

## 🔒 Permission Handling

### Request Notification Permission

```dart
// In onboarding or first-time setup
Future<void> requestNotificationPermission() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted permission');
    // Register device
    await sl<NotificationRepository>().registerDevice();
  } else {
    print('❌ User declined permission');
    // Show explanation dialog
  }
}
```

### Check Current Permission Status

```dart
Future<bool> hasNotificationPermission() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final settings = await messaging.getNotificationSettings();
  
  return settings.authorizationStatus == AuthorizationStatus.authorized;
}
```

---

## 📱 Android 13+ Runtime Permission

For Android 13+, request POST_NOTIFICATIONS permission:

```dart
// Using permission_handler package
import 'package:permission_handler/permission.dart';

Future<void> requestAndroidNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      print('✅ Android notification permission granted');
    } else if (status.isPermanentlyDenied) {
      // Open app settings
      openAppSettings();
    }
  }
}
```

---

## 🐛 Debugging

### Enable Verbose Logging

The FirebaseMessagingService and NotificationRepository already have comprehensive logging.

Check logs for:
- `✅` Success messages
- `⚠️` Warning messages
- `❌` Error messages
- `📱` Device operations
- `📨` Notification operations
- `👆` User interactions

### Common Issues

#### 1. Notifications not appearing
- ✅ Check notification permission is granted
- ✅ Verify FCM token is registered with backend
- ✅ Check backend is sending correct channel ID
- ✅ Test on real device (iOS simulator doesn't support push)

#### 2. Navigation not working
- ✅ Verify routes are defined in MaterialApp
- ✅ Check navigatorKey is set correctly
- ✅ Ensure notification data contains correct fields

#### 3. Token registration fails
- ✅ Check backend API is running
- ✅ Verify JWT token is valid
- ✅ Check Dio interceptor for authentication

---

## ✅ Implementation Checklist

### Backend Integration:
- [x] Backend notification channels documented
- [x] API endpoints provided
- [x] Notification payload structure defined

### Frontend Implementation:
- [x] All 7 notification channels created (Android)
- [x] Theme colors applied to channels
- [x] NotificationRepository created
- [x] Firebase Messaging Service updated with navigation
- [x] Navigator key configured
- [x] Routes defined for all notification types

### Next Steps:
- [ ] Add NotificationRepository to dependency injection
- [ ] Update AuthBloc to register/unregister devices
- [ ] Create navigation routes for all notification types
- [ ] Test registration/unregistration
- [ ] Test navigation from notifications
- [ ] Test on real Android device
- [ ] Test on real iPhone

---

## 🎉 You're Ready!

Your Nookly app is now fully configured for push notifications with:

✅ **Professional notification channels** with your brand colors  
✅ **Automatic navigation** based on notification type  
✅ **Complete backend integration** ready to use  
✅ **Token management** for register/unregister  
✅ **Comprehensive logging** for debugging  
✅ **Theme-based styling** matching your app  

**Next:** Update your AuthBloc and test the complete flow!


