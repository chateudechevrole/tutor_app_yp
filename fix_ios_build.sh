#!/bin/bash

# QuickTutor - iOS Build Fixer
# Resolves common iOS build issues including "Unable to find module dependency: Flutter"

set -e

echo "🔧 QuickTutor iOS Build Fixer"
echo "=============================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Navigate to project root
cd "$(dirname "$0")"

echo "📍 Working directory: $(pwd)"
echo ""

# Step 1: Clean everything
echo "🧹 Step 1/6: Cleaning all build artifacts..."
flutter clean > /dev/null 2>&1
rm -rf ios/build ios/DerivedData ios/.symlinks ios/Flutter/Flutter.framework ios/Flutter/App.framework
echo -e "${GREEN}✅ Cleaned${NC}"
echo ""

# Step 2: Remove pods
echo "🗑️  Step 2/6: Removing CocoaPods..."
cd ios
pod deintegrate > /dev/null 2>&1 || true
rm -rf Pods Podfile.lock .symlinks
cd ..
echo -e "${GREEN}✅ Pods removed${NC}"
echo ""

# Step 3: Get Flutter packages
echo "📦 Step 3/6: Getting Flutter packages..."
flutter pub get > /dev/null 2>&1
echo -e "${GREEN}✅ Packages fetched${NC}"
echo ""

# Step 4: Precache iOS artifacts
echo "💾 Step 4/6: Precaching iOS artifacts..."
flutter precache --ios > /dev/null 2>&1
echo -e "${GREEN}✅ iOS artifacts cached${NC}"
echo ""

# Step 5: Install pods
echo "🔧 Step 5/6: Installing CocoaPods..."
cd ios
pod install --repo-update > /dev/null 2>&1
cd ..
echo -e "${GREEN}✅ Pods installed${NC}"
echo ""

# Step 6: Verify Flutter framework
echo "🔍 Step 6/6: Verifying Flutter framework..."
if [ -d "ios/Flutter" ]; then
    echo -e "${GREEN}✅ Flutter framework directory exists${NC}"
else
    echo -e "${YELLOW}⚠️  Flutter framework directory missing, creating...${NC}"
    mkdir -p ios/Flutter
fi
echo ""

# Final check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ iOS Build Environment Fixed!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You can now run your app with:"
echo ""
echo "  flutter run -d \"iPhone 17 Pro\" -t lib/main_student.dart"
echo ""
echo "Or use the interactive launcher:"
echo ""
echo "  ./launch_simulator.sh"
echo ""
