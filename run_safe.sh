#!/bin/bash

# QuickTutor - Safe iOS Run Script
# Prevents concurrent build issues by cleaning up before running

set -e

echo "🔧 Safe iOS Launcher"
echo "===================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")"

# Step 1: Kill any existing Flutter/Xcode processes
echo "🧹 Step 1/4: Cleaning up existing processes..."
pkill -9 -f "flutter run" 2>/dev/null || true
killall Xcode xcodebuild 2>/dev/null || true
sleep 1
echo -e "${GREEN}✅ Processes cleaned${NC}"
echo ""

# Step 2: Remove build locks
echo "🔓 Step 2/4: Removing build locks..."
rm -rf ios/build/XCBuildData 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
echo -e "${GREEN}✅ Locks removed${NC}"
echo ""

# Step 3: Clean Xcode workspace
echo "🧼 Step 3/4: Cleaning Xcode workspace..."
cd ios
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner -configuration Debug > /dev/null 2>&1 || true
cd ..
echo -e "${GREEN}✅ Workspace cleaned${NC}"
echo ""

# Step 4: Choose app and simulator
echo "📱 Step 4/4: Select app to launch"
echo ""
echo "Select an app:"
echo "1) Student App (main_student.dart)"
echo "2) Tutor App (main_tutor.dart)"
echo "3) Admin App (main_admin.dart)"
echo "4) Main App (main.dart)"
echo ""

read -p "Your choice (1-4): " app_choice

case $app_choice in
    1) TARGET="lib/main_student.dart" APP_NAME="Student App" ;;
    2) TARGET="lib/main_tutor.dart" APP_NAME="Tutor App" ;;
    3) TARGET="lib/main_admin.dart" APP_NAME="Admin App" ;;
    4) TARGET="lib/main.dart" APP_NAME="Main App" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo ""
echo "Select a simulator:"
echo "1) iPhone 17 Pro"
echo "2) iPhone 17"
echo "3) iPhone 16e (Tutor)"
echo "4) First available"
echo ""

read -p "Your choice (1-4): " sim_choice

case $sim_choice in
    1) DEVICE="8E50B3D4-6FA1-4744-B8CD-62B5F9CA2EE3" SIM_NAME="iPhone 17 Pro" ;;
    2) DEVICE="ED5A98AB-816C-4215-9BD0-49CAB193DB6A" SIM_NAME="iPhone 17" ;;
    3) DEVICE="0E1258B5-2DB9-4671-B9BF-C0362494F98E" SIM_NAME="iPhone 16e (Tutor)" ;;
    4) DEVICE="" SIM_NAME="First available" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🚀 Launching $APP_NAME on $SIM_NAME${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Hot reload: Press 'r'"
echo "Hot restart: Press 'R'"
echo "Quit: Press 'q'"
echo ""

# Launch the app
if [ -z "$DEVICE" ]; then
    flutter run -t "$TARGET"
else
    flutter run -d "$DEVICE" -t "$TARGET"
fi
