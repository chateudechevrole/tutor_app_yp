# FlutterFire Configuration Instructions

## IMPORTANT: Run these steps AFTER code generation is complete

### Step 1: Configure FlutterFire
Run the following command in your terminal:
```bash
flutterfire configure --platforms=android,ios
```

This will:
- Create a Firebase project (or let you select an existing one)
- Register your apps for Android and iOS
- Generate `lib/firebase_options.dart` with your Firebase configuration

### Step 2: Verify Application IDs
Make sure the Android `applicationId` and iOS `bundle id` match the apps you add in Firebase Console:

**Android**: Check `android/app/build.gradle.kts` for `applicationId`
**iOS**: Check `ios/Runner.xcodeproj/project.pbxproj` for `PRODUCT_BUNDLE_IDENTIFIER`

### Step 3: Verify Generated File
Confirm that `lib/firebase_options.dart` has been created and contains your Firebase configuration.

### Step 4: Deploy Firestore Rules
In the Firebase Console:
1. Go to Firestore Database → Rules
2. Copy the content from `firestore.rules` in this project
3. Paste and publish the rules

### Step 5: Enable Authentication
In the Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable "Email/Password" provider

### Step 6: Create Firestore Database
In the Firebase Console:
1. Go to Firestore Database
2. Click "Create database"
3. Start in "test mode" (we'll apply rules after)

---

Once these steps are complete, you can run the app with:
```bash
flutter run -t lib/main.dart
```
