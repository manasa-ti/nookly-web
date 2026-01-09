#!/bin/bash
# Flutter Web Deployment Script
# Usage: ./deploy-web.sh [firebase|gcs] [dev|staging|prod]

set -e

DEPLOY_METHOD=${1:-firebase}  # firebase or gcs
ENV=${2:-dev}  # dev, staging, or prod

FLUTTER_DIR="/Users/manasa/flutter-projects/samples/hushmate"
PROJECT_ID="nookly-backend-367126309999"
REGION="asia-southeast1"

echo "🌐 Flutter Web Deployment Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Method: $DEPLOY_METHOD"
echo "Environment: $ENV"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$FLUTTER_DIR"

# Step 1: Clean and get dependencies
echo "📦 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Step 2: Build web app with environment variables
echo "🔨 Building Flutter web app (release mode)..."

# Determine environment for dart-define
DART_ENV="development"
if [ "$ENV" = "prod" ] || [ "$ENV" = "production" ]; then
    DART_ENV="production"
elif [ "$ENV" = "staging" ]; then
    DART_ENV="staging"
fi

# Build command with environment variables
# Note: For GitHub Pages, you should set these as GitHub Secrets and pass them here
# Example: --dart-define=HMS_APP_ID=$HMS_APP_ID
BUILD_ARGS="--release --dart-define=ENVIRONMENT=$DART_ENV"

# Add environment variables if they're set (for CI/CD)
if [ -n "$HMS_APP_ID" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=HMS_APP_ID=$HMS_APP_ID"
fi
if [ -n "$HMS_AUTH_TOKEN" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=HMS_AUTH_TOKEN=$HMS_AUTH_TOKEN"
fi
if [ -n "$FIREBASE_WEB_PROD_API_KEY" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FIREBASE_WEB_PROD_API_KEY=$FIREBASE_WEB_PROD_API_KEY"
fi
if [ -n "$FIREBASE_WEB_PROD_APP_ID" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FIREBASE_WEB_PROD_APP_ID=$FIREBASE_WEB_PROD_APP_ID"
fi
if [ -n "$FIREBASE_WEB_PROD_MESSAGING_SENDER_ID" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FIREBASE_WEB_PROD_MESSAGING_SENDER_ID=$FIREBASE_WEB_PROD_MESSAGING_SENDER_ID"
fi
if [ -n "$FIREBASE_WEB_PROD_PROJECT_ID" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FIREBASE_WEB_PROD_PROJECT_ID=$FIREBASE_WEB_PROD_PROJECT_ID"
fi
if [ -n "$FIREBASE_WEB_PROD_AUTH_DOMAIN" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FIREBASE_WEB_PROD_AUTH_DOMAIN=$FIREBASE_WEB_PROD_AUTH_DOMAIN"
fi
if [ -n "$FIREBASE_WEB_PROD_STORAGE_BUCKET" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FIREBASE_WEB_PROD_STORAGE_BUCKET=$FIREBASE_WEB_PROD_STORAGE_BUCKET"
fi
if [ -n "$FIREBASE_WEB_PROD_MEASUREMENT_ID" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FIREBASE_WEB_PROD_MEASUREMENT_ID=$FIREBASE_WEB_PROD_MEASUREMENT_ID"
fi
if [ -n "$GOOGLE_SIGN_IN_WEB_CLIENT_ID" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=GOOGLE_SIGN_IN_WEB_CLIENT_ID=$GOOGLE_SIGN_IN_WEB_CLIENT_ID"
fi

echo "⚠️  SECURITY NOTE: If deploying to GitHub Pages, ensure environment variables are set!"
echo "   See SECURITY_SETUP.md for details on using GitHub Secrets"
echo ""

flutter build web $BUILD_ARGS

if [ ! -d "build/web" ]; then
    echo "❌ Build failed! build/web directory not found."
    exit 1
fi

echo "✅ Build complete! Output: build/web/"
echo ""

# Step 3: Deploy based on method
case $DEPLOY_METHOD in
  firebase)
    echo "🔥 Deploying to Firebase Hosting..."
    
    if ! command -v firebase >/dev/null 2>&1; then
        echo "❌ Firebase CLI not found. Install with: npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if firebase.json exists
    if [ ! -f "firebase.json" ]; then
        echo "⚠️  firebase.json not found. Initializing Firebase..."
        echo "   Please run: firebase init hosting"
        echo "   Then set 'public' directory to 'build/web'"
        exit 1
    fi
    
    # Switch to correct Firebase project if needed
    if [ "$ENV" = "dev" ]; then
        firebase use --add || true
    fi
    
    # Deploy
    firebase deploy --only hosting
    
    echo ""
    echo "✅ Deployment complete!"
    echo "🌐 Your app should be live at: https://$(firebase projects:list | grep -i nookly | head -1 | awk '{print $1}').web.app"
    ;;
    
  gcs)
    echo "☁️  Deploying to Google Cloud Storage..."
    
    BUCKET_NAME="nookly-web-app-$ENV"
    
    # Check if bucket exists, create if not
    if ! gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
        echo "📦 Creating Cloud Storage bucket: $BUCKET_NAME"
        gsutil mb -l "$REGION" "gs://$BUCKET_NAME"
        
        # Make bucket publicly readable
        echo "🔓 Making bucket publicly readable..."
        gsutil iam ch allUsers:objectViewer "gs://$BUCKET_NAME"
        
        # Enable static website hosting
        echo "🌐 Enabling static website hosting..."
        gsutil web set -m index.html -e index.html "gs://$BUCKET_NAME"
    fi
    
    # Upload files
    echo "📤 Uploading files to gs://$BUCKET_NAME..."
    gsutil -m cp -r build/web/* "gs://$BUCKET_NAME/"
    
    # Set cache headers
    echo "⚙️  Setting cache headers..."
    gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" "gs://$BUCKET_NAME/**/*.@(js|css|woff|woff2|ttf|otf|png|jpg|jpeg|gif|ico|svg)"
    gsutil -m setmeta -h "Cache-Control:public, max-age=0, must-revalidate" "gs://$BUCKET_NAME/index.html"
    
    echo ""
    echo "✅ Deployment complete!"
    echo "🌐 Your app is available at:"
    echo "   http://storage.googleapis.com/$BUCKET_NAME/index.html"
    echo ""
    echo "💡 To use a custom domain, set up Cloud CDN or Load Balancer"
    ;;
    
  *)
    echo "❌ Unknown deployment method: $DEPLOY_METHOD"
    echo "   Use: firebase or gcs"
    exit 1
    ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment process completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Verify the app loads correctly"
echo "   2. Test API connectivity (check CORS)"
echo "   3. Test authentication flow"
echo "   4. Update backend CORS_ORIGINS if needed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

