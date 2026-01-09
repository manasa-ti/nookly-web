# Security Setup Guide

## ⚠️ Important: Secret Keys Management

This project has been updated to use environment variables for all sensitive keys and tokens. **Never commit actual secret values to version control!**

## Environment Variables Required

### For GitHub Pages Deployment

When building for web deployment, you need to pass environment variables using `--dart-define` flags.

### Required Environment Variables

#### 100ms Configuration
- `HMS_APP_ID` - Your 100ms App ID
- `HMS_AUTH_TOKEN` - Your 100ms Auth Token (JWT)

#### Firebase Configuration (Development)
- `FIREBASE_WEB_DEV_API_KEY`
- `FIREBASE_WEB_DEV_APP_ID`
- `FIREBASE_WEB_DEV_MESSAGING_SENDER_ID`
- `FIREBASE_WEB_DEV_PROJECT_ID`
- `FIREBASE_WEB_DEV_AUTH_DOMAIN`
- `FIREBASE_WEB_DEV_STORAGE_BUCKET`
- `FIREBASE_WEB_DEV_MEASUREMENT_ID`

#### Firebase Configuration (Production)
- `FIREBASE_WEB_PROD_API_KEY`
- `FIREBASE_WEB_PROD_APP_ID`
- `FIREBASE_WEB_PROD_MESSAGING_SENDER_ID`
- `FIREBASE_WEB_PROD_PROJECT_ID`
- `FIREBASE_WEB_PROD_AUTH_DOMAIN`
- `FIREBASE_WEB_PROD_STORAGE_BUCKET`
- `FIREBASE_WEB_PROD_MEASUREMENT_ID`

#### Google Sign-In Configuration
- `GOOGLE_SIGN_IN_WEB_CLIENT_ID`
- `GOOGLE_SIGN_IN_ANDROID_CLIENT_ID`
- `GOOGLE_SIGN_IN_IOS_CLIENT_ID`

## Building with Environment Variables

### For Web Deployment (GitHub Pages)

```bash
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=HMS_APP_ID=your_hms_app_id \
  --dart-define=HMS_AUTH_TOKEN=your_hms_auth_token \
  --dart-define=FIREBASE_WEB_PROD_API_KEY=your_key \
  --dart-define=FIREBASE_WEB_PROD_APP_ID=your_app_id \
  --dart-define=FIREBASE_WEB_PROD_MESSAGING_SENDER_ID=your_sender_id \
  --dart-define=FIREBASE_WEB_PROD_PROJECT_ID=your_project_id \
  --dart-define=FIREBASE_WEB_PROD_AUTH_DOMAIN=your_auth_domain \
  --dart-define=FIREBASE_WEB_PROD_STORAGE_BUCKET=your_storage_bucket \
  --dart-define=FIREBASE_WEB_PROD_MEASUREMENT_ID=your_measurement_id \
  --dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=your_google_web_client_id
```

### Using GitHub Actions Secrets

For GitHub Pages deployment via GitHub Actions, store these as **Repository Secrets**:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add each environment variable as a secret
3. Reference them in your GitHub Actions workflow:

```yaml
- name: Build Flutter Web
  run: |
    flutter build web --release \
      --dart-define=ENVIRONMENT=production \
      --dart-define=HMS_APP_ID=${{ secrets.HMS_APP_ID }} \
      --dart-define=HMS_AUTH_TOKEN=${{ secrets.HMS_AUTH_TOKEN }} \
      --dart-define=FIREBASE_WEB_PROD_API_KEY=${{ secrets.FIREBASE_WEB_PROD_API_KEY }} \
      # ... etc
```

## Local Development

For local development, you can either:

1. **Use default values** (already set in code for backward compatibility)
2. **Create a `.env` file** (not committed to git) and use a script to load it
3. **Pass `--dart-define` flags** when running:

```bash
flutter run --dart-define=HMS_APP_ID=your_dev_app_id --dart-define=HMS_AUTH_TOKEN=your_dev_token
```

## Security Best Practices

1. ✅ **Never commit `.env` files** - They're in `.gitignore`
2. ✅ **Use GitHub Secrets** for CI/CD pipelines
3. ✅ **Rotate secrets regularly** - Especially the 100ms Auth Token
4. ✅ **Use different keys per environment** - Dev, Staging, Production
5. ✅ **Review build outputs** - Ensure secrets aren't exposed in compiled code
6. ⚠️ **Note**: Firebase API keys are generally safe to expose (they're public by design), but it's still best practice to use environment variables

## What Was Changed

- ✅ `lib/core/config/environments/*.dart` - Now read from environment variables
- ✅ `lib/firebase_options.dart` - Now read from environment variables
- ✅ `lib/core/services/google_sign_in_service.dart` - Now read from environment variables
- ✅ `.gitignore` - Added `.env` files to ignore list

## Migration Notes

The code includes **default values** for backward compatibility during development. However, for production builds (especially GitHub Pages), you **must** provide these via `--dart-define` flags.

If you don't provide environment variables, the app will use the hardcoded defaults, which means:
- ⚠️ Secrets will still be in the compiled code
- ⚠️ They'll be visible in the deployed web app

**For GitHub Pages deployment, always use `--dart-define` flags with your actual secrets!**

