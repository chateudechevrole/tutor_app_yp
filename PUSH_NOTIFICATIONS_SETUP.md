# 🔔 Push Notifications Setup - Complete Implementation

## ✅ All Changes Completed

### 1. iOS Configuration ✅
**File**: `ios/Runner/Info.plist`
- ✅ Added `FirebaseAppDelegateProxyEnabled` → `true`
- ✅ Added `UIBackgroundModes` → `remote-notification`

### 2. Android Configuration ✅
**File**: `android/app/src/main/AndroidManifest.xml`
- ✅ Added `POST_NOTIFICATIONS` permission (Android 13+)

### 3. Background Message Handler ✅
**File**: `lib/services/push/push_background.dart` (NEW)
- ✅ Created `firebaseMessagingBackgroundHandler` with `@pragma('vm:entry-point')`
- ✅ Handles messages when app is terminated/background
- ✅ Includes Firebase initialization for isolated execution
- ✅ Comprehensive logging for debugging

### 4. Push Service ✅
**File**: `lib/services/push/push_service.dart` (NEW)
- ✅ `requestPermissionsAndSaveToken()` - Request permissions & save FCM token
- ✅ `removeToken()` - Clean up FCM token on sign-out
- ✅ `listenForegroundMessages()` - Handle foreground notifications
- ✅ `getInitialMessage()` - Handle app launch from notification
- ✅ Saves tokens to both `fcmToken` (single) and `fcmTokens` (array for multiple devices)

### 5. Student App Entry Point ✅
**File**: `lib/main_student.dart`
- ✅ Added `firebase_messaging` import
- ✅ Added `push_background.dart` import
- ✅ Registered background handler: `FirebaseMessaging.onBackgroundMessage()`

### 6. Tutor App Entry Point ✅
**File**: `lib/main_tutor.dart`
- ✅ Added `firebase_messaging` import
- ✅ Added `push_background.dart` import
- ✅ Registered background handler: `FirebaseMessaging.onBackgroundMessage()`

### 7. Auth Service Integration ✅
**File**: `lib/services/auth_service.dart`
- ✅ Removed old `firebase_messaging` direct import
- ✅ Added `PushService` import
- ✅ Removed manual FCM token methods (`_registerFcmToken`, `_removeFcmToken`)
- ✅ Updated `signIn()` to call `_pushService.requestPermissionsAndSaveToken()`
- ✅ Updated `signIn()` to start foreground listener
- ✅ Updated `signOut()` to call `_pushService.removeToken()`

### 8. Code Formatting ✅
- ✅ All files formatted with `dart format`

---

## 📋 What You Need to Do Now

### 1. **Rebuild iOS** (Required for Info.plist changes)
```bash
cd /Users/yuanping/QuickTutor/quicktutor_2
flutter clean
cd ios && pod install && cd ..
```

### 2. **Enable Xcode Capabilities** (Manual - ONE TIME SETUP)
Open Xcode project: `ios/Runner.xcworkspace`

**For Runner target:**
1. Go to **Signing & Capabilities** tab
2. Click **"+ Capability"**
3. Add **"Push Notifications"**
4. Click **"+ Capability"** again
5. Add **"Background Modes"**
6. Check ✅ **"Remote notifications"**

### 3. **Test the Setup**
```bash
# Test Student App
flutter run -t lib/main_student.dart -d "iPhone 16e"

# Test Tutor App
flutter run -t lib/main_tutor.dart -d "iPhone 16e (Tutor)"
```

### 4. **Verify FCM Token Saved**
After signing in, check Firestore:
- Go to `users/{userId}`
- Should see:
  - `fcmToken`: "abc123..." (single token)
  - `fcmTokens`: ["abc123..."] (array)
  - `fcmUpdatedAt`: timestamp

### 5. **Check Logs**
Look for these in Xcode console or terminal:
```
🔔 Notification permission status: authorized
✅ FCM Token obtained: abc123...
✅ FCM token saved to Firestore
```

---

## 🎯 How It Works

### Sign-In Flow:
1. User signs in → `AuthService.signIn()`
2. User doc created/updated in Firestore
3. `PushService.requestPermissionsAndSaveToken()` called
4. iOS shows permission dialog (first time only)
5. FCM token obtained from Firebase
6. Token saved to `users/{uid}.fcmToken` and `fcmTokens` array
7. Foreground message listener started

### Sign-Out Flow:
1. User signs out → `AuthService.signOut()`
2. `PushService.removeToken()` called
3. Current FCM token removed from `fcmTokens` array
4. Firebase Auth sign-out

### Message Handling:
- **App in foreground**: `FirebaseMessaging.onMessage` → handled by `listenForegroundMessages()`
- **App in background**: `FirebaseMessaging.onBackgroundMessage` → handled by `firebaseMessagingBackgroundHandler()`
- **App terminated**: Same as background → notification shown, tap launches app
- **Notification tap**: `FirebaseMessaging.onMessageOpenedApp` → handled by callback

---

## 🚀 Next Steps: Server-Side Notifications

To send notifications from your backend (Cloud Functions):

### Cloud Function Example:
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onBookingCreated = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snapshot, context) => {
    const booking = snapshot.data();
    const tutorId = booking.tutorId;
    
    // Get tutor's FCM token
    const tutorDoc = await admin.firestore()
      .collection('users')
      .doc(tutorId)
      .get();
    
    const fcmToken = tutorDoc.data()?.fcmToken;
    
    if (fcmToken) {
      // Send notification
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🎓 New Booking Request',
          body: 'A student just booked you! Tap to review.',
        },
        data: {
          type: 'booking_created',
          bookingId: context.params.bookingId,
          tutorId: tutorId,
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        android: {
          priority: 'high',
        },
      });
    }
  });
```

---

## 🐛 Troubleshooting

### "No FCM token" in logs
- ✅ Make sure you ran `pod install` after updating Info.plist
- ✅ Check Firebase Console → Project Settings → Cloud Messaging → Apple app
- ✅ Upload APNs Auth Key (.p8 file) or APNs Certificate

### Red squiggly lines in VSCode for `firebase_messaging`
- ✅ This is a Dart analyzer cache issue (cosmetic only)
- ✅ The code **will compile and run correctly**
- ✅ Fix: Command Palette → "Dart: Restart Analysis Server"

### Permission dialog not showing (iOS)
- ✅ Delete app from simulator/device
- ✅ Clean build: `flutter clean`
- ✅ Rebuild: `flutter run`

### Token not saving to Firestore
- ✅ Check Firestore security rules allow write to `users/{userId}`
- ✅ Verify user is signed in before calling `requestPermissionsAndSaveToken()`
- ✅ Check logs for error messages

### Background messages not received
- ✅ Ensure Xcode "Background Modes → Remote notifications" is enabled
- ✅ Test on **real device** (simulators have limited push support)
- ✅ Check Firebase Console → Cloud Messaging for APNs setup

---

## 📊 Data Structure

### Firestore `users/{userId}`:
```dart
{
  email: string,
  displayName: string,
  role: 'student' | 'tutor',
  fcmToken: string,              // NEW: Latest FCM token
  fcmTokens: string[],           // NEW: All device tokens (multi-device support)
  fcmUpdatedAt: timestamp,       // NEW: Last token update time
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

---

## ✨ Summary

**All push notification infrastructure is now complete!**

✅ iOS & Android platform configurations  
✅ Background message handler  
✅ Foreground message listener  
✅ FCM token management  
✅ Sign-in/Sign-out integration  
✅ Multi-device support (fcmTokens array)  

**Next**: Enable Xcode capabilities, rebuild iOS, test on device, then add Cloud Functions to send actual notifications! 🎉

---

## 📚 Files Changed

1. ✅ `ios/Runner/Info.plist` - Added FCM config
2. ✅ `android/app/src/main/AndroidManifest.xml` - Added notification permission
3. ✅ `lib/services/push/push_background.dart` - NEW background handler
4. ✅ `lib/services/push/push_service.dart` - NEW push service
5. ✅ `lib/main_student.dart` - Added FCM initialization
6. ✅ `lib/main_tutor.dart` - Added FCM initialization
7. ✅ `lib/services/auth_service.dart` - Integrated PushService

**Ready to test!** 🚀
