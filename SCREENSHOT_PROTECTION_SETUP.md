# Screenshot and Screen Recording Protection Setup

This document outlines the setup and configuration for screenshot and screen recording prevention in the Nookly application.

## Overview

Screenshot and screen recording protection has been implemented for the following screens:
- **Video Calls** (`CallScreen`)
- **Chat Screen** (`ChatPage`)
- **Profile Pages** (`ProfileHubPage`, `ProfileViewPage`, `ProfileCreationPage`, `EditProfilePage`)

The protection is remotely configurable via Firebase Remote Config, allowing you to enable/disable protection without requiring an app update.

## Firebase Remote Config Setup

To configure screenshot protection remotely, you need to set up the following parameters in your Firebase Console:

### 1. Navigate to Firebase Remote Config

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Firebase project (`nookly-dev` for development, `nookly-18de4` for staging/production)
3. Navigate to **Build** → **Remote Config**

### 2. Add Remote Config Parameters

Add the following parameters with their default values:

| Parameter Key | Type | Default Value | Description |
|--------------|------|---------------|-------------|
| `enable_screenshot_protection` | Boolean | `true` | Master switch to enable/disable screenshot protection globally |
| `protect_video_calls` | Boolean | `true` | Enable protection for video call screens |
| `protect_chat_screen` | Boolean | `true` | Enable protection for chat screen |
| `protect_profile_pages` | Boolean | `true` | Enable protection for profile pages |

### 3. Configure Default Values

1. Click **Add parameter** for each parameter above
2. Set the **Parameter key** exactly as shown
3. Set the **Default value** as a boolean:
   - Select **Boolean** as the data type
   - Set the value to `true` or `false`
4. Click **Save**

### 4. Publish Configuration

1. After adding all parameters, click **Publish changes**
2. The configuration will be available to all app instances within a few minutes (default fetch interval is 1 hour)

### 5. Conditional Values (Optional)

You can also set conditional values based on app version, platform, etc.:

1. Click on a parameter
2. Click **Add value for condition**
3. Create a condition (e.g., `app_version < 1.0.0` to disable for older versions)
4. Set the value for that condition

## Testing Remote Config

### Enable Debug Mode

To test Remote Config changes immediately without waiting for the fetch interval:

1. **Android**: Run the following ADB command:
   ```bash
   adb shell setprop debug.firebase.remote_config true
   ```

2. **iOS**: In Xcode, add `-FIRDebugEnabled` to your scheme's "Arguments Passed On Launch"

### Verify Configuration

Check the app logs for:
```
✅ Remote Config initialized
📊 Remote Config Protection Settings:
  enable_screenshot_protection: true
  protect_video_calls: true
  protect_chat_screen: true
  protect_profile_pages: true
```

## How It Works

### Protection Mechanism

The app uses the `screen_protector` Flutter package, which:
- **Android**: Sets `FLAG_SECURE` on the window, preventing screenshots and screen recording
- **iOS**: Uses native APIs to prevent screenshots and screen recording

### Service Architecture

1. **RemoteConfigService** (`lib/core/services/remote_config_service.dart`)
   - Fetches configuration from Firebase Remote Config
   - Provides methods to check if protection should be enabled for specific screens
   - Handles default values if Remote Config is unavailable

2. **ScreenProtectionService** (`lib/core/services/screen_protection_service.dart`)
   - Wraps the `screen_protector` package
   - Checks Remote Config before enabling protection
   - Manages protection state (enable/disable)

### Screen Integration

Each protected screen:
- Enables protection in `initState()` (after checking Remote Config)
- Disables protection in `dispose()` when leaving the screen

Example:
```dart
@override
void initState() {
  super.initState();
  _screenProtectionService = sl<ScreenProtectionService>();
  _enableScreenProtection();
  // ... rest of initialization
}

Future<void> _enableScreenProtection() async {
  if (!mounted) return;
  await _screenProtectionService.enableProtection(
    screenType: 'chat', // or 'video_call', 'profile'
    context: context,
  );
}

@override
void dispose() {
  _disableScreenProtection();
  super.dispose();
}
```

## Behavior Notes

### System Messages

When a user attempts to take a screenshot or record the screen on a protected screen:
- **Android**: The system may show a toast message (OS-level, not customizable)
- **iOS**: The action is silently blocked (no message shown)

The `screen_protector` package does not provide a callback to detect screenshot attempts, so we cannot show custom app messages. The OS handles the blocking automatically.

### Limitations

1. **Cannot Prevent External Recording**: This protection cannot prevent users from recording the screen with external cameras or devices
2. **Rooted/Jailbroken Devices**: Protection may be bypassed on rooted Android devices or jailbroken iOS devices
3. **Third-Party Apps**: Some third-party screen recording apps may bypass protection

### Remote Config Priority

The protection respects Remote Config in the following order:
1. `enable_screenshot_protection` (global master switch)
2. Screen-specific flag (`protect_video_calls`, `protect_chat_screen`, `protect_profile_pages`)

If `enable_screenshot_protection` is `false`, protection is disabled regardless of screen-specific flags.

## Debugging

### Enable Protection for Testing

To temporarily disable protection for debugging:
1. In Firebase Remote Config, set `enable_screenshot_protection` to `false`
2. Publish the changes
3. Restart the app (or wait for the next fetch interval)

### Check Protection Status

Look for these log messages:
- `🔒 Screen protection enabled for <screen_type>` - Protection is active
- `🔓 Screen protection disabled` - Protection is disabled
- `🔒 Screenshot protection disabled via Remote Config` - Protection skipped due to Remote Config

### Common Issues

1. **Protection not working**:
   - Verify Remote Config parameters are set correctly
   - Check that the parameter keys match exactly (case-sensitive)
   - Ensure `enable_screenshot_protection` is `true`
   - Check app logs for initialization errors

2. **Remote Config not loading**:
   - Verify Firebase is initialized before Remote Config service
   - Check network connectivity
   - Verify Firebase project configuration files are correct
   - Check default values are set correctly

3. **Protection stays enabled after leaving screen**:
   - Verify `dispose()` method calls `_disableScreenProtection()`
   - Check that no other screen is still protecting (only one screen can protect at a time)

## Environment-Specific Configuration

Remember that Remote Config is configured per Firebase project:
- **Development**: Use `nookly-dev` project
- **Staging/Production**: Use `nookly-18de4` project

Set up the Remote Config parameters in both projects with appropriate values for each environment.

## Best Practices

1. **Default to Protected**: Set default values to `true` for security by default
2. **Test Changes**: Always test Remote Config changes in development before pushing to production
3. **Monitor Logs**: Watch app logs after publishing Remote Config changes
4. **Document Changes**: Keep a record of when and why protection settings were changed
5. **Gradual Rollout**: Consider using Remote Config conditions to gradually roll out changes

---

For questions or issues, refer to the implementation in:
- `lib/core/services/remote_config_service.dart`
- `lib/core/services/screen_protection_service.dart`

