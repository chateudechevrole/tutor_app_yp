# Quick Command Reference

## 🚀 Firebase Deployment Commands

### Deploy Firestore Indexes (Run in project root)

```bash
# Step 1: Login (if not already logged in)
firebase login

# Step 2: Select your project
firebase use quicktutor2

# Step 3: Deploy indexes
firebase deploy --only firestore:indexes
```

---

## 📋 Verification Commands

### Check which project is active
```bash
firebase projects:list
```

### View current indexes
```bash
firebase firestore:indexes
```

### Check login status
```bash
firebase login:list
```

---

## 🔄 One-Command Deployment (After Setup)

Once you're logged in and have selected the project, you only need:

```bash
firebase deploy --only firestore:indexes
```

---

## 🧪 Test the App

```bash
# Run student app on iPhone simulator
flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart

# Or run and watch for hot reload
flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart --hot
```

---

## 📱 iOS Permissions (If photo upload doesn't work)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>QuickTutor needs access to your camera to update your profile picture</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>QuickTutor needs access to your photo library to update your profile picture</string>
```

---

## 🔍 Troubleshooting

### Firebase CLI not found
```bash
npm install -g firebase-tools
```

### Not authorized
```bash
firebase logout
firebase login
```

### Wrong project selected
```bash
firebase use --add
# Select correct project from list
```

---

## 📊 Monitor Firebase Console

**Indexes Status:**
https://console.firebase.google.com/project/quicktutor2/firestore/indexes

**Storage Files:**
https://console.firebase.google.com/project/quicktutor2/storage

**Authentication Users:**
https://console.firebase.google.com/project/quicktutor2/authentication/users

**Firestore Data:**
https://console.firebase.google.com/project/quicktutor2/firestore/data

---

## ✅ Quick Test Checklist

After deploying indexes:

1. Run app: `flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart`
2. Go to Profile tab
3. Test edit name (tap ✏️ icon)
4. Test upload photo (tap 📷 icon)
5. Go to Booking History
6. Verify bookings load
7. Try filtering by status
8. Check sorting (newest first)

---

## 🎯 Success Indicators

### Firebase Deploy Success:
```
✔  firestore: deployed indexes in firestore.indexes.json successfully
✔  Deploy complete!
```

### App Works:
- ✅ Profile screen loads
- ✅ Can edit name
- ✅ Can upload photo
- ✅ Booking history loads
- ✅ Can filter bookings
- ✅ No console errors

---

## 📞 Quick Links

- **Firebase Console:** https://console.firebase.google.com
- **Project:** https://console.firebase.google.com/project/quicktutor2
- **Indexes:** https://console.firebase.google.com/project/quicktutor2/firestore/indexes
- **Documentation:** https://firebase.google.com/docs/firestore/query-data/indexing
