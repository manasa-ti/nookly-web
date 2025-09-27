#!/bin/bash

# Enhanced Release Build Script for Nookly App
# This script automates the complete release build process for both Android and iOS

set -e  # Exit on any error

echo "🚀 Starting Release Build for Nookly App..."
echo "============================================="

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

# Get current version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
TARGET_SDK=$(grep "targetSdk" android/app/build.gradle.kts | sed 's/.*targetSdk = //' | tr -d ' ')
print_status "Building version: $VERSION"
print_status "Target SDK: $TARGET_SDK (Android 15)"

# Clean and prepare
print_step "Cleaning previous builds..."
flutter clean

print_step "Getting dependencies..."
flutter pub get

# Accept Android licenses if needed
print_step "Checking Android licenses..."
echo "y" | flutter doctor --android-licenses > /dev/null 2>&1 || true

# Build Android
print_step "Building Android App Bundle (AAB)..."
flutter build appbundle --release
print_status "✅ Android AAB built: build/app/outputs/bundle/release/app-release.aab"

print_step "Building Android APK..."
flutter build apk --release
print_status "✅ Android APK built: build/app/outputs/flutter-apk/app-release.apk"

# Build iOS
print_step "Installing iOS dependencies..."
cd ios
pod install
cd ..

print_step "Building iOS release..."
flutter build ios --release --no-codesign

print_step "Creating iOS archive..."
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath build/Runner.xcarchive archive
cd ..

print_step "Exporting iOS archive for TestFlight..."
xcodebuild -exportArchive -archivePath ios/build/Runner.xcarchive -exportPath ios/build/export -exportOptionsPlist exportOptions.plist
print_status "✅ iOS IPA built: ios/build/export/nookly.ipa"

# Summary
echo ""
echo "🎉 Build completed successfully!"
echo "================================="
echo ""
print_status "Build artifacts:"
echo "📱 Android AAB: build/app/outputs/bundle/release/app-release.aab"
echo "📱 Android APK: build/app/outputs/flutter-apk/app-release.apk"
echo "🍎 iOS IPA: ios/build/export/nookly.ipa"
echo ""
print_status "Next steps:"
echo "1. Upload Android AAB to Google Play Console for alpha testing"
echo "2. Upload iOS IPA to App Store Connect for TestFlight"
echo ""
print_warning "Make sure you have:"
echo "- Valid signing certificates and provisioning profiles"
echo "- App Store Connect app created"
echo "- Google Play Console app created"
echo ""
print_status "Build script completed! 🎉"
