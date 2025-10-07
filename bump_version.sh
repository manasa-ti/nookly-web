#!/bin/bash

# Version Bump Script for Nookly App
# Usage: ./bump_version.sh [major|minor|patch|build]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo "Current version: $CURRENT_VERSION"

# Parse current version
IFS='+' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
VERSION_NAME=${VERSION_PARTS[0]}
BUILD_NUMBER=${VERSION_PARTS[1]:-1}

IFS='.' read -ra VERSION_COMPONENTS <<< "$VERSION_NAME"
MAJOR=${VERSION_COMPONENTS[0]:-1}
MINOR=${VERSION_COMPONENTS[1]:-0}
PATCH=${VERSION_COMPONENTS[2]:-0}

echo "Parsed version: Major=$MAJOR, Minor=$MINOR, Patch=$PATCH, Build=$BUILD_NUMBER"

# Determine bump type
BUMP_TYPE=${1:-build}

case $BUMP_TYPE in
    "major")
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        ;;
    "minor")
        MINOR=$((MINOR + 1))
        PATCH=0
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        ;;
    "patch")
        PATCH=$((PATCH + 1))
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        ;;
    "build")
        BUILD_NUMBER=$((BUILD_NUMBER + 1))
        ;;
    *)
        print_error "Invalid bump type: $BUMP_TYPE"
        echo "Usage: $0 [major|minor|patch|build]"
        echo ""
        echo "Examples:"
        echo "  $0 build    # Increment build number only (default)"
        echo "  $0 patch    # Increment patch version (1.0.2 -> 1.0.3)"
        echo "  $0 minor    # Increment minor version (1.0.2 -> 1.1.0)"
        echo "  $0 major    # Increment major version (1.0.2 -> 2.0.0)"
        exit 1
        ;;
esac

# Create new version
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_NUMBER"

print_step "Bumping version from $CURRENT_VERSION to $NEW_VERSION"

# Update pubspec.yaml
sed -i.bak "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml

# Update android/app/build.gradle.kts
sed -i.bak "s/versionCode = [0-9]*/versionCode = $BUILD_NUMBER/" android/app/build.gradle.kts
sed -i.bak "s/versionName = \"[^\"]*\"/versionName = \"$MAJOR.$MINOR.$PATCH\"/" android/app/build.gradle.kts

# Remove backup files
rm pubspec.yaml.bak android/app/build.gradle.kts.bak

print_status "✅ Version updated to $NEW_VERSION"

# Display version info
echo ""
echo "📱 Version Information:"
echo "   Version Name: $MAJOR.$MINOR.$PATCH"
echo "   Build Number: $BUILD_NUMBER"
echo "   Full Version: $NEW_VERSION"
echo ""

# Check if we should run build
read -p "Do you want to run the release build now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Running release build..."
    ./build_release.sh
else
    print_status "Version bumped successfully. Run './build_release.sh' when ready to build."
fi
