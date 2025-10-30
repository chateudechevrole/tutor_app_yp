# iOS Simulator Quick Start Guide

## ✅ Environment Status

Your Flutter environment is **stable and ready**:

- ✅ Flutter 3.35.6 (stable channel)
- ✅ Dart 3.9.2
- ✅ Xcode 26.0.1
- ✅ CocoaPods 1.16.2
- ✅ All Firebase pods installed (Firebase SDK 11.15.0)
- ✅ No critical errors in code analysis

## 🚀 Quick Launch Commands

### Student App
```bash
flutter run -d <simulator-id> -t lib/main_student.dart
```

### Tutor App
```bash
flutter run -d <simulator-id> -t lib/main_tutor.dart
```

### Admin App
```bash
flutter run -d <simulator-id> -t lib/main_admin.dart
```

### Main App (Role-based routing)
```bash
flutter run -d <simulator-id> -t lib/main.dart
```

## 📱 Available Simulators

```
iPhone 17 Pro       : 8E50B3D4-6FA1-4744-B8CD-62B5F9CA2EE3
iPhone 17 Pro Max   : CED6A978-13E8-4AEC-A5DE-28540D025EA7
iPhone Air          : 8740D4BC-0FF1-489A-9581-E621B8909182
iPhone 17           : ED5A98AB-816C-4215-9BD0-49CAB193DB6A
iPhone 16e          : C6C738AA-0DAA-4009-BC9E-76BDD0832FB8
iPhone 16e (Tutor)  : 0E1258B5-2DB9-4671-B9BF-C0362494F98E
```

### Example Launch:
```bash
# Launch student app on iPhone 17
flutter run -d ED5A98AB-816C-4215-9BD0-49CAB193DB6A -t lib/main_student.dart

# Launch tutor app on iPhone 16e (Tutor)
flutter run -d 0E1258B5-2DB9-4671-B9BF-C0362494F98E -t lib/main_tutor.dart
```

## 🔧 Troubleshooting

### If you encounter build issues:

1. **Clean everything:**
   ```bash
   flutter clean
   cd ios && pod deintegrate && pod install && cd ..
   flutter pub get
   ```

2. **Rebuild:**
   ```bash
   flutter build ios --simulator --debug -t lib/main_student.dart
   ```

3. **VS Code analyzer issues:**
   - Command Palette → "Developer: Reload Window"
   - Or restart VS Code

### Common Issues

#### Pod Install Fails
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

#### Xcode Build Fails
```bash
# Open workspace in Xcode and clean build folder
open ios/Runner.xcworkspace
# In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
```

#### Firebase Errors
- Ensure `ios/Runner/GoogleService-Info.plist` exists
- Check Firebase project configuration in console

## 📦 Installed Packages

### Firebase
- firebase_core: 3.15.2
- firebase_auth: 5.7.0
- cloud_firestore: 5.6.12
- firebase_storage: 12.4.10
- firebase_messaging: 15.2.10

### Other
- image_picker: 1.0.7
- url_launcher: 6.2.5

## 🔔 Push Notifications Note

Push notifications require:
- **Physical device** (not simulator) for iOS
- Xcode capabilities: Push Notifications + Background Modes
- Firebase APNs configuration

On simulator, push features will be initialized but won't receive actual notifications.

## 🎯 Development Tips

### Hot Reload
Press `r` in terminal while app is running

### Hot Restart
Press `R` in terminal while app is running

### View Logs
```bash
# In separate terminal
flutter logs
```

### Check for Issues
```bash
flutter doctor -v
flutter pub outdated
flutter analyze
```

## 📝 Project Structure

```
lib/
├── main.dart              # Role-based routing
├── main_student.dart      # Student-only entry
├── main_tutor.dart        # Tutor-only entry
├── main_admin.dart        # Admin-only entry
├── features/
│   ├── auth/
│   ├── student/
│   ├── tutor/
│   └── admin/
└── services/
    ├── auth_service.dart
    └── push/
        ├── push_service.dart
        └── push_background.dart
```

## ✨ Current Features

- ✅ Multi-role authentication (Student/Tutor/Admin)
- ✅ Tutor profile with avatar upload
- ✅ Subject/Language/Grade pickers
- ✅ Student booking flow
- ✅ Push notifications (device-ready)
- ✅ Firestore integration
- ✅ Firebase Storage for photos

---

**Last Updated:** October 26, 2025  
**Environment:** macOS 15.7, Xcode 26.0.1, Flutter 3.35.6
