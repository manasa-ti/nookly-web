# Notification Navigation - Complete Solution

## 🔍 Issue Identified

When tapping a message notification, navigation fails because:
1. `ChatPage` requires: `conversationId`, `participantName`, `participantAvatar`, `isOnline`, `lastSeen`, `connectionStatus`
2. Notification only has: `sender_id`, `conversation_id`
3. App uses `MaterialPageRoute`, not named routes

## ✅ Solution: Enhanced Backend Payload

### Current Backend Payload (Incomplete):
```json
{
  "data": {
    "type": "message",
    "sender_id": "123",
    "conversation_id": "conv_456"
  }
}
```

### ✨ Updated Backend Payload (Complete):
```json
{
  "data": {
    "type": "message",
    "sender_id": "123",
    "conversation_id": "conv_456",
    "sender_name": "John Doe",
    "sender_avatar": "https://example.com/avatar.jpg",
    "is_online": "true",
    "last_seen": "2025-10-08T10:30:00Z"
  }
}
```

---

## 🔧 Backend Update Required

Update your notification service to include participant details:

```javascript
// Backend: services/notificationService.js

async sendMessageNotification(recipientId, senderName, messageText, senderId, conversationId) {
  // Fetch sender details
  const sender = await db.query(
    'SELECT id, name, profile_picture, is_online, last_seen FROM users WHERE id = $1',
    [senderId]
  );
  
  const senderData = sender.rows[0];
  
  return await this.sendToUser(recipientId, {
    title: senderName,
    body: messageText.substring(0, 100),
    priority: 'high',
    category: 'MESSAGE',
    data: {
      type: 'message',
      sender_id: senderId.toString(),
      conversation_id: conversationId.toString(),
      // ADD THESE FIELDS:
      sender_name: senderData.name,
      sender_avatar: senderData.profile_picture || '',
      is_online: senderData.is_online ? 'true' : 'false',
      last_seen: senderData.last_seen?.toISOString() || '',
    },
    android: {
      channelId: 'messages',
      color: '#667eea',
      tag: `conv_${conversationId}`
    }
  });
}
```

---

## 📱 Frontend: Updated Navigation Handler

```dart
// lib/core/services/firebase_messaging_service.dart

import 'package:nookly/presentation/pages/chat/chat_page.dart';

/// Navigate to chat screen with full participant data
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
  
  try {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: senderId, // ChatPage uses participantId as conversationId
          participantName: senderName,
          participantAvatar: senderAvatar,
          isOnline: isOnline,
          lastSeen: lastSeen,
          connectionStatus: isOnline ? 'online' : null,
        ),
      ),
    );
  } catch (e) {
    _logger.e('❌ Error navigating to chat: $e');
  }
}
```

---

## 🎯 Quick Fix for Now

**Current implementation** navigates to inbox/home. This works but isn't ideal.

**To enable direct chat navigation:**
1. Update backend to send participant details in notification
2. Update frontend navigation handler (code above)
3. Import ChatPage in firebase_messaging_service.dart

---

## 💡 Alternative: Fetch User Data Before Navigation

If you can't update backend immediately:

```dart
/// Navigate to chat with data fetching
void _navigateToChat(Map<String, dynamic> data) async {
  final senderId = data['sender_id'];
  
  if (navigatorKey?.currentContext == null) return;
  
  final context = navigatorKey!.currentContext!;
  
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );
  
  try {
    // Fetch user details
    final response = await NetworkService.dio.get('/users/$senderId');
    final userData = response.data;
    
    // Close loading
    Navigator.of(context).pop();
    
    // Navigate to chat
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: senderId,
          participantName: userData['name'] ?? 'User',
          participantAvatar: userData['profilePicture'],
          isOnline: userData['isOnline'] ?? false,
          lastSeen: userData['lastSeen'],
          connectionStatus: userData['isOnline'] ? 'online' : null,
        ),
      ),
    );
  } catch (e) {
    // Close loading
    Navigator.of(context).pop();
    _logger.e('❌ Error loading user data: $e');
    
    // Fallback: navigate to inbox
    _navigateToInbox();
  }
}
```

---

## ✅ Recommended Approach

**Best solution:** Update backend to include participant details in notification payload.

**Pros:**
- ✅ Instant navigation (no loading)
- ✅ No extra API call
- ✅ Better UX
- ✅ Works offline if app cache has data

**Implementation time:** ~10 minutes (backend update)

---

## 🧪 Testing After Fix

1. Send message notification with full payload
2. Tap notification
3. Expected: Opens directly to chat screen
4. User can immediately read and reply

---

Would you like me to:
1. **Implement the fetch-data approach** (works now, adds loading)
2. **Wait for backend update** (better UX, cleaner code)
3. **Keep current solution** (navigates to inbox, simple)


