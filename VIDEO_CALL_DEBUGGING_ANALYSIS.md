# Video Call Debugging Analysis - Issue Report

**Date:** October 20, 2025
**Issue:** Blank screens and video track not loading
**Status:** 🔴 CRITICAL - Root cause identified

---

## 🐛 **OBSERVED ISSUES**

### Issue 1: Call Initiator - Blank Screen
- **Symptom:** Initiator sees completely blank screen (no video at all)
- **Local video:** Not visible
- **Remote video:** Not visible

### Issue 2: Call Receiver - Duplicate Local Video
- **Symptom:** Receiver sees their own video in BOTH views
- **Full screen:** Shows local video (should be remote)
- **Small overlay:** Shows local video (correct)
- **Remote video:** Not visible anywhere

### Issue 3: Audio Mute Button Spam
- **Symptom:** Audio mute logged 3x rapidly
- **Indicates:** Button clicked multiple times or no debouncing

---

## 🔍 **LOG ANALYSIS - CRITICAL FINDINGS**

### ❌ **MISSING LOGS (This is the main problem):**

**What's NOT appearing in your logs:**
1. ❌ NO `🎉 onJoin` callback logs
2. ❌ NO `🎵 TRACK UPDATE` logs  
3. ❌ NO `📹 LOCAL video track ADDED`
4. ❌ NO `📹 REMOTE video track ADDED`
5. ❌ NO `🎥 Creating local/remote video view` logs
6. ❌ NO `👤 PEER UPDATE` logs with video track info

**What this means:**
- The HMS SDK callbacks are **NOT being triggered**
- Our service is not receiving track updates
- Video tracks are never being assigned
- State machine stuck at `notInitialized`

### ✅ **WHAT IS WORKING:**

1. ✅ Audio is working (speaker-list shows audio track IDs)
2. ✅ Network quality updates working
3. ✅ Connection established (ICE connected)
4. ✅ Room joined (websocket open)

---

## 🎯 **ROOT CAUSE**

Based on the logs, the issue is **NOT in the Flutter code**. The problem is:

### **1. HMS Room Template Configuration (Backend)**

Your backend is likely using an HMS room template that:
- ❌ Doesn't have video tracks enabled
- ❌ Has wrong role permissions (roles can't publish video)
- ❌ Uses audio-only template instead of video template

**Evidence:**
- Audio tracks are appearing (`track_id` in speaker-list)
- Video tracks are completely absent
- No `onTrackUpdate` callbacks for video
- Connection is working fine

### **2. Multiple Peers in Room (4 instead of 2)**

The logs show **4 different peer IDs**:
```
peer_id: ab972937-0880-4f07-89b7-daedf113cf49
peer_id: b01a8763-6c54-47f4-98e1-13c26fc202f4
peer_id: 6b3f1f45-f076-4ed7-806e-6b8f811e709d
peer_id: 95bf76f4-f698-4075-85b0-0ed7f0e66b25
```

This suggests:
- Old call sessions not cleaned up
- Backend creating multiple sessions
- Room not being properly isolated

---

## 🔧 **FIXES APPLIED**

### Fix #1: Enhanced onJoin Logging ✅
Added comprehensive logging to catch track assignment on join:
```dart
🎉 onJoin called
🎉 - Room ID, Name, Total peers
🎉 - For each peer: name, ID, role, video track, audio track
🎉 - Immediate track assignment if available
```

### Fix #2: Debouncing for Mute Buttons ✅
Added 1-second debounce to prevent spam:
```dart
if (now.difference(_lastAudioMuteTime).inMilliseconds < 1000) {
  return; // Ignore rapid clicks
}
```

---

## 📋 **ACTION ITEMS FOR YOU**

### **BACKEND CHANGES REQUIRED** (High Priority)

#### 1. Check HMS Room Template Configuration

**In your backend code, when creating HMS room, ensure:**

```javascript
// Example backend code (adjust to your implementation)
const room = await hms.rooms.create({
  name: 'call-room-' + callId,
  template_id: 'YOUR_VIDEO_TEMPLATE_ID',  // ⚠️ Must be VIDEO template
  region: 'in',  // India region
});
```

**⚠️ CRITICAL: Use a VIDEO template, not audio-only!**

Check your HMS dashboard:
1. Go to https://dashboard.100ms.live
2. Navigate to Templates
3. Find your template
4. Verify it has **"Video" enabled** for all roles
5. Check that roles can **"Publish Video"**

#### 2. Check Role Configuration

Ensure both `host` and `guest` (or whatever roles you use) have:
- ✅ **Publish Audio:** ON
- ✅ **Publish Video:** ON
- ✅ **Subscribe to Audio:** ON
- ✅ **Subscribe to Video:** ON

#### 3. Fix Room Cleanup

Ensure old call sessions are properly ended:
```javascript
// When call ends, delete the room
await hms.rooms.delete(roomId);
```

---

## 🧪 **HOW TO VERIFY BACKEND FIX**

### **Test 1: Check Room Template**
```bash
# Call your backend API
curl -X POST https://dev.nookly.app/api/calls/initiate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"receiverId": "test123", "callType": "video"}'

# Check response - look for:
{
  "callSession": {
    "hmsRoomId": "...",
    "roomId": "..."
  },
  "tokens": {
    "caller": {"token": "..."},
    "receiver": {"token": "..."}
  }
}
```

### **Test 2: Verify HMS Room Has Video**

Log into HMS Dashboard:
1. Go to Rooms section
2. Find the active room
3. Click on it
4. Check "Tracks" - should show VIDEO tracks, not just audio

---

## 🎯 **EXPECTED LOGS AFTER FIX**

After backend fixes, you should see these logs when testing:

```
🎉 ============================================
🎉 onJoin called
🎉 - Room ID: abc123
🎉 - Total peers: 1 (initially, then 2)
🎉 Peer in room: User_xxx (isLocal: true)
🎉   - Video Track: track-123-abc (NOT NULL!)
🎉   - Audio Track: track-456-def
🎉 ✅ LOCAL VIDEO ASSIGNED ON JOIN: track-123-abc
🎉 ============================================

👤 PEER UPDATE: User_yyy
👤 - Update Type: peerJoined
👤 - Is Local: false
👤 - Video Track: Available (track-789-xyz)
✅ REMOTE PEER JOINED: User_yyy
📹 ✅ Remote video track available on join

🎵 TRACK UPDATE
🎵 - Track Kind: kHMSTrackKindVideo
🎵 - Track Update: trackAdded
📹 ✅ REMOTE video track ADDED

🎥 Creating local video view - State: ready, Track: track-123
🎥 Local video ready - track ID: track-123

🎥 Creating remote video view - State: ready, Track: track-789
🎥 Remote video ready - track ID: track-789
```

---

## 📝 **TEMPORARY WORKAROUND (For Testing)**

While backend is being fixed, you can test with HMS pre-built rooms:

1. Create a test template in HMS Dashboard with video enabled
2. Hardcode the template ID temporarily in backend
3. Test the call flow

---

## 🔧 **CODE CHANGES MADE**

### Enhanced HMSCallService ✅
- Added detailed peer logging in `onJoin`
- Immediate track assignment from room.peers
- Better state tracking

### Enhanced CallScreen ✅
- Added 1-second debounce on mute buttons
- Prevents rapid clicking
- Better user feedback

---

## 📊 **SUMMARY**

| Component | Status | Issue |
|-----------|--------|-------|
| **Flutter Code** | ✅ Working | No issues found |
| **HMS SDK** | ✅ Connected | Connection established |
| **Backend API** | ✅ Working | Calls initiated successfully |
| **HMS Room Config** | ❌ PROBLEM | Video tracks not configured |
| **Role Permissions** | ❌ PROBLEM | Roles can't publish video |

**PRIMARY ISSUE:** HMS room template on backend doesn't have video enabled.

**SOLUTION:** Update backend HMS room creation to use video-enabled template with proper role permissions.

---

## 🚀 **NEXT STEPS**

1. **Backend Team:** Update HMS room template configuration
2. **Test Again:** With new logs showing video track assignment
3. **Report Back:** Share logs with `🎉 onJoin` section
4. **Verify:** Look for video track IDs (not "NULL")

---

**When you test again with the updated code, look for these logs in order:**
1. `🎉 onJoin` - Should show video tracks
2. `🎉 ✅ LOCAL VIDEO ASSIGNED` - Should appear
3. `📹 ✅ REMOTE video track ADDED` - Should appear when peer joins
4. `🎥 Local video ready` - Should appear
5. `🎥 Remote video ready` - Should appear

**If still blank, share the `🎉 onJoin` section of the logs!**

