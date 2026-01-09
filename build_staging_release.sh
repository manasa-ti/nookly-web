#!/bin/bash

# Staging Release Build Script for Nookly App
# This script builds release versions for staging environment

set -e  # Exit on any error

echo "🚀 Starting Staging Release Build for Nookly App..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS for iOS builds"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Xcode is installed (for iOS builds)
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
    exit 1
fi

# Load environment variables from .env file
print_step "Loading secrets from .env file..."
if [ -f ".env" ]; then
    # Source the load_env script if it exists, otherwise load directly
    if [ -f "scripts/load_env.sh" ]; then
        source scripts/load_env.sh
    else
        # Simple .env loader
        set -a
        source .env 2>/dev/null || true
        set +a
        print_status "✅ Loaded secrets from .env file"
    fi
else
    print_warning ".env file not found. Secrets will use default values (if any)."
    print_warning "Create a .env file with your secrets. See .env.example for template."
fi

# Get current version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
TARGET_SDK=$(grep "targetSdk" android/app/build.gradle.kts | sed 's/.*targetSdk = //' | tr -d ' ')
print_status "Building version: $VERSION for STAGING environment"
print_status "Target SDK: $TARGET_SDK (Android 15)"

# Clean and prepare
print_step "Cleaning previous builds..."
flutter clean

print_step "Getting dependencies..."
flutter pub get

# Accept Android licenses if needed
print_step "Checking Android licenses..."
echo "y" | flutter doctor --android-licenses > /dev/null 2>&1 || true

# Build Android with staging environment and secrets
print_step "Building Android App Bundle (AAB) for STAGING..."
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
  --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_API_KEY="${FIREBASE_ANDROID_PROD_API_KEY:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_APP_ID="${FIREBASE_ANDROID_PROD_APP_ID:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID="${FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_PROJECT_ID="${FIREBASE_ANDROID_PROD_PROJECT_ID:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_STORAGE_BUCKET="${FIREBASE_ANDROID_PROD_STORAGE_BUCKET:-}" \
  --dart-define=GOOGLE_SIGN_IN_ANDROID_CLIENT_ID="${GOOGLE_SIGN_IN_ANDROID_CLIENT_ID:-}"
print_status "✅ Android AAB built: build/app/outputs/bundle/release/app-release.aab"

print_step "Building Android APK for STAGING..."
flutter build apk --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
  --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_API_KEY="${FIREBASE_ANDROID_PROD_API_KEY:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_APP_ID="${FIREBASE_ANDROID_PROD_APP_ID:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID="${FIREBASE_ANDROID_PROD_MESSAGING_SENDER_ID:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_PROJECT_ID="${FIREBASE_ANDROID_PROD_PROJECT_ID:-}" \
  --dart-define=FIREBASE_ANDROID_PROD_STORAGE_BUCKET="${FIREBASE_ANDROID_PROD_STORAGE_BUCKET:-}" \
  --dart-define=GOOGLE_SIGN_IN_ANDROID_CLIENT_ID="${GOOGLE_SIGN_IN_ANDROID_CLIENT_ID:-}"
print_status "✅ Android APK built: build/app/outputs/flutter-apk/app-release.apk"

# Build iOS with staging environment
# Setup Ruby environment for CocoaPods (using Ruby 3.4 for SSL support)
print_step "Setting up Ruby environment for CocoaPods..."
setup_ruby_env() {
    # Priority 1: Check for Homebrew Ruby 3.4 (most common on macOS)
    if [ -d "/usr/local/Cellar/ruby" ]; then
        # Find the latest Ruby 3.4.x installation
        RUBY_34_PATH=$(ls -td /usr/local/Cellar/ruby/3.4.* 2>/dev/null | head -1)
        if [ -n "$RUBY_34_PATH" ] && [ -d "$RUBY_34_PATH/bin" ]; then
            # Remove RVM from PATH to avoid conflicts
            export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$HOME/.rvm" | tr '\n' ':' | sed 's/:$//')
            # Add Ruby 3.4 paths first
            export PATH="$RUBY_34_PATH/bin:$PATH"
            # Also add the gem bin directory for Ruby 3.4
            if [ -d "/usr/local/lib/ruby/gems/3.4.0/bin" ]; then
                export PATH="/usr/local/lib/ruby/gems/3.4.0/bin:$PATH"
            fi
            # Unset RVM variables that might interfere
            unset GEM_HOME GEM_PATH
            print_status "Using Homebrew Ruby 3.4: $RUBY_34_PATH"
        fi
    fi
    
    # Priority 2: Check for Homebrew Ruby 3.4 in alternative location
    if [ -d "/opt/homebrew/Cellar/ruby" ]; then
        RUBY_34_PATH=$(ls -td /opt/homebrew/Cellar/ruby/3.4.* 2>/dev/null | head -1)
        if [ -n "$RUBY_34_PATH" ] && [ -d "$RUBY_34_PATH/bin" ]; then
            # Remove RVM from PATH to avoid conflicts
            export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "$HOME/.rvm" | tr '\n' ':' | sed 's/:$//')
            # Add Ruby 3.4 paths first
            export PATH="$RUBY_34_PATH/bin:$PATH"
            # Also add the gem bin directory for Ruby 3.4 (Apple Silicon)
            if [ -d "/opt/homebrew/lib/ruby/gems/3.4.0/bin" ]; then
                export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
            fi
            # Unset RVM variables that might interfere
            unset GEM_HOME GEM_PATH
            print_status "Using Homebrew Ruby 3.4 (Apple Silicon): $RUBY_34_PATH"
        fi
    fi
    
    # Priority 3: Try RVM with Ruby 3.4
    if [ -s "$HOME/.rvm/scripts/rvm" ]; then
        source "$HOME/.rvm/scripts/rvm" 2>/dev/null || true
        if command -v rvm &> /dev/null; then
            # Check if ruby-3.4 exists
            if [ -d "$HOME/.rvm/gems/ruby-3.4" ] || rvm list | grep -q "ruby-3.4"; then
                rvm use 3.4 2>/dev/null || {
                    # Try to set PATH manually for RVM Ruby 3.4
                    RUBY_34_GEMS=$(ls -td "$HOME/.rvm/gems/ruby-3.4"* 2>/dev/null | head -1)
                    if [ -n "$RUBY_34_GEMS" ] && [ -d "$RUBY_34_GEMS/bin" ]; then
                        export PATH="$RUBY_34_GEMS/bin:$PATH"
                    fi
                }
            fi
        fi
    fi
    
    # Priority 4: Check for rbenv with Ruby 3.4
    if [ -s "$HOME/.rbenv/bin/rbenv" ]; then
        eval "$(rbenv init -)" 2>/dev/null || true
        if command -v rbenv &> /dev/null; then
            rbenv shell 3.4 2>/dev/null || rbenv local 3.4 2>/dev/null || true
        fi
    fi
    
    # Verify Ruby 3.4 is being used
    CURRENT_RUBY_VERSION=$(ruby --version 2>/dev/null || echo "unknown")
    if echo "$CURRENT_RUBY_VERSION" | grep -q "3\.4"; then
        print_status "✅ Ruby 3.4 detected: $CURRENT_RUBY_VERSION"
    else
        print_warning "Ruby version: $CURRENT_RUBY_VERSION (expected 3.4.x)"
    fi
    
    # Check and install bigdecimal gem if needed (required for Ruby 3.4)
    # Use Ruby 3.4's gem directly to avoid RVM interference
    RUBY_34_GEM=""
    if [ -f "/usr/local/Cellar/ruby/3.4.7/bin/gem" ]; then
        RUBY_34_GEM="/usr/local/Cellar/ruby/3.4.7/bin/gem"
    elif [ -f "/opt/homebrew/Cellar/ruby/3.4.7/bin/gem" ]; then
        RUBY_34_GEM="/opt/homebrew/Cellar/ruby/3.4.7/bin/gem"
    fi
    
    if [ -n "$RUBY_34_GEM" ]; then
        # Unset RVM variables before running gem commands
        unset GEM_HOME GEM_PATH
        if ! "$RUBY_34_GEM" list bigdecimal -i &>/dev/null 2>&1; then
            print_status "Installing bigdecimal gem (required for Ruby 3.4)..."
            "$RUBY_34_GEM" install bigdecimal --no-document 2>&1 | grep -v -E "Ignoring|Error loading" || true
        fi
    fi
    
    # Verify pod is available - use direct path to avoid RVM conflicts
    # POD_BINARY is set as a global variable
    GEM_PATHS=(
        "/usr/local/lib/ruby/gems/3.4.0/bin"
        "/opt/homebrew/lib/ruby/gems/3.4.0/bin"
        "$HOME/.gem/ruby/3.4.0/bin"
    )
    
    for GEM_PATH in "${GEM_PATHS[@]}"; do
        if [ -f "$GEM_PATH/pod" ]; then
            POD_BINARY="$GEM_PATH/pod"
            export PATH="$GEM_PATH:$PATH"
            break
        fi
    done
    
    # If still not found, check if pod is in PATH but verify it's the right one
    if [ -z "$POD_BINARY" ]; then
        POD_BINARY=$(which pod 2>/dev/null || echo "")
        if [ -n "$POD_BINARY" ]; then
            # Check if it's from RVM (we don't want that)
            if echo "$POD_BINARY" | grep -q "\.rvm"; then
                POD_BINARY=""
            fi
        fi
    fi
    
    if [ -z "$POD_BINARY" ] || [ ! -f "$POD_BINARY" ]; then
        print_error "CocoaPods (pod) is not available with Ruby 3.4."
        print_error "Please install CocoaPods with Ruby 3.4:"
        print_error "  /usr/local/Cellar/ruby/3.4.7/bin/gem install cocoapods"
        exit 1
    fi
    
    # Display Ruby and CocoaPods versions
    RUBY_VERSION=$(ruby --version 2>/dev/null || echo "unknown")
    POD_VERSION=$(pod --version 2>/dev/null || echo "unknown")
    print_status "Ruby: $RUBY_VERSION"
    print_status "CocoaPods: $POD_VERSION"
}

POD_BINARY=""
setup_ruby_env

print_step "Installing iOS dependencies..."
cd ios
# Unset RVM variables before running pod install
unset GEM_HOME GEM_PATH
# Use the pod binary directly to ensure we're using Ruby 3.4's CocoaPods
if [ -n "$POD_BINARY" ] && [ -f "$POD_BINARY" ]; then
    "$POD_BINARY" install 2>&1 | grep -v -E "Ignoring|Error loading" || true
else
    # Fallback: try to find pod again
    POD_BINARY=$(which pod 2>/dev/null | grep -v "\.rvm" | head -1)
    if [ -n "$POD_BINARY" ] && [ -f "$POD_BINARY" ]; then
        "$POD_BINARY" install 2>&1 | grep -v -E "Ignoring|Error loading" || true
    else
        pod install 2>&1 | grep -v -E "Ignoring|Error loading" || true
    fi
fi
cd ..

print_step "Building iOS release for STAGING..."
flutter build ios --release --no-codesign \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=HMS_APP_ID="${HMS_APP_ID:-}" \
  --dart-define=HMS_AUTH_TOKEN="${HMS_AUTH_TOKEN:-}" \
  --dart-define=FIREBASE_IOS_PROD_API_KEY="${FIREBASE_IOS_PROD_API_KEY:-}" \
  --dart-define=FIREBASE_IOS_PROD_APP_ID="${FIREBASE_IOS_PROD_APP_ID:-}" \
  --dart-define=FIREBASE_IOS_PROD_MESSAGING_SENDER_ID="${FIREBASE_IOS_PROD_MESSAGING_SENDER_ID:-}" \
  --dart-define=FIREBASE_IOS_PROD_PROJECT_ID="${FIREBASE_IOS_PROD_PROJECT_ID:-}" \
  --dart-define=FIREBASE_IOS_PROD_STORAGE_BUCKET="${FIREBASE_IOS_PROD_STORAGE_BUCKET:-}" \
  --dart-define=FIREBASE_IOS_PROD_BUNDLE_ID="${FIREBASE_IOS_PROD_BUNDLE_ID:-}" \
  --dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID="${GOOGLE_SIGN_IN_IOS_CLIENT_ID:-}"

print_step "Creating iOS archive..."
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath build/Runner.xcarchive archive
cd ..

print_step "Exporting iOS archive for TestFlight..."
xcodebuild -exportArchive -archivePath ios/build/Runner.xcarchive -exportPath ios/build/export -exportOptionsPlist exportOptions.plist
print_status "✅ iOS IPA built: ios/build/export/nookly.ipa"

# Summary
echo ""
echo "🎉 Staging Release Build completed successfully!"
echo "=============================================="
echo ""
print_status "Build artifacts (STAGING environment):"
echo "📱 Android AAB: build/app/outputs/bundle/release/app-release.aab"
echo "📱 Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "🍎 iOS IPA: ios/build/export/nookly.ipa"
echo ""
print_status "Environment: STAGING"
print_status "API Base URL: https://staging.nookly.app/api"
print_status "WebSocket URL: wss://staging.nookly.app"
echo ""
print_status "Next steps:"
echo "1. Upload Android AAB to Google Play Console for internal testing"
echo "2. Upload iOS IPA to App Store Connect for TestFlight (staging)"
echo ""
print_warning "Make sure you have:"
echo "- Valid signing certificates and provisioning profiles"
echo "- App Store Connect app created"
echo "- Google Play Console app created"
echo ""
print_status "Staging release build script completed! 🎉"



