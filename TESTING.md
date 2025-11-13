# QuickTutor - Testing Guide

## Search & Visibility Testing

### Prerequisites
1. Firebase Console access
2. At least one tutor account with:
   - `tutorProfiles/{uid}.verified = true`
   - `tutorProfiles/{uid}.online = true`
   - `tutorProfiles/{uid}.isBusy = false`

### Test 1: Tutor Appears in Search When Online

**Steps:**
1. Run tutor app: `flutter run -d "iPhone 16e (Tutor)" -t lib/main_tutor.dart`
2. Login as verified tutor
3. Toggle "Online" switch to ON
4. Verify Firestore: `tutorProfiles/{uid}.online = true`
5. Run student app: `flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart`
6. Login as student
7. Navigate to Home tab

**Expected:**
- Console shows: `[search] tutors returned: N (online + verified + not busy)` where N >= 1
- Tutor appears in the list
- Tutor card shows name, photo, subjects, grades

**Actual:** ___________

---

### Test 2: Tutor Disappears When Going Offline

**Steps:**
1. With tutor showing in student search (from Test 1)
2. In tutor app, toggle "Online" switch to OFF
3. Wait 1-2 seconds
4. Check student app

**Expected:**
- Console shows: `[search] tutors returned: M` where M = N-1
- Tutor no longer appears in student list
- If M = 0, shows "No tutors online for this filter yet."

**Actual:** ___________

---

### Test 3: Filter by Grade

**Steps:**
1. Ensure at least one tutor is online with `grades: ["Form 1"]`
2. In student app, tap "Grade" filter chip
3. Select "Form 1"
4. Tap "Apply"

**Expected:**
- Only shows tutors with "Form 1" in their grades array
- Console shows: `[search] tutors returned: X`

**Actual:** ___________

---

### Test 4: Clear Filters

**Steps:**
1. With filters applied (from Test 3)
2. Tap any filter chip
3. Tap "Clear" button

**Expected:**
- All filters reset to placeholder text ("Grade", "Subject", etc.)
- Shows all online, verified, non-busy tutors
- Console shows increased tutor count

**Actual:** ___________

---

### Test 5: Busy Tutors Hidden

**Steps:**
1. Set tutor's `isBusy = true` in Firestore manually
2. Check student search

**Expected:**
- Tutor does NOT appear even if online and verified
- Console log excludes this tutor from count

**Actual:** ___________

---

## iOS Status Bar / AppBar Testing

### Test 6: No White Bar Above AppBar

**Steps:**
1. Run student app on iPhone simulator
2. Navigate to each tab: Home, Messages, Profile
3. Look at the top of each screen

**Expected:**
- ✅ No extra white space above AppBar
- ✅ Status bar (time, battery) blends with white AppBar
- ✅ Status bar icons are dark/black (readable on white)
- ✅ AppBar has subtle shadow below it

**Actual for Home:** ___________
**Actual for Messages:** ___________
**Actual for Profile:** ___________

---

### Test 7: AppBar Consistency

**Steps:**
1. Open all three student screens
2. Compare AppBars

**Expected:**
- All have white background
- All have same elevation (1)
- All have dark text
- All have systemOverlayStyle.dark

**Actual:** ___________

---

## Push Notifications Testing

### Prerequisites
- **IMPORTANT:** FCM push requires a **real iOS/Android device**
- Simulators won't receive push notifications
- Firebase project must have Cloud Functions deployed

---

### Test 8: FCM Token Saved (Student)

**Steps:**
1. Run student app on real device
2. Login
3. Grant notification permission when prompted
4. Check console output
5. Check Firestore: `users/{studentUid}.fcmTokens`

**Expected Console:**
```
🔔 Notification permission status: AuthorizationStatus.authorized
✅ FCM Token obtained: [first 20 chars]...
✅ FCM token saved for [uid]
```

**Expected Firestore:**
```json
{
  "fcmTokens": ["cXY...abc"],
  "updatedAt": Timestamp
}
```

**Actual:** ___________

---

### Test 9: FCM Token Saved (Tutor)

**Steps:**
1. Run tutor app on real device
2. Login
3. Grant notification permission
4. Check console and Firestore (same as Test 8)

**Expected:**
- Same as Test 8 but for tutor UID

**Actual:** ___________

---

### Test 10: Booking Accepted → Student Receives Push

**Prerequisites:**
- Student and tutor both have FCM tokens saved
- Cloud Functions deployed

**Steps:**
1. Student creates a booking request
2. Tutor accepts the booking
3. Check student device

**Expected:**
- Student receives push notification
- Notification title: "Booking Accepted" (or similar)
- Tapping notification opens Messages tab

**Actual:** ___________

---

### Test 11: New Message → Push Notification

**Prerequisites:**
- Active booking between student and tutor

**Steps:**
1. Student sends a message to tutor
2. Check tutor device (app in background)

**Expected:**
- Tutor receives push notification
- Notification shows message preview
- Tapping notification opens chat

**Actual:** ___________

---

### Test 12: Foreground Message Handling

**Steps:**
1. Open student app
2. While app is active, have tutor accept a booking

**Expected:**
- SnackBar appears in student app (green background)
- Shows "Booking Accepted" message
- "View" action navigates to Messages tab

**Actual:** ___________

---

### Test 13: Background Message Handling

**Steps:**
1. Open student app, then minimize/background it
2. Have tutor accept a booking
3. Check device notification center

**Expected:**
- System notification appears
- Tapping it brings app to foreground
- Navigates to Messages tab

**Actual:** ___________

---

### Test 14: App Launched from Notification

**Steps:**
1. Force quit student app
2. Have tutor send a message
3. Tap notification in notification center

**Expected:**
- App launches
- Opens directly to Messages tab
- Shows the booking with new message

**Actual:** ___________

---

### Test 15: Token Refresh

**Steps:**
1. Login to app
2. Wait for token refresh (can take hours/days in production)
3. OR manually trigger by reinstalling app
4. Check console logs

**Expected Console:**
```
✅ Refreshed FCM token saved for [uid]
```

**Expected Firestore:**
- `fcmTokens` array contains new token
- Old token may still be present (array union)

**Actual:** ___________

---

## iOS-Specific Setup Verification

### Test 16: Push Capabilities Enabled

**Steps:**
1. Open Xcode project: `open ios/Runner.xcworkspace`
2. Select Runner target
3. Go to "Signing & Capabilities" tab

**Expected:**
- ✅ Push Notifications capability present
- ✅ Background Modes capability present
  - ✅ "Remote notifications" checked

**Actual:** ___________

---

### Test 17: GoogleService-Info.plist Present

**Steps:**
1. Check `ios/Runner/GoogleService-Info.plist` exists
2. Open in text editor
3. Verify contains:
   - `PROJECT_ID`: quicktutor2
   - `GCM_SENDER_ID`
   - `BUNDLE_ID`: com.example.quicktutor2

**Expected:**
- File exists with correct values

**Actual:** ___________

---

### Test 18: AppDelegate Configuration

**Steps:**
1. Open `ios/Runner/AppDelegate.swift`
2. Check for Firebase initialization

**Expected:**
```swift
import Firebase
// ...
FirebaseApp.configure()
```

**Actual:** ___________

---

## Android-Specific Setup Verification

### Test 19: google-services.json Present

**Steps:**
1. Check `android/app/google-services.json` exists
2. Verify contains project ID "quicktutor2"

**Expected:**
- File exists with correct project

**Actual:** ___________

---

### Test 20: Android Manifest Permissions

**Steps:**
1. Open `android/app/src/main/AndroidManifest.xml`
2. Check for:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

**Expected:**
- Permissions present

**Actual:** ___________

---

## Troubleshooting

### Search Returns 0 Tutors

**Debug Steps:**
1. Check Firestore console → tutorProfiles collection
2. Verify at least one doc has:
   - `online: true`
   - `verified: true`
   - `isBusy: false`
3. Check console logs for errors
4. Try clearing all filters
5. Check Firestore indexes are deployed:
   ```bash
   firebase firestore:indexes
   ```

**Common Causes:**
- All tutors offline
- All tutors busy
- No verified tutors
- Index not built yet (wait 5-10 min after deploy)

---

### Push Not Received

**Debug Steps:**
1. Check device notification settings:
   - Settings → QuickTutor → Notifications → Allowed
2. Check FCM token in Firestore:
   - `users/{uid}.fcmTokens` not empty
3. Check Cloud Functions logs:
   - Firebase Console → Functions → Logs
4. Verify device is REAL device (not simulator)
5. Check internet connection

**Common Causes:**
- Simulator (FCM requires real device)
- Notifications disabled in settings
- Cloud Functions not deployed
- fcmToken not saved
- Wrong project configuration

---

### White Bar Above AppBar (iOS)

**Debug Steps:**
1. Check `extendBodyBehindAppBar: false` in Scaffold
2. Check `systemOverlayStyle: SystemUiOverlayStyle.dark` in AppBar
3. Look for extra SafeArea widgets
4. Check AppBar `backgroundColor: Colors.white`

**Common Causes:**
- extendBodyBehindAppBar: true
- Missing systemOverlayStyle
- Double SafeArea
- Transparent AppBar background

---

## Success Criteria

### Search
- ✅ Online tutors appear within 1-2 seconds
- ✅ Offline tutors disappear within 1-2 seconds
- ✅ Filters work correctly
- ✅ Clear filters shows all tutors
- ✅ Busy tutors hidden

### iOS UI
- ✅ No white bar above AppBar
- ✅ Status bar blends with AppBar
- ✅ Dark status bar icons on white
- ✅ Subtle shadow below AppBar

### Push (Student)
- ✅ Token saved on login
- ✅ Receives booking accepted notification
- ✅ Receives new message notification
- ✅ Foreground shows SnackBar
- ✅ Background shows system notification
- ✅ Tap opens correct screen

### Push (Tutor)
- ✅ Token saved on login
- ✅ Receives new booking notification
- ✅ Receives new message notification
- ✅ Foreground shows SnackBar
- ✅ Background shows system notification

---

## Quick Commands

```bash
# Run student app
flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart

# Run tutor app
flutter run -d "iPhone 16e (Tutor)" -t lib/main_tutor.dart

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Check indexes status
firebase firestore:indexes

# View Cloud Functions logs
firebase functions:log

# Clear Firestore cache (if needed)
flutter clean
flutter pub get
```

---

**Testing Date:** ___________
**Tested By:** ___________
**Overall Status:** ___________
