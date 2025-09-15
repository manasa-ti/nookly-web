# Online Status Implementation

This document describes the implementation of online status features in the Hushmate app.

## Overview

The app now supports real-time online status tracking for users, including:
- Online/offline status indicators
- Last seen timestamps
- Connection status (online/away/offline)
- Real-time status updates via socket events
- Heartbeat functionality to maintain online status

## API Changes

### Messages/Conversations API
The `/messages/conversations` endpoint now returns user objects with additional online status fields:

```json
{
  "user": {
    "_id": "string",
    "email": "string",
    "name": "string",
    "profile_pic": "string",
    "age": "number",
    "sex": "string",
    "interests": ["string"],
    "location": "object",
    "isOnline": "boolean (true if user is currently online)",
    "lastSeen": "string (ISO date - when user was last active)",
    "connectionStatus": "string (online/away/offline - current connection status)"
  }
}
```

### Profile API
The `/users/profile/:userId` endpoint now includes online status fields for other users:

```json
{
  "_id": "string",
  "email": "string (only if requesting own profile)",
  "name": "string",
  "bio": "string",
  "interests": ["string"],
  "objectives": ["string"],
  "personality_type": ["string"],
  "physical_activeness": ["string"],
  "availability": ["string"],
  "age": "number",
  "sex": "string",
  "seeking_gender": "string",
  "hometown": "string",
  "profile_pic": "string",
  "preferred_age_range": {
    "lower_limit": "number",
    "upper_limit": "number"
  },
  "preferred_distance_radius": "number",
  "location": {
    "coordinates": [number, number]
  },
  "last_active": "string (ISO date)",
  "isOnline": "boolean (true if user is currently online, only for other users)",
  "lastSeen": "string (ISO date - when user was last active, only for other users)",
  "connectionStatus": "string (online/away/offline - current connection status, only for other users)",
  "createdAt": "string (ISO date)",
  "updatedAt": "string (ISO date)"
}
```

## Socket Events

### User Online Status Events

#### User Comes Online
- **Server emits to all users:**
  - `user_online` `{ userId }`
- **Client behavior:**
  - Updates user's online status in local state
  - Shows online indicator in UI (green dot, etc.)
  - Updates conversations list if user is in conversations

#### User Goes Offline
- **Server emits to all users:**
  - `user_offline` `{ userId }`
- **Client behavior:**
  - Updates user's online status in local state
  - Hides online indicator in UI
  - Updates conversations list if user is in conversations

#### Heartbeat
- **Client emits:**
  - `heartbeat` (no data required)
- **Purpose:** Maintain online status during long idle periods
- **Frequency:** Recommended every 30-60 seconds when app is active

## Implementation Details

### Data Models

#### User Entity
Updated to include online status fields:
- `isOnline`: Boolean indicating if user is currently online
- `lastSeen`: ISO date string of when user was last active
- `connectionStatus`: String indicating connection status (online/away/offline)
- `lastActive`: ISO date string of last activity

#### Conversation Entity
Updated to include online status fields:
- `lastSeen`: ISO date string of when participant was last active
- `connectionStatus`: String indicating participant's connection status

### UI Components

#### Conversation List
- Shows online status indicators (green dots) for online users
- Displays "Online" badge for currently online users
- Shows "Last seen X minutes/hours/days ago" for offline users
- Updates in real-time when users come online/offline

#### Chat Page
- Shows online status in the app bar
- Displays "Online" for currently online users
- Shows formatted last seen time for offline users
- Updates in real-time during conversation

#### Custom Avatar Widget
- Already supports online status with green dot indicator
- Positioned at bottom-right of avatar
- Only visible when user is online

### Socket Service

#### New Methods
- `sendHeartbeat()`: Sends heartbeat to maintain online status
- `startHeartbeat()`: Starts periodic heartbeat timer
- `stopHeartbeat()`: Stops heartbeat timer
- `_handleUserOnlineStatus()`: Handles online/offline status changes

#### Event Handlers
- `user_online`: Updates user status to online
- `user_offline`: Updates user status to offline

### Usage Examples

#### Starting Heartbeat
```dart
final socketService = GetIt.instance<SocketService>();
socketService.startHeartbeat(interval: Duration(seconds: 30));
```

#### Stopping Heartbeat
```dart
final socketService = GetIt.instance<SocketService>();
socketService.stopHeartbeat();
```

#### Manual Heartbeat
```dart
final socketService = GetIt.instance<SocketService>();
socketService.sendHeartbeat();
```

## Best Practices

1. **Start heartbeat when app becomes active** - Call `startHeartbeat()` when the app comes to foreground
2. **Stop heartbeat when app goes to background** - Call `stopHeartbeat()` when the app goes to background
3. **Handle socket disconnection** - The heartbeat automatically stops when socket disconnects
4. **Update UI in real-time** - Listen for `user_online` and `user_offline` events to update UI immediately
5. **Format last seen time** - Use relative time formatting (e.g., "5m ago", "2h ago") for better UX

## Testing

To test the online status features:

1. **Online Status Display**: Check that online users show green dots and "Online" status
2. **Last Seen Display**: Verify that offline users show appropriate last seen times
3. **Real-time Updates**: Test that status updates immediately when users come online/offline
4. **Heartbeat**: Monitor logs to ensure heartbeat is being sent regularly
5. **Socket Events**: Verify that `user_online` and `user_offline` events are received and handled

## Future Enhancements

Potential future improvements:
- Away status detection (user inactive but connected)
- Custom online status messages
- Online status privacy settings
- Batch status updates for better performance
- Offline message queuing with status awareness
