# Avatar Upload & Enhanced Profile Implementation

## ✅ Completed Changes

### 1. Storage Repository (`lib/data/repositories/storage_repository.dart`)
- ✅ Added constructor injection for `FirebaseStorage` (better for testing)
- ✅ Added `uploadTutorAvatar(File file, String uid)` method
  - Uploads to `profilePhotos/{uid}/avatar.jpg`
  - Sets `contentType: image/jpeg`
  - Sets `cacheControl: public,max-age=3600`
  - Returns download URL

### 2. Tutor Repository (`lib/data/repositories/tutor_repository.dart`)
- ✅ Added constructor injection for `FirebaseFirestore` (better for testing)
- ✅ Added `saveAvatarUrl(String uid, String url)` method
  - Saves to `tutorProfiles/{uid}.photoUrl`
  - Uses `SetOptions(merge: true)` to preserve other fields

### 3. Tutor Profile Edit Screen (`lib/features/tutor/tutor_profile_edit_screen.dart`)
- ✅ Updated imports to use repository methods
- ✅ Added `StorageRepository` instance
- ✅ Modified `_pickAndUploadPhoto()` to use new repository methods:
  - Picks image with `maxWidth: 1200` (optimized size)
  - Calls `_storage.uploadTutorAvatar(file, uid)`
  - Calls `_repo.saveAvatarUrl(uid, downloadUrl)`
  - Shows success/error messages
- ✅ Avatar displays `photoUrl` from Firestore with `NetworkImage`
- ✅ Languages, Subjects, and Grade pickers already implemented with menu selectors (no free typing)

### 4. Student Tutor Profile Screen (`lib/features/student/tutor_profile_screen.dart`)
- ✅ Complete redesign with rich profile view:
  - **Header Section**:
    - Large circular avatar (60px radius) from `photoUrl`
    - Display name (headline style)
    - Email address
    - Star rating with icon
    - Gradient background
  
  - **Content Sections**:
    - Subjects (chips with primary color)
    - Grade Levels (chips with secondary color)
    - Languages (chips with language icon)
    - Introduction
    - Teaching Style
    - Experience
    - Education
  
  - **Reviews Section**:
    - Shows last 5 reviews from subcollection
    - Displays student name, star rating, comment, date
    - Empty state: "No reviews yet" with icon
    - Real-time updates with `StreamBuilder`
  
  - **Bottom Action**:
    - Floating "Book Now" button with shadow
    - Navigates to `Routes.bookingConfirm` with tutorId

### 5. Permissions Configured

#### iOS (`ios/Runner/Info.plist`)
- ✅ `NSPhotoLibraryUsageDescription` - Already configured
- ✅ `NSCameraUsageDescription` - Already configured

#### Android (`android/app/src/main/AndroidManifest.xml`)
- ✅ `READ_MEDIA_IMAGES` - For Android 13+ (Tiramisu)
- ✅ `READ_EXTERNAL_STORAGE` (maxSdkVersion=32) - For older Android versions

### 6. Packages Already Installed
- ✅ `firebase_storage: ^12.3.7`
- ✅ `image_picker: ^1.0.7`

## 📊 Data Structure

### Firestore Collections

#### `tutorProfiles/{tutorId}`
```dart
{
  displayName: string,
  email: string,
  photoUrl: string,           // NEW: Avatar download URL
  intro: string,
  teachingStyle: string,
  experience: string,
  education: string,
  certificates: string[],
  languages: string[],        // From predefined catalog
  subjects: string[],         // From predefined catalog (max 5)
  grades: string[],           // From predefined catalog
  avgRating: number,
  verified: boolean,
  isOnline: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### `tutorProfiles/{tutorId}/reviews/{reviewId}` (subcollection)
```dart
{
  studentId: string,
  studentName: string,
  rating: number,             // 1-5 stars
  comment: string,
  createdAt: timestamp
}
```

### Firebase Storage Structure
```
profilePhotos/
  {tutorId}/
    avatar.jpg              // JPEG with cache control
```

## 🎯 Feature Flow

### Tutor Uploads Avatar
1. Tutor opens **Profile** tab in tutor shell
2. Taps camera icon on circular avatar
3. `image_picker` opens gallery (maxWidth: 1200)
4. Image uploaded to `profilePhotos/{uid}/avatar.jpg`
5. Download URL saved to `tutorProfiles/{uid}.photoUrl`
6. UI refreshes to show new avatar
7. Success message displayed

### Student Views Tutor Profile
1. Student taps tutor card in search/home
2. Navigates to `TutorProfileScreen` with tutorId
3. Fetches tutor data from `tutorProfiles/{tutorId}`
4. Displays:
   - Avatar from `photoUrl` (NetworkImage)
   - Basic info (name, email, rating)
   - Chips for subjects, grades, languages
   - Text sections for intro, teaching style, experience, education
   - Reviews from `reviews` subcollection (last 5, ordered by createdAt desc)
5. Student taps **Book Now** → routes to booking confirmation

## 🔧 Testing Checklist

### Avatar Upload (Tutor App)
- [ ] Tap avatar camera icon → opens gallery
- [ ] Select image → shows loading state
- [ ] Upload completes → avatar displays immediately
- [ ] Success snackbar appears
- [ ] Check Firestore: `tutorProfiles/{uid}.photoUrl` contains URL
- [ ] Check Storage: `profilePhotos/{uid}/avatar.jpg` exists
- [ ] Verify image has correct content-type (image/jpeg)

### Profile View (Student App)
- [ ] Navigate to tutor profile from search
- [ ] Avatar loads correctly (or shows placeholder)
- [ ] All sections display data properly
- [ ] Chips render for subjects, grades, languages
- [ ] Empty sections don't show (conditional rendering)
- [ ] Reviews section shows real reviews or empty state
- [ ] "Book Now" button navigates to booking flow
- [ ] Scroll works smoothly with all content

### Permissions
- [ ] **iOS**: First launch asks for photo library permission
- [ ] **Android 13+**: Asks for READ_MEDIA_IMAGES permission
- [ ] **Android <13**: Asks for READ_EXTERNAL_STORAGE permission
- [ ] Denying permission shows error (gracefully handled)

### Edge Cases
- [ ] No internet → shows error message
- [ ] Large images → resized to 1200px max
- [ ] Tutor with no photoUrl → shows placeholder icon
- [ ] Tutor with no reviews → shows "No reviews yet"
- [ ] Very long intro/experience text → scrolls properly

## 🔒 Firebase Storage Security Rules

**IMPORTANT**: Update your Firebase Storage rules to allow read/write:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile photos - public read, owner write
    match /profilePhotos/{userId}/avatar.jpg {
      allow read: if true;  // Public avatars
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Keep existing rules for other paths...
  }
}
```

### To Apply Rules:
1. Open Firebase Console → Storage
2. Click **Rules** tab
3. Add the `profilePhotos` rule above
4. Click **Publish**

## 📝 Code Highlights

### Repository Pattern (Testable)
```dart
// StorageRepository with dependency injection
class StorageRepository {
  final FirebaseStorage _storage;
  
  StorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;
}

// Usage in widget (can be replaced with Provider/GetIt later)
final _storage = StorageRepository();
final _repo = TutorRepo();
```

### Avatar Upload Flow
```dart
Future<void> _pickAndUploadPhoto() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    imageQuality: 85,
  );
  
  if (pickedFile == null) return;
  
  setState(() => _loading = true);
  
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final file = File(pickedFile.path);
  
  // Upload to Storage
  final downloadUrl = await _storage.uploadTutorAvatar(file, uid);
  
  // Save URL to Firestore
  await _repo.saveAvatarUrl(uid, downloadUrl);
  
  setState(() {
    _photoUrl = downloadUrl;
    _loading = false;
  });
}
```

### Rich Profile Display
```dart
// Avatar with fallback
CircleAvatar(
  radius: 60,
  backgroundColor: Colors.grey.shade200,
  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
      ? NetworkImage(photoUrl)
      : null,
  child: (photoUrl == null || photoUrl.isEmpty)
      ? const Icon(Icons.person, size: 60)
      : null,
)

// Reviews with empty state
if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(Icons.rate_review_outlined, size: 48),
        const SizedBox(height: 8),
        Text('No reviews yet'),
      ],
    ),
  );
}
```

## 🎨 UI Improvements

### Before → After

**Tutor Profile Edit**:
- ❌ Basic text fields for everything
- ✅ Avatar with camera button
- ✅ Menu pickers for languages (no free typing)
- ✅ Menu pickers for grades (no free typing)
- ✅ Subject chips with max 5 limit

**Student Tutor View**:
- ❌ Simple text: "Name, Rating: 4.8"
- ✅ Beautiful header with large avatar
- ✅ Gradient background
- ✅ Organized sections with chips
- ✅ Reviews with star ratings
- ✅ Floating "Book Now" button
- ✅ Empty states handled gracefully

## 🚀 Next Steps (Optional Enhancements)

1. **Avatar Cropping**: Add `image_cropper` package for better UX
2. **Compression**: Use `flutter_image_compress` to reduce file sizes
3. **Cache Management**: Add cache headers for better performance
4. **Review Pagination**: Load more than 5 reviews with "Load More" button
5. **Rating Statistics**: Show rating distribution (5★: 80%, 4★: 15%, etc.)
6. **Verified Badge**: Show badge icon next to verified tutors
7. **Share Profile**: Add share button to share tutor profile
8. **Favorite Tutors**: Let students save favorite tutors

## 📚 References

- **Firebase Storage Docs**: https://firebase.google.com/docs/storage/flutter/upload-files
- **Image Picker Docs**: https://pub.dev/packages/image_picker
- **Repository Pattern**: https://flutter.dev/docs/development/data-and-backend/state-mgmt/options#repository-pattern

## ✨ Summary

All requirements completed:
1. ✅ Storage repo with `uploadTutorAvatar` method
2. ✅ Tutor repo with `saveAvatarUrl` helper
3. ✅ Edit profile screen uses new methods
4. ✅ Avatar picker works with image_picker
5. ✅ Avatar displays from Firestore `photoUrl`
6. ✅ Languages & Grades use menu selectors (no free typing)
7. ✅ Student tutor profile shows rich view
8. ✅ Reviews section with empty state
9. ✅ "Book Now" button routes to booking
10. ✅ iOS & Android permissions configured

**Ready to test!** 🎉
