#!/bin/bash

# iOS Release Build Script for Nookly App
# This script automates the iOS release build process

set -e  # Exit on any error

echo "🚀 Starting iOS Release Build for Nookly App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
    exit 1
fi

print_status "Checking Flutter version..."
flutter --version

print_status "Cleaning previous builds..."
flutter clean

print_status "Getting dependencies..."
flutter pub get

print_status "Installing iOS dependencies..."
cd ios
pod install
cd ..

print_status "Building iOS release..."
flutter build ios --release --no-codesign

print_status "Build completed successfully!"
print_status "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Any iOS Device' as target"
echo "3. Go to Product → Archive"
echo "4. Follow the distribution steps in the Organizer"

print_warning "Make sure you have:"
echo "- Apple Developer Account"
echo "- Valid certificates and provisioning profiles"
echo "- App Store Connect app created"
echo "- Updated exportOptions.plist with your Team ID"

echo ""
print_status "Build script completed! 🎉" 