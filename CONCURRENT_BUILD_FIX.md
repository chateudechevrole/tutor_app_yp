# Concurrent Build Fix - iOS/Xcode

## Problem
```
Xcode build failed due to concurrent builds, will retry in X seconds.
```

This error occurs when multiple Flutter/Xcode processes are trying to build simultaneously, or when build lock files from a previous build are stuck.

## Root Causes
1. Multiple `flutter run` commands running at the same time
2. Xcode IDE open and building while Flutter tries to build
3. Stale build lock files in `ios/build/XCBuildData`
4. Orphaned xcodebuild processes from crashed builds
5. DerivedData cache conflicts

## Immediate Fix

### Option 1: Use the Safe Launch Script (Recommended)
```bash
./run_safe.sh
```

This automatically:
- Kills existing Flutter/Xcode processes
- Removes build locks
- Cleans the workspace
- Launches your app safely

### Option 2: Manual Fix
```bash
# 1. Kill all Flutter processes
pkill -9 -f "flutter run"

# 2. Kill all Xcode processes
killall Xcode xcodebuild

# 3. Remove build locks
rm -rf ios/build/XCBuildData

# 4. Clean Xcode workspace
cd ios
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
cd ..

# 5. Try running again
flutter run -d "<device-id>" -t lib/main_student.dart
```

## Prevention Strategies

### 1. Always Close Previous Builds
Before starting a new build:
```bash
pkill -f "flutter run"  # Kill previous Flutter processes
```

### 2. Don't Run Multiple Flutter Commands
- Only run ONE `flutter run` at a time
- Wait for previous builds to complete or press `q` to quit
- Close Xcode if you're using `flutter run` from terminal

### 3. Clear Build Locks Regularly
```bash
rm -rf ios/build/XCBuildData
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 4. Disable Xcode Background Builds
If you have Xcode open:
- Xcode → Preferences → Behaviors
- Uncheck "Build" → "Starts" → "Show tab"
- Or simply close Xcode when using Flutter CLI

### 5. Use Dedicated Simulators
Don't switch between simulators mid-build. Pick one and stick with it.

## Quick Commands

### Check for Running Builds
```bash
# Check Flutter processes
ps aux | grep "flutter run"

# Check Xcode processes
ps aux | grep xcodebuild
```

### Force Kill Everything
```bash
# Nuclear option - kills all Flutter and Xcode processes
pkill -9 -f flutter
killall -9 Xcode xcodebuild
rm -rf ios/build/XCBuildData
```

### Clean Everything
```bash
flutter clean
cd ios
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
rm -rf build DerivedData
cd ..
```

## Advanced: Disable Swift Build System Integration
This can help prevent some concurrent build issues:
```bash
defaults write com.apple.dt.XCBuild EnableSwiftBuildSystemIntegration 0
```

To re-enable:
```bash
defaults delete com.apple.dt.XCBuild EnableSwiftBuildSystemIntegration
```

## Automated Solutions Created

### 1. `run_safe.sh`
Interactive launcher that prevents concurrent builds:
```bash
./run_safe.sh
```

Features:
- Automatically kills existing processes
- Removes build locks
- Cleans workspace
- Lets you choose app and simulator
- Safe to run multiple times

### 2. Quick Kill Script
```bash
# Create a quick alias
alias kill-flutter="pkill -9 -f flutter && killall -9 Xcode xcodebuild && rm -rf ios/build/XCBuildData"

# Then just run:
kill-flutter
```

## Workflow Best Practices

### Starting a New Build Session
```bash
# 1. Clean up first
pkill -f "flutter run"
rm -rf ios/build/XCBuildData

# 2. Launch safely
./run_safe.sh
```

### Switching Between Apps
```bash
# 1. Stop current app (in Flutter terminal)
Press 'q'

# 2. Wait for clean shutdown (2-3 seconds)

# 3. Launch new app
./run_safe.sh
```

### If Build Gets Stuck
```bash
# 1. Press Ctrl+C to interrupt

# 2. Clean up
pkill -9 -f flutter
rm -rf ios/build/XCBuildData

# 3. Try again
./run_safe.sh
```

## Troubleshooting Checklist

If you still get concurrent build errors:

- [ ] Check: `ps aux | grep flutter` - any processes running?
- [ ] Check: `ps aux | grep xcodebuild` - any builds active?
- [ ] Close Xcode application completely
- [ ] Remove: `rm -rf ios/build/XCBuildData`
- [ ] Remove: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
- [ ] Clean: `cd ios && xcodebuild clean -workspace Runner.xcworkspace -scheme Runner`
- [ ] Restart terminal
- [ ] Restart computer (if nothing else works)

## When to Use Each Solution

### Use `./run_safe.sh` when:
- Starting a fresh development session
- Switching between apps
- You've had concurrent build errors before

### Use manual cleanup when:
- Quick iteration needed
- You know exactly what's running
- Debugging specific build issues

### Use nuclear option when:
- Everything is stuck
- Multiple failed attempts
- Build locks won't clear

---

## Summary

**Concurrent builds are preventable!**

✅ Always use `./run_safe.sh` to launch apps  
✅ Only run ONE build at a time  
✅ Close Xcode when using Flutter CLI  
✅ Kill previous builds before starting new ones  

**Last Updated:** October 27, 2025  
**Status:** ✅ Fixed with automated scripts
