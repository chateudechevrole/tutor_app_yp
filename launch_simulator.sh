#!/bin/bash

# QuickTutor - iOS Simulator Launch Script
# This script helps you quickly launch your apps on iOS simulator

set -e

echo "🎯 QuickTutor iOS Simulator Launcher"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Function to list simulators
list_simulators() {
    echo "📱 Available iOS Simulators:"
    echo ""
    xcrun simctl list devices available | grep "iPhone" | nl
    echo ""
}

# Function to ensure environment is ready
check_environment() {
    echo "🔍 Checking environment..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Flutter: $(flutter --version | head -n 1)${NC}"
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ Xcode not found. Please install Xcode first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Xcode: $(xcodebuild -version | head -n 1)${NC}"
    echo ""
}

# Function to clean and prepare
prepare_build() {
    echo "🧹 Preparing build environment..."
    
    # Clean if requested
    if [ "$1" == "clean" ]; then
        echo "  → Running flutter clean..."
        flutter clean > /dev/null 2>&1
        
        echo "  → Cleaning iOS pods..."
        cd ios
        pod deintegrate > /dev/null 2>&1 || true
        rm -rf Pods Podfile.lock
        cd ..
    fi
    
    # Get dependencies
    echo "  → Getting Flutter packages..."
    flutter pub get > /dev/null 2>&1
    
    # Install pods
    echo "  → Installing CocoaPods..."
    cd ios && pod install > /dev/null 2>&1 && cd ..
    
    echo -e "${GREEN}✅ Build environment ready${NC}"
    echo ""
}

# Main menu
show_menu() {
    echo "Select an app to launch:"
    echo ""
    echo "1) Student App (main_student.dart)"
    echo "2) Tutor App (main_tutor.dart)"
    echo "3) Admin App (main_admin.dart)"
    echo "4) Main App - Role-based (main.dart)"
    echo "5) Clean & Rebuild"
    echo "6) List Simulators"
    echo "0) Exit"
    echo ""
}

# Launch app function
launch_app() {
    local target=$1
    local app_name=$2
    
    echo ""
    echo "🚀 Launching $app_name..."
    echo ""
    
    # Get list of simulators
    mapfile -t sims < <(xcrun simctl list devices available | grep "iPhone" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
    
    if [ ${#sims[@]} -eq 0 ]; then
        echo -e "${RED}❌ No simulators found${NC}"
        return
    fi
    
    # Show simulators with numbers
    echo "Select a simulator:"
    xcrun simctl list devices available | grep "iPhone" | nl
    echo ""
    
    read -p "Enter simulator number (or press Enter for first available): " sim_choice
    
    # Default to first simulator if no choice
    if [ -z "$sim_choice" ]; then
        sim_choice=1
    fi
    
    # Get the simulator ID
    sim_id=${sims[$((sim_choice-1))]}
    
    if [ -z "$sim_id" ]; then
        echo -e "${RED}❌ Invalid simulator choice${NC}"
        return
    fi
    
    echo ""
    echo -e "${GREEN}→ Running on simulator: $sim_id${NC}"
    echo ""
    
    # Launch the app
    flutter run -d "$sim_id" -t "lib/$target"
}

# Main script
main() {
    check_environment
    
    # Check for clean flag
    if [ "$1" == "clean" ] || [ "$1" == "-c" ]; then
        prepare_build "clean"
    else
        prepare_build
    fi
    
    while true; do
        show_menu
        read -p "Your choice: " choice
        
        case $choice in
            1)
                launch_app "main_student.dart" "Student App"
                ;;
            2)
                launch_app "main_tutor.dart" "Tutor App"
                ;;
            3)
                launch_app "main_admin.dart" "Admin App"
                ;;
            4)
                launch_app "main.dart" "Main App (Role-based)"
                ;;
            5)
                prepare_build "clean"
                ;;
            6)
                list_simulators
                ;;
            0)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                echo ""
                ;;
        esac
    done
}

# Run main function
main "$@"
