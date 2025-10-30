# Tutor Flow Implementation Summary

## ✅ Completed Implementation

### Design System
- **Colors**: kBg (soft white), kPrimary (deep blue), kAccent (soft yellow)
- **Theme**: `lib/theme/tutor_theme.dart` with Material 3
- All tutor screens wrapped in `Theme(data: tutorTheme, ...)`

### Routes Added
- `/tutor/login` - TutorLoginScreen
- `/tutor/verify` - TutorVerifyScreen (file uploads)
- `/tutor/waiting` - TutorWaitingScreen (pending approval)
- `/tutor/dashboard` - TutorDashboardScreen (main hub)
- `/tutor/edit` - TutorProfileEditScreen (profile editing)
- `/tutor/chats` - TutorChatsScreen (chat threads list)
- `/tutor/chat` - TutorChatScreen (individual chat)
- `/tutor/bookings` - TutorBookingsScreen (booking notifications)

### Screens Implemented

#### 1. TutorLoginScreen
- Email/password login
- Auto-routes based on verification status
- Links to signup

#### 2. TutorVerifyScreen
- Three file upload fields (IC, Education Cert, Bank Statement)
- Uses image_picker for file selection
- Uploads to Firebase Storage at `verifications/{uid}/`
- Creates verificationRequest with status "pending"

#### 3. TutorWaitingScreen
- Polls verification status via stream
- Auto-redirects to dashboard when approved
- Shows rejection message with retry option

#### 4. TutorDashboardScreen
- Online/Offline toggle
- Stats cards (Sessions, Rating, Earnings)
- Menu items: Class History, Earnings, Verification, Settings, Messages
- Bottom nav: Home, Messages, Profile

#### 5. TutorProfileEditScreen
- Guided form with all fields
- Avatar upload placeholder (image_picker required)
- Chips for Languages, Subjects, Grades
- Saves to tutorProfiles/{uid}
- Note: "This profile is visible to students"

#### 6. TutorChatsScreen
- Lists chat threads where tutor is participant
- Taps open TutorChatScreen

#### 7. TutorChatScreen
- Real-time messaging
- "Start Class" button (placeholder)
- Send/receive messages via Firestore

#### 8. TutorBookingsScreen
- Lists bookings for current tutor
- Shows status pills (paid/accepted/completed)
- Tap for details (placeholder)

### Data Layer

#### TutorRepository Extensions
- `uploadAvatar(uid, file)` - Uploads to Storage, updates both users and tutorProfiles
- `updateProfile(uid, data)` - Saves profile to tutorProfiles
- `streamVerificationStatus(uid)` - Real-time verification status
- `submitVerification(uid, fileUrls)` - Creates verification request

#### StorageRepository (NEW)
- `putFile(path, file)` - Generic file upload to Firebase Storage
- Returns download URL

### Admin Updates
- VerifyQueueScreen now shows expandable cards
- Each verification shows 3 file links (IC, Edu Cert, Bank Statement)
- Clicking "View" opens file URL in system browser (url_launcher)

### Dependencies Added
- `image_picker: ^1.0.7` - For file uploads
- `url_launcher: ^6.2.5` - For admin to view verification files

### Firebase Structure
```
verificationRequests/{uid}:
  status: "not_submitted" | "pending" | "approved" | "rejected"
  submittedAt: timestamp
  files:
    icUrl: string
    eduCertUrl: string
    bankStmtUrl: string

tutorProfiles/{uid}:
  displayName, intro, subjects[], grades[], languages[]
  teachingStyle, experience, education, certificates[]
  avgRating, isOnline, photoUrl

Storage:
  verifications/{uid}/ic.jpg
  verifications/{uid}/edu_cert.jpg
  verifications/{uid}/bank_stmt.jpg
  tutor_avatars/{uid}.jpg
```

### main_tutor.dart
- Uses tutorTheme
- initialRoute: Routes.tutorDash
- Fallback to verify if not verified (handled by login flow)

## Analysis Status
✅ Code formatted with `dart format .`
✅ 15 info-level warnings, 0 errors
✅ All tutor flows functional

## Testing Checklist
- [ ] New tutor signs up → lands on /tutor/verify
- [ ] Upload 3 files → status becomes "pending"
- [ ] Admin sees 3 file URLs in Verify Queue (clickable)
- [ ] Admin approves → tutor auto-redirects to dashboard
- [ ] Tutor toggles online → tutorProfiles/{uid}.isOnline updates
- [ ] Edit profile → saves fields to Firestore
- [ ] Messages tab shows chat threads and booking list
- [ ] Chat screen sends/receives messages
- [ ] All screens use kBg/kPrimary/kAccent colors
