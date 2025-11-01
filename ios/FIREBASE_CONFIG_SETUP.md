# iOS Firebase Configuration Setup

## Overview
This project uses different Firebase projects for different environments:
- **Development (Debug)**: `nookly-dev`
- **Production/Staging (Release)**: `nookly-18de4`

## Current Setup
- `GoogleService-Info.plist` - Production/Staging config (nookly-18de4)
- `GoogleService-Info-Dev.plist` - Development config (nookly-dev)

## Xcode Build Phase Configuration

To automatically use the correct Firebase config based on build configuration:

### Step-by-Step Instructions:

1. **Open the project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ **Important:** Open the `.xcworkspace` file, NOT the `.xcodeproj` file

2. **Select the Runner target:**
   - In the left sidebar, click on the **Runner** project (blue icon)
   - Under **TARGETS**, select **Runner**
   - Click on the **Build Phases** tab (at the top)

3. **Add Run Script Phase:**
   - Click the **+** button at the top-left of the Build Phases section
   - Select **New Run Script Phase**
   - A new "Run Script" section will appear

4. **Configure the script:**
   - Expand the new "Run Script" section (click the disclosure triangle)
   - In the script editor box, paste this exact line:
     ```bash
     "${SRCROOT}/Runner/copy_firebase_config.sh"
     ```
   - Rename the phase by double-clicking "Run Script" → change to **"Copy Firebase Config"**

5. **Move script before compilation:**
   - **Drag** the "Copy Firebase Config" phase **above** "Compile Sources"
   - The order should be:
     - Target Dependencies
     - **Copy Firebase Config** ← Your new script (should be here)
     - Compile Sources
     - Link Binary With Libraries
     - ...

6. **Verify configuration:**
   - The script phase should show: `"${SRCROOT}/Runner/copy_firebase_config.sh"`
   - Shell should be: `/bin/sh` (default)
   - Check "Show environment variables in build log" (optional, for debugging)

### Visual Location in Xcode:
```
Runner Target → Build Phases Tab
├── Target Dependencies
├── Copy Firebase Config        ← Add script here
├── Compile Sources
├── Link Binary With Libraries
└── ...
```

## Alternative: Manual Method

If you prefer manual control:

**For Debug builds:**
- Copy `GoogleService-Info-Dev.plist` to `GoogleService-Info.plist` before building

**For Release builds:**
- Ensure `GoogleService-Info.plist` contains the production config (nookly-18de4)

## Verification

After building, verify the correct config is used by checking:
1. The console logs should show which Firebase project is being initialized
2. Check Firebase Analytics/Crashlytics dashboard - events should appear in the correct project

## Notes

- The script automatically copies the correct config file based on `CONFIGURATION` variable
- Debug builds → uses `nookly-dev`
- Release builds → uses `nookly-18de4` (production)

