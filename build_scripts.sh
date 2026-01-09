#!/bin/bash

# Build script for Nookly app with different environments
# Loads secrets from .env file

echo "Nookly Build Script"
echo "==================="

# Load environment variables from .env file
if [ -f ".env" ]; then
    if [ -f "scripts/load_env.sh" ]; then
        source scripts/load_env.sh
    else
        set -a
        source .env 2>/dev/null || true
        set +a
        echo "✅ Loaded secrets from .env file"
    fi
else
    echo "⚠️  Warning: .env file not found. Secrets will use default values (if any)."
fi

case "$1" in
  "dev"|"development")
    echo "Building for DEVELOPMENT environment..."
    flutter build apk --dart-define=ENVIRONMENT=development \
      --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
      --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
      --dart-define=FIREBASE_ANDROID_DEV_API_KEY="${FIREBASE_ANDROID_DEV_API_KEY:-}" \
      --dart-define=FIREBASE_ANDROID_DEV_APP_ID="${FIREBASE_ANDROID_DEV_APP_ID:-}" \
      --dart-define=FIREBASE_ANDROID_DEV_MESSAGING_SENDER_ID="${FIREBASE_ANDROID_DEV_MESSAGING_SENDER_ID:-}" \
      --dart-define=FIREBASE_ANDROID_DEV_PROJECT_ID="${FIREBASE_ANDROID_DEV_PROJECT_ID:-}" \
      --dart-define=FIREBASE_ANDROID_DEV_STORAGE_BUCKET="${FIREBASE_ANDROID_DEV_STORAGE_BUCKET:-}" \
      --dart-define=GOOGLE_SIGN_IN_ANDROID_CLIENT_ID="${GOOGLE_SIGN_IN_ANDROID_CLIENT_ID:-}"
    flutter build ios --dart-define=ENVIRONMENT=development \
      --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
      --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
      --dart-define=FIREBASE_IOS_DEV_API_KEY="${FIREBASE_IOS_DEV_API_KEY:-}" \
      --dart-define=FIREBASE_IOS_DEV_APP_ID="${FIREBASE_IOS_DEV_APP_ID:-}" \
      --dart-define=FIREBASE_IOS_DEV_MESSAGING_SENDER_ID="${FIREBASE_IOS_DEV_MESSAGING_SENDER_ID:-}" \
      --dart-define=FIREBASE_IOS_DEV_PROJECT_ID="${FIREBASE_IOS_DEV_PROJECT_ID:-}" \
      --dart-define=FIREBASE_IOS_DEV_STORAGE_BUCKET="${FIREBASE_IOS_DEV_STORAGE_BUCKET:-}" \
      --dart-define=FIREBASE_IOS_DEV_BUNDLE_ID="${FIREBASE_IOS_DEV_BUNDLE_ID:-}" \
      --dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID="${GOOGLE_SIGN_IN_IOS_CLIENT_ID:-}"
    ;;
  "staging")
    echo "Building for STAGING environment..."
    flutter build apk --dart-define=ENVIRONMENT=staging \
      --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
      --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_API_KEY="${FIREBASE_ANDROID_PROD_API_KEY:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_APP_ID="${FIREBASE_ANDROID_PROD_APP_ID:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID="${FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_PROJECT_ID="${FIREBASE_ANDROID_PROD_PROJECT_ID:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_STORAGE_BUCKET="${FIREBASE_ANDROID_PROD_STORAGE_BUCKET:-}" \
      --dart-define=GOOGLE_SIGN_IN_ANDROID_CLIENT_ID="${GOOGLE_SIGN_IN_ANDROID_CLIENT_ID:-}"
    flutter build ios --dart-define=ENVIRONMENT=staging \
      --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
      --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
      --dart-define=FIREBASE_IOS_PROD_API_KEY="${FIREBASE_IOS_PROD_API_KEY:-}" \
      --dart-define=FIREBASE_IOS_PROD_APP_ID="${FIREBASE_IOS_PROD_APP_ID:-}" \
      --dart-define=FIREBASE_IOS_PROD_MESSAGING_SENDER_ID="${FIREBASE_IOS_PROD_MESSAGING_SENDER_ID:-}" \
      --dart-define=FIREBASE_IOS_PROD_PROJECT_ID="${FIREBASE_IOS_PROD_PROJECT_ID:-}" \
      --dart-define=FIREBASE_IOS_PROD_STORAGE_BUCKET="${FIREBASE_IOS_PROD_STORAGE_BUCKET:-}" \
      --dart-define=FIREBASE_IOS_PROD_BUNDLE_ID="${FIREBASE_IOS_PROD_BUNDLE_ID:-}" \
      --dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID="${GOOGLE_SIGN_IN_IOS_CLIENT_ID:-}"
    ;;
  "prod"|"production")
    echo "Building for PRODUCTION environment..."
    flutter build apk --dart-define=ENVIRONMENT=production \
      --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
      --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_API_KEY="${FIREBASE_ANDROID_PROD_API_KEY:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_APP_ID="${FIREBASE_ANDROID_PROD_APP_ID:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID="${FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_PROJECT_ID="${FIREBASE_ANDROID_PROD_PROJECT_ID:-}" \
      --dart-define=FIREBASE_ANDROID_PROD_STORAGE_BUCKET="${FIREBASE_ANDROID_PROD_STORAGE_BUCKET:-}" \
      --dart-define=GOOGLE_SIGN_IN_ANDROID_CLIENT_ID="${GOOGLE_SIGN_IN_ANDROID_CLIENT_ID:-}"
    flutter build ios --dart-define=ENVIRONMENT=production \
      --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
      --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
      --dart-define=FIREBASE_IOS_PROD_API_KEY="${FIREBASE_IOS_PROD_API_KEY:-}" \
      --dart-define=FIREBASE_IOS_PROD_APP_ID="${FIREBASE_IOS_PROD_APP_ID:-}" \
      --dart-define=FIREBASE_IOS_PROD_MESSAGING_SENDER_ID="${FIREBASE_IOS_PROD_MESSAGING_SENDER_ID:-}" \
      --dart-define=FIREBASE_IOS_PROD_PROJECT_ID="${FIREBASE_IOS_PROD_PROJECT_ID:-}" \
      --dart-define=FIREBASE_IOS_PROD_STORAGE_BUCKET="${FIREBASE_IOS_PROD_STORAGE_BUCKET:-}" \
      --dart-define=FIREBASE_IOS_PROD_BUNDLE_ID="${FIREBASE_IOS_PROD_BUNDLE_ID:-}" \
      --dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID="${GOOGLE_SIGN_IN_IOS_CLIENT_ID:-}"
    ;;
  *)
    echo "Usage: $0 {dev|development|staging|prod|production}"
    echo ""
    echo "Examples:"
    echo "  $0 dev          # Build for development"
    echo "  $0 staging      # Build for staging"
    echo "  $0 prod         # Build for production"
    echo ""
    echo "Note: Secrets are loaded from .env file. Create .env file with your secrets."
    exit 1
    ;;
esac

echo "✅ Build completed!" 