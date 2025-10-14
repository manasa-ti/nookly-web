# 🔧 Push Notification Troubleshooting

## 🔴 Issue: Notifications Not Received After Reinstall

This is a **common issue** when reinstalling apps. Here's why and how to fix it:

### Why This Happens:
1. **New FCM token generated** - Every app installation gets a unique FCM token
2. **Backend has old token** - Your server still has the old (now invalid) token
3. **Notification sent to old token** - Firebase rejects it (token not found)
4. **User doesn't receive notification** ❌

---

## 🔍 Diagnostic Steps

### Step 1: Check if App Generated New FCM Token

Run the app and check the logs:

```
Expected logs:
✅ Firebase initialized
✅ Firebase Messaging initialized
📱 FCM Token: dXXXX... (your new token)
✅ User granted permission
```

**If you see FCM token:** ✅ Token generated successfully

**If you DON'T see FCM token:** ❌ Problem with Firebase initialization

---

### Step 2: Check if Device Registered with Backend

After login, check logs:

```
Expected logs:
📱 Registering device: platform=android
✅ Device registered successfully
Device info: {...}
```

**If you see "Device registered":** ✅ Backend has new token

**If you DON'T see this:** ❌ Registration failed

---

### Step 3: Verify Backend Has New Token

Check your backend database:

```sql
-- Check devices for your user
SELECT * FROM user_devices 
WHERE user_id = YOUR_USER_ID 
ORDER BY created_at DESC 
LIMIT 5;
```

**Expected:**
- Should see a new entry with today's timestamp
- `fcm_token` should match the token from app logs
- `is_active` should be `true`

**If old token still active:**
Backend didn't update correctly

---

### Step 4: Test with New Token

Send test notification using the NEW token from app logs:

**Option A: Firebase Console**
1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Paste the NEW FCM token from your app logs
4. Send

**Option B: Backend Test Endpoint**
```bash
POST /api/notifications/test
Headers: Authorization: Bearer <your-jwt-token>
```

---

## ✅ Solutions

### Solution 1: Force Re-Registration

**Quick Fix** - Manually trigger registration:

```dart
// In your app's dev menu or settings
Future<void> forceRegisterDevice() async {
  final repo = sl<NotificationRepository>();
  final success = await repo.registerDevice();
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Device registered successfully')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to register device')),
    );
  }
}
```

### Solution 2: Login Again

The app should automatically register on login:

1. **Logout** from the app
2. **Login** again
3. Check logs for: "✅ Device registered successfully"
4. Send test notification

### Solution 3: Clean Backend Tokens

If you have multiple old tokens in backend:

```sql
-- Deactivate old tokens for user
UPDATE user_devices 
SET is_active = false 
WHERE user_id = YOUR_USER_ID 
AND created_at < NOW() - INTERVAL '1 day';
```

Then login to app again to register new token.

---

## 🐛 Common Issues After Reinstall

### Issue 1: App Not Logging In
**Symptom:** Can't login after reinstall  
**Cause:** Session expired  
**Solution:** Clear app data and login fresh

### Issue 2: Permission Denied
**Symptom:** "User declined notification permission"  
**Cause:** Android 13+ requires runtime permission  
**Solution:** 
1. Uninstall app
2. Reinstall
3. Grant notification permission when prompted

### Issue 3: Backend Returns 401 Unauthorized
**Symptom:** Registration fails with 401 error  
**Cause:** JWT token expired or invalid  
**Solution:** Logout and login again with fresh token

### Issue 4: Multiple Devices Registered
**Symptom:** Same device registered multiple times  
**Cause:** Token changed but old entry not cleaned up  
**Solution:** Backend should mark old tokens as inactive

---

## 🔍 Detailed Debugging

### Enable Verbose Logging

The app already has comprehensive logging. Check for these specific messages:

#### Firebase Initialization:
```
✅ Firebase initialized
✅ Firebase background message handler set
✅ Firebase Messaging initialized
```

#### Permission:
```
✅ User granted notification permission
OR
❌ User declined or has not accepted notification permission
```

#### FCM Token:
```
📱 FCM Token: dXXXXXXXXXXXX...
```

#### Registration:
```
📱 Registering device: platform=android
✅ Device registered successfully
Device info: {id: xxx, platform: android, ...}
```

#### Errors:
```
❌ Error registering device: <error details>
⚠️ FCM token is null, cannot register device
```

---

## 🧪 Step-by-Step Test After Reinstall

### Test Procedure:

1. **Uninstall app** (if not already done)
   ```bash
   adb uninstall com.nookly.app
   ```

2. **Install fresh build**
   ```bash
   flutter run
   ```

3. **Grant notification permission**
   - When prompted, tap "Allow"

4. **Check logs for Firebase initialization**
   ```
   ✅ Firebase initialized
   ✅ Firebase Messaging initialized
   ```

5. **Check logs for FCM token**
   ```
   📱 FCM Token: dXXXX...
   ```
   **COPY THIS TOKEN!**

6. **Login to app**
   - Use your test account

7. **Check logs for registration**
   ```
   📱 Registering device: platform=android
   ✅ Device registered successfully
   ```

8. **Verify in backend database**
   - Check the new token is stored
   - Check `is_active = true`

9. **Send test notification**
   - Use Firebase Console with NEW token
   - Or use backend `/notifications/test` endpoint

10. **Expected result**
    - Notification appears
    - Blue color
    - Sound + vibration
    - Heads-up display

---

## 🎯 Quick Fix Right Now

If you need notifications working immediately:

### Option A: Use Firebase Console Test
1. Check app logs for new FCM token
2. Copy the token (starts with something like `dXXX...`)
3. Go to Firebase Console → Cloud Messaging → "Send test message"
4. Paste the NEW token
5. Send test

This bypasses your backend and tests Firebase directly.

### Option B: Re-login to App
1. Logout from app
2. Login again
3. Check logs confirm: "✅ Device registered successfully"
4. Try sending notification from backend

---

## 📊 Expected vs Actual

### Expected Flow After Reinstall:
```
Reinstall app
  ↓
Open app
  ↓
Firebase generates NEW FCM token
  ↓
User logs in
  ↓
App registers NEW token with backend
  ↓
Backend stores NEW token
  ↓
✅ Notifications work
```

### If It's Not Working:
One of these steps failed. Check logs to find which step.

---

## 🔧 Backend Cleanup (If Needed)

If backend has many stale tokens:

```javascript
// Add to your notification service
async cleanupStaleTokens(userId) {
  // Deactivate tokens older than 30 days
  await db.query(`
    UPDATE user_devices 
    SET is_active = false 
    WHERE user_id = $1 
    AND last_used < NOW() - INTERVAL '30 days'
  `, [userId]);
  
  // OR delete them entirely
  await db.query(`
    DELETE FROM user_devices 
    WHERE user_id = $1 
    AND last_used < NOW() - INTERVAL '30 days'
  `, [userId]);
}
```

---

## ✅ Next Steps

1. **Check app logs** - Look for FCM token and registration
2. **Copy new FCM token** - From logs
3. **Verify in backend** - Check database has new token
4. **Test with new token** - Send notification
5. **If still not working** - Share the logs with me

---

Let me know what you see in the logs and I'll help you fix it!


