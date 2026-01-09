# Mobile Build Setup Guide

## Overview

This guide explains how to set up and use environment variables for local mobile app builds (Android and iOS).

## Setup Steps

### 1. Create `.env` File

Copy the example template and fill in your secrets:

```bash
cp .env.example.mobile .env
```

### 2. Fill in Your Secrets

Edit the `.env` file and replace all placeholder values with your actual secrets:

- **100ms Configuration**: Get from your 100ms dashboard
- **Firebase Configuration**: Get from Firebase Console
  - Development: Use dev Firebase project credentials
  - Production: Use prod Firebase project credentials (staging also uses these)
- **Google Sign-In**: Get from Google Cloud Console > APIs & Services > Credentials

### 3. Build Your App

The build scripts will automatically load secrets from `.env` file:

#### Production Build
```bash
./build_release.sh
```

#### Staging Build
```bash
./build_staging_release.sh
```

#### Quick Build (Development/Staging/Production)
```bash
./build_scripts.sh dev      # Development
./build_scripts.sh staging  # Staging
./build_scripts.sh prod     # Production
```

## What Gets Built

### Android
- **AAB** (App Bundle): `build/app/outputs/bundle/release/app-release.aab`
  - Upload to Google Play Console
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
  - For direct installation/testing

### iOS
- **IPA**: `ios/build/export/nookly.ipa`
  - Upload to App Store Connect for TestFlight/App Store

## Environment Configuration

### Development
- **API**: `https://dev.nookly.app/api`
- **Firebase**: Dev project (`nookly-dev`)
- **Firebase Config**: Uses `FIREBASE_*_DEV_*` variables

### Staging
- **API**: `https://staging.nookly.app/api`
- **Firebase**: Prod project (`nookly-18de4`) ⚠️
- **Firebase Config**: Uses `FIREBASE_*_PROD_*` variables

### Production
- **API**: `https://api.nookly.app/api`
- **Firebase**: Prod project (`nookly-18de4`)
- **Firebase Config**: Uses `FIREBASE_*_PROD_*` variables

## Security Notes

1. ✅ **`.env` is in `.gitignore`** - Never commit it
2. ✅ **Secrets are compiled into the binary** - They're embedded at build time
3. ⚠️ **Mobile binaries can be reverse-engineered** - But it's harder than web
4. ✅ **Use different secrets per environment** - Dev, Staging, Production

## Troubleshooting

### Missing Secrets Warning

If you see:
```
⚠️  Warning: .env file not found. Secrets will use default values (if any).
```

**Solution**: Create `.env` file from the template:
```bash
cp .env.example.mobile .env
# Then fill in your actual values
```

### Empty Secrets

If secrets are empty, the app will use default values from the code (if any). For production builds, you should always provide actual secrets.

### Build Fails

If build fails with missing variables:
1. Check that `.env` file exists
2. Verify all required variables are set
3. Ensure no syntax errors in `.env` file (no spaces around `=`)

## Required Secrets Summary

### All Environments Need:
- `HMS_APP_ID`
- `HMS_AUTH_TOKEN`
- `GOOGLE_SIGN_IN_ANDROID_CLIENT_ID`
- `GOOGLE_SIGN_IN_IOS_CLIENT_ID`

### Development Needs:
- `FIREBASE_ANDROID_DEV_*` (5 variables)
- `FIREBASE_IOS_DEV_*` (6 variables)

### Production & Staging Need:
- `FIREBASE_ANDROID_PROD_*` (5 variables)
- `FIREBASE_IOS_PROD_*` (6 variables)

## Next Steps

1. ✅ Create `.env` file from template
2. ✅ Fill in all your secrets
3. ✅ Test build with `./build_scripts.sh dev`
4. ✅ Build production release with `./build_release.sh`
5. ✅ Upload to Play Store / App Store

