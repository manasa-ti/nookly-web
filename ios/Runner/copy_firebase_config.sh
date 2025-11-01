#!/bin/bash

# Script to copy the correct GoogleService-Info.plist based on build configuration
# This script should be added as a Run Script build phase in Xcode

# Get the build configuration
# In Xcode, CONFIGURATION will be "Debug" or "Release"
# For Flutter, we check if it's a debug build by looking at the configuration

if [ "${CONFIGURATION}" == "Debug" ]; then
    echo "Using Development Firebase config (nookly-dev)"
    cp "${PROJECT_DIR}/Runner/GoogleService-Info-Dev.plist" "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
else
    echo "Using Production/Staging Firebase config (nookly-18de4)"
    # For Release builds, use the production config
    # The production GoogleService-Info.plist should already be in place
    # This assumes the production file is the default one
fi

