#!/bin/bash
# Deploy Flutter Web Build to Git Repository (nookly-web)
# Usage: ./deploy-to-git.sh [environment] [branch]
# Example: ./deploy-to-git.sh development main

set -e

ENV=${1:-development}  # development, staging, or production
BRANCH=${2:-main}      # Git branch to push to

FLUTTER_DIR="/Users/manasa/flutter-projects/samples/hushmate"
DEPLOY_DIR="$FLUTTER_DIR/web-deploy"
GIT_REPO="https://github.com/manasa-ti/nookly-web.git"

echo "🚀 Flutter Web Git Deployment Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment: $ENV"
echo "Branch: $BRANCH"
echo "Deploy Directory: $DEPLOY_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$FLUTTER_DIR"

# Step 1: Build web app with environment
echo "🔨 Building Flutter web app (release mode) for $ENV..."
flutter build web --release --dart-define=ENVIRONMENT=$ENV

if [ ! -d "build/web" ]; then
    echo "❌ Build failed! build/web directory not found."
    exit 1
fi

echo "✅ Build complete!"
echo ""

# Step 2: Prepare deployment directory
echo "📦 Preparing deployment directory..."

# Remove old deployment files (but keep .git if it exists)
if [ -d "$DEPLOY_DIR" ]; then
    # Remove all files except .git
    find "$DEPLOY_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
else
    mkdir -p "$DEPLOY_DIR"
fi

# Step 3: Copy build files to deployment directory
echo "📋 Copying build files to deployment directory..."
cp -r build/web/* "$DEPLOY_DIR/"

echo "✅ Files copied!"
echo ""

# Step 4: Initialize git repository if needed
cd "$DEPLOY_DIR"

if [ ! -d ".git" ]; then
    echo "🔧 Initializing git repository..."
    git init
    git remote add origin "$GIT_REPO" 2>/dev/null || git remote set-url origin "$GIT_REPO"
    echo "✅ Git repository initialized!"
else
    echo "✅ Git repository already exists"
    # Ensure remote is set correctly
    git remote set-url origin "$GIT_REPO" 2>/dev/null || git remote add origin "$GIT_REPO"
fi

# Step 5: Checkout or create branch
echo "🌿 Checking out branch: $BRANCH"
if git show-ref --verify --quiet refs/heads/$BRANCH; then
    git checkout $BRANCH
elif git ls-remote --heads origin $BRANCH | grep -q $BRANCH; then
    git checkout -b $BRANCH origin/$BRANCH
else
    git checkout -b $BRANCH
fi

# Step 6: Add and commit changes
echo "📝 Staging changes..."
git add -A

if git diff --staged --quiet; then
    echo "⚠️  No changes to commit. Build output is identical to last commit."
else
    echo "💾 Committing changes..."
    git commit -m "Deploy web app - Environment: $ENV - $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Step 7: Push to remote
    echo "📤 Pushing to $GIT_REPO (branch: $BRANCH)..."
    git push -u origin $BRANCH
    
    echo ""
    echo "✅ Deployment complete!"
    echo "🌐 Repository: $GIT_REPO"
    echo "🌿 Branch: $BRANCH"
else
    echo ""
    echo "✅ No changes to deploy (build is identical to last commit)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Git deployment process completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Verify the files in the repository"
echo "   2. Set up hosting (GitHub Pages, Netlify, Vercel, etc.)"
echo "   3. Configure custom domain if needed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

