# Messaging Debug Guide

## 🔍 **Issue: Messages Not Being Sent/Received**

If you're not seeing `private_message` events in the logs, follow this debugging guide:

## 📋 **Debugging Checklist**

### **1. Check Socket Connection**
Look for these logs in the console:
```
🔵 Initializing socket and user
🔵 User: [user_id]
🔵 Token available: true
🔵 Socket service created
🔵 Key management service created
🔵 Connecting to socket: wss://dev.nookly.app
🔵 Socket connected: true
🔵 Socket ID: [socket_id]
🔵 Joining private chat room: [conversation_id]
🔵 Socket listeners registered
```

### **2. Check Message Sending**
When sending a message, look for:
```
🔵 Attempting to send message to: [conversation_id]
🔵 Socket connected: true
🔵 Current user ID: [user_id]
🔵 sendEncryptedMessage called
🔵 Getting conversation key for: [receiver_id]
🔵 Got encryption key: [key_prefix]...
🔵 Encrypting message
🔵 Message encrypted successfully
🔵 Sending encrypted message to: [receiver_id]
🔵 Message data: {...}
✅ Encrypted message emitted successfully
```

### **3. Check Message Receiving**
When receiving a message, look for:
```
🔵 Processing new message in inbox from: [sender_name]
🔵 Message data: {...}
```

## 🚨 **Common Issues & Solutions**

### **Issue 1: Socket Not Connecting**
**Symptoms:**
- No "Socket connected: true" log
- "Socket not connected after initialization" error

**Solutions:**
1. Check network connectivity
2. Verify server URL is correct
3. Check authentication token
4. Ensure backend is running

### **Issue 2: Key Management Service Failing**
**Symptoms:**
- "Error getting conversation key" logs
- "Key management service not available" errors

**Solutions:**
1. Backend E2EE endpoints might not be implemented yet
2. The app will fallback to local key generation for testing
3. Check if backend has `/api/conversation-keys/` endpoints

### **Issue 3: E2EE Encryption Failing**
**Symptoms:**
- "Failed to send encrypted message" errors
- "Error encrypting message" logs

**Solutions:**
1. The app will automatically fallback to regular messaging
2. Check if crypto/encrypt packages are properly installed
3. Verify E2EE utils are working (tests should pass)

### **Issue 4: No private_message Events**
**Symptoms:**
- No "private_message" events in logs
- Messages not appearing in chat

**Solutions:**
1. Check if socket is properly connected
2. Verify you're in the correct chat room
3. Check if backend is handling the events
4. Try sending a test message (see below)

## 🧪 **Testing Steps**

### **Step 1: Test Socket Connection**
1. Open the app
2. Navigate to a chat
3. Check console for socket connection logs
4. Verify "Socket connected: true"

### **Step 2: Test Message Sending**
1. Type a message in chat
2. Press send
3. Check console for sending logs
4. Look for "✅ Encrypted message emitted successfully" or "✅ Regular message sent successfully"

### **Step 3: Test Message Receiving**
1. Send a message from another device/user
2. Check console for receiving logs
3. Look for "🔵 Processing new message" logs

### **Step 4: Test Fallback Messaging**
If E2EE fails, the app should automatically fallback to regular messaging. Look for:
```
❌ Failed to send encrypted message: [error]
🔄 Falling back to regular message sending
🔵 Sending regular message: {...}
✅ Regular message sent successfully
```

## 🔧 **Manual Testing**

### **Test Socket Connection**
```dart
// Add this to chat page for testing
void _testSocketConnection() {
  if (_socketService != null) {
    print('Socket connected: ${_socketService!.isConnected}');
    print('Socket ID: ${_socketService!.socketId}');
    print('Current user ID: $_currentUserId');
  }
}
```

### **Test Message Sending**
```dart
// Add this to chat page for testing
void _testMessageSending() {
  _sendTestMessage(); // This will send a simple test message
}
```

### **Test E2EE**
```dart
// Add this to chat page for testing
void _testE2EE() {
  final success = E2EEUtils.testEncryptionDecryption();
  print('E2EE Test: ${success ? 'PASSED' : 'FAILED'}');
}
```

## 📊 **Expected Log Flow**

### **Normal Message Sending:**
```
🔵 Attempting to send message to: [conversation_id]
🔵 Socket connected: true
🔵 Current user ID: [user_id]
🔵 sendEncryptedMessage called
🔵 Getting conversation key for: [receiver_id]
🔵 Got encryption key: [key_prefix]...
🔵 Encrypting message
🔵 Message encrypted successfully
🔵 Sending encrypted message to: [receiver_id]
🔵 Message data: {...}
✅ Encrypted message emitted successfully
✅ Message sent successfully (encrypted)
```

### **Fallback Message Sending:**
```
🔵 Attempting to send message to: [conversation_id]
🔵 Socket connected: true
🔵 Current user ID: [user_id]
❌ Failed to send encrypted message: [error]
🔄 Falling back to regular message sending
🔵 Sending regular message: {...}
✅ Regular message sent successfully
✅ Message sent successfully (regular)
```

## 🎯 **Next Steps**

1. **Run the app** and check the console logs
2. **Follow the debugging checklist** above
3. **Identify the specific issue** from the symptoms
4. **Apply the corresponding solution**
5. **Test again** to verify the fix

## 📞 **If Issues Persist**

If you're still having issues after following this guide:

1. **Check the console logs** for specific error messages
2. **Verify backend is running** and accessible
3. **Test with a simple message** using the test functions
4. **Check network connectivity** and firewall settings
5. **Verify authentication** is working properly

The E2EE implementation is working correctly (tests pass), so the issue is likely with:
- Socket connection
- Backend endpoints
- Authentication
- Network connectivity 