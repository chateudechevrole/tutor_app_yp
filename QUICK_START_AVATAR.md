# 🚀 Quick Start Guide - Avatar Upload & Profile Features

## What Was Implemented

✅ **Repository Layer**
- `StorageRepository.uploadTutorAvatar()` - Uploads to `profilePhotos/{uid}/avatar.jpg`
- `TutorRepo.saveAvatarUrl()` - Saves download URL to Firestore

✅ **Tutor App Features**
- Avatar upload with gallery picker
- Photo optimization (max 1200px, 85% quality)
- Upload to Firebase Storage with cache control
- Languages, Subjects, Grades pickers (no free typing - already done)

✅ **Student App Features**
- Rich tutor profile screen with:
  - Large avatar display
  - Subjects, Grades, Languages chips
  - Introduction, Teaching Style, Experience, Education sections
  - Reviews subcollection (with empty state)
  - Floating "Book Now" button

✅ **Permissions**
- iOS: Photo Library & Camera (already in Info.plist)
- Android: READ_MEDIA_IMAGES (Android 13+) & READ_EXTERNAL_STORAGE (older)

✅ **Packages**
- firebase_messaging updated to ^15.2.10
- All packages installed with `flutter pub get`

## 🔧 What You Need to Do Now

### 1. Update Firebase Storage Security Rules

**Go to**: Firebase Console → Storage → Rules

**Add this rule**:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile photos - public read, owner write
    match /profilePhotos/{userId}/avatar.jpg {
      allow read: if true;  // Public avatars
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Keep your existing rules for other paths below...
  }
}
```

**Click**: Publish

### 2. Rebuild iOS (Permissions Require Rebuild)

```bash
cd /Users/yuanping/QuickTutor/quicktutor_2
flutter clean
cd ios && pod install && cd ..
```

### 3. Test the Features

#### Test Avatar Upload (Tutor App):
```bash
flutter run -t lib/main_tutor.dart -d "iPhone 16e (Tutor)"
```

1. Sign in as a tutor
2. Go to **Profile** tab
3. Tap the **camera icon** on the avatar
4. Select a photo from gallery
5. Wait for upload (loading spinner)
6. Avatar should update immediately
7. Check Firestore: `tutorProfiles/{tutorId}` should have `photoUrl`

#### Test Profile View (Student App):
```bash
flutter run -t lib/main_student.dart -d "iPhone 17"
```

1. Sign in as a student
2. Search for tutors or browse home
3. Tap a **tutor card**
4. Should show rich profile with:
   - Avatar (if tutor uploaded one)
   - All profile sections
   - Reviews or "No reviews yet"
5. Tap **Book Now** → should go to booking flow

### 4. Check for Errors

The avatar upload code is complete and formatted. The only error you might see is related to `firebase_messaging` in `auth_service.dart` - that's from the previous push notification implementation and is unrelated to avatar upload.

## 📋 Testing Checklist

### Avatar Upload
- [ ] Tutor can tap avatar camera icon
- [ ] Gallery opens with image picker
- [ ] Selected image uploads successfully
- [ ] Avatar displays immediately after upload
- [ ] Success snackbar shows
- [ ] Firestore `photoUrl` field is populated
- [ ] Storage shows `profilePhotos/{uid}/avatar.jpg`

### Student Profile View
- [ ] Navigation from tutor card works
- [ ] Avatar loads (or shows placeholder)
- [ ] All sections display correctly
- [ ] Chips render for subjects, grades, languages
- [ ] Reviews show or empty state displays
- [ ] "Book Now" button navigates correctly
- [ ] Page scrolls smoothly

### Permissions
- [ ] iOS asks for photo library access (first time)
- [ ] Android asks for media access (first time)
- [ ] Permissions work on both platforms

## 🐛 Troubleshooting

### "Permission denied" error on upload
→ Check Firebase Storage rules (step 1 above)

### Avatar doesn't display after upload
→ Check browser console or Xcode console for CORS/network errors
→ Verify `photoUrl` exists in Firestore

### Image picker doesn't open
→ iOS: Make sure you ran `pod install` after adding permissions
→ Android: Check permissions in AndroidManifest.xml

### Reviews not showing
→ Reviews are from subcollection `tutorProfiles/{tutorId}/reviews/{reviewId}`
→ Empty state will show if no reviews exist (this is expected)

## 📁 Files Changed

1. `lib/data/repositories/storage_repository.dart` - Added `uploadTutorAvatar()`
2. `lib/data/repositories/tutor_repository.dart` - Added `saveAvatarUrl()`
3. `lib/features/tutor/tutor_profile_edit_screen.dart` - Updated to use new methods
4. `lib/features/student/tutor_profile_screen.dart` - Complete redesign
5. `android/app/src/main/AndroidManifest.xml` - Added image permissions
6. `pubspec.yaml` - Updated firebase_messaging to ^15.2.10

## 🎯 Next Actions

1. **Publish Storage Rules** (most important!)
2. **Rebuild iOS**: `flutter clean && cd ios && pod install && cd ..`
3. **Test Avatar Upload** on tutor app
4. **Test Profile View** on student app
5. **Verify** data in Firebase Console (Firestore + Storage)

## 📚 Documentation

Full implementation details: `AVATAR_UPLOAD_IMPLEMENTATION.md`

---

**Everything is ready to test!** 🎉

Just publish the Firebase Storage rules and rebuild iOS, then start testing!
