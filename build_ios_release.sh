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

# Setup Ruby environment for CocoaPods (using Ruby 3.4 for SSL support)
print_status "Setting up Ruby environment for CocoaPods..."
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

print_status "Installing iOS dependencies..."
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