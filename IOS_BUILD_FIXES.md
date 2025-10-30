# iOS Build Issues - Solutions

## ✅ SOLVED: "Unable to find module dependency: Flutter"

### Problem
```
Swift Compiler Error (Xcode): Unable to find module dependency: 'Flutter'
import Flutter
```

### Root Cause
The Podfile had a custom `post_install` block that was overriding Flutter's required build settings.

### Solution Applied
Updated `ios/Podfile` to use the standard Flutter post_install hook:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

**Instead of the custom:**
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
```

### Steps Taken
1. ✅ Cleaned Flutter build artifacts
2. ✅ Removed iOS build cache
3. ✅ Deintegrated CocoaPods
4. ✅ Updated Podfile with correct post_install
5. ✅ Reinstalled all pods
6. ✅ Regenerated Flutter packages

### Quick Fix Command
```bash
cd /Users/yuanping/QuickTutor/quicktutor_2
./fix_ios_build.sh
```

---

## Common iOS Build Issues & Fixes

### 1. Pod Install Fails

**Symptoms:**
- Pod install hangs
- Dependency resolution errors

**Fix:**
```bash
cd ios
pod deintegrate
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### 2. Xcode Build Fails After Working Previously

**Symptoms:**
- "Framework not found"
- Module import errors

**Fix:**
```bash
flutter clean
rm -rf ios/build ios/DerivedData
flutter pub get
cd ios && pod install && cd ..
```

### 3. Flutter Framework Not Found

**Symptoms:**
- "Unable to find module dependency: 'Flutter'"
- "Framework Flutter not found"

**Fix:**
```bash
rm -rf ios/Flutter ios/.symlinks
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### 4. Xcode Version Incompatibility

**Symptoms:**
- Build settings warnings
- Deployment target errors

**Fix:**
- Ensure Xcode is up to date (currently 26.0.1)
- Check iOS deployment target in `ios/Podfile` (currently 15.0)
- Update Xcode via App Store if needed

### 5. Simulator Not Found

**Symptoms:**
- "No devices found"
- Invalid device ID

**Fix:**
```bash
# List available simulators
xcrun simctl list devices available | grep "iPhone"

# Or use Flutter's device list
flutter devices
```

### 6. Firebase Build Issues

**Symptoms:**
- Firebase pod version conflicts
- "Undefined symbols for architecture"

**Fix:**
- Ensure all Firebase pods use the same SDK version
- Check `ios/Podfile` for version pinning
- Currently using Firebase SDK 11.15.0

---

## Preventive Measures

### 1. Always Use Flutter's Post Install Hook
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### 2. Keep Dependencies Updated
```bash
flutter pub outdated
flutter pub upgrade --major-versions
```

### 3. Clean Builds Periodically
```bash
flutter clean
cd ios && pod deintegrate && pod install && cd ..
```

### 4. Verify Environment Health
```bash
flutter doctor -v
```

---

## Automated Fix Script

Created `fix_ios_build.sh` to automate the fix process:

```bash
chmod +x fix_ios_build.sh
./fix_ios_build.sh
```

This script:
1. Cleans all build artifacts
2. Removes and reinstalls CocoaPods
3. Refreshes Flutter packages
4. Precaches iOS artifacts
5. Verifies Flutter framework

---

## Current Stable Configuration

### Podfile
- Platform: iOS 15.0
- Uses `flutter_additional_ios_build_settings` in post_install
- Firebase SDK: 11.15.0 (consistent across all pods)

### Dependencies
- Flutter: 3.35.6
- Dart: 3.9.2
- Xcode: 26.0.1
- CocoaPods: 1.16.2

### Build Status
✅ All entry points building successfully on iOS simulator

---

## Troubleshooting Checklist

When encountering build issues, try in order:

- [ ] `flutter clean`
- [ ] `cd ios && pod install && cd ..`
- [ ] Remove build cache: `rm -rf ios/build ios/DerivedData`
- [ ] Deintegrate pods: `cd ios && pod deintegrate && pod install && cd ..`
- [ ] Remove Flutter framework: `rm -rf ios/Flutter ios/.symlinks`
- [ ] Run `./fix_ios_build.sh`
- [ ] Restart Xcode if open
- [ ] Restart computer (last resort)

---

**Last Updated:** October 27, 2025  
**Status:** ✅ iOS build environment stable
