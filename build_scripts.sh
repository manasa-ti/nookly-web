#!/bin/bash

# Build script for Nookly app with different environments

echo "Nookly Build Script"
echo "==================="

case "$1" in
  "dev"|"development")
    echo "Building for DEVELOPMENT environment..."
    flutter build apk --dart-define=ENVIRONMENT=development
    flutter build ios --dart-define=ENVIRONMENT=development
    ;;
  "staging")
    echo "Building for STAGING environment..."
    flutter build apk --dart-define=ENVIRONMENT=staging
    flutter build ios --dart-define=ENVIRONMENT=staging
    ;;
  "prod"|"production")
    echo "Building for PRODUCTION environment..."
    flutter build apk --dart-define=ENVIRONMENT=production
    flutter build ios --dart-define=ENVIRONMENT=production
    ;;
  *)
    echo "Usage: $0 {dev|development|staging|prod|production}"
    echo ""
    echo "Examples:"
    echo "  $0 dev          # Build for development"
    echo "  $0 staging      # Build for staging"
    echo "  $0 prod         # Build for production"
    exit 1
    ;;
esac

echo "Build completed!" 