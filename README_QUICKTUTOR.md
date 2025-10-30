# QuickTutor - Minimal Flutter + Firebase Multi-Role App

## Overview
QuickTutor is a functional demonstration of a tutoring platform with three synchronized user roles: **Student**, **Tutor**, and **Admin**. All roles interact with the same Firebase Firestore database, creating a unified real-time experience.

## Architecture

### Tech Stack
- **Flutter 3.35+** (Material 3)
- **Firebase Authentication** (Email/Password)
- **Cloud Firestore** (Real-time database)
- **Firebase Storage** (Document uploads - placeholder)

### Project Structure
```
lib/
├── core/                    # App-wide configuration
│   ├── app_theme.dart       # Material 3 theme
│   └── app_routes.dart      # Centralized routing
├── services/                # Business logic
│   ├── auth_service.dart    # Authentication wrapper
│   └── firestore_paths.dart # Database path constants
├── data/
│   ├── models/              # Data models
│   │   ├── user_model.dart
│   │   ├── booking_model.dart
│   │   └── message_model.dart
│   └── repositories/        # Data access layer
│       ├── booking_repository.dart
│       ├── chat_repository.dart
│       └── tutor_repository.dart
├── features/
│   ├── auth/                # Login & Signup
│   ├── student/             # Student-specific screens
│   ├── tutor/               # Tutor-specific screens
│   ├── admin/               # Admin-specific screens
│   └── common/              # Shared widgets
├── main.dart                # Main entry with role gate
├── main_student.dart        # Student-only entry
└── main_tutor.dart          # Tutor-only entry
```

## User Flows

### 🎓 Student Flow
1. **Sign Up / Login** → Create account with role "student"
2. **Home Screen** → View dashboard with navigation
3. **Find Tutors** → Browse online tutors (filtered by `isOnline` field)
4. **View Tutor Profile** → See tutor details, rating, subjects
5. **Book Session** → Select subject & duration, simulate payment
6. **Chat** → Real-time messaging with tutor (Firestore subcollection)
7. **Profile** → View booking history (TODO in demo)

**Key Database Interactions:**
- Reads: `tutorProfiles` (where `isOnline == true`)
- Writes: `bookings`, `chats/{threadId}/messages`

---

### 👨‍🏫 Tutor Flow
1. **Sign Up / Login** → Create account with role "tutor" (unverified)
2. **Verification Screen** → Upload credentials (mock) → writes to `verificationRequests/{uid}`
3. **Admin Approval** → Wait for admin to set `users/{uid}.tutorVerified = true`
4. **Dashboard** → Toggle online status, update public profile
5. **Messages** → Receive and respond to student chats (TODO: full implementation)
6. **Profile Edit** → Update subjects, availability, rates

**Key Database Interactions:**
- Writes: `tutorProfiles/{uid}` (profile data, `isOnline` field)
- Reads: `bookings` (where `tutorId == uid`), chat threads

---

### 🛡️ Admin Flow
1. **Login** → (Demo: direct entry, no credentials needed)
2. **Dashboard** → Central management hub
3. **Verification Queue** → View all `verificationRequests` with status "pending"
4. **Approve/Reject Tutors** → Updates:
   - `users/{tutorId}.tutorVerified = true`
   - `users/{tutorId}.role = "tutor"` (if needed)
   - `verificationRequests/{tutorId}.status = "approved"`
5. **User Management** → (TODO: view all users, bookings)

**Key Database Interactions:**
- Reads: `verificationRequests`, `users`, `bookings`
- Writes: `users/{uid}` (role, tutorVerified), `verificationRequests/{uid}` (status)

---

## Database Schema

### Collections

#### `users/{uid}`
```json
{
  "email": "user@example.com",
  "role": "student | tutor | admin",
  "tutorVerified": false,
  "displayName": "John Doe",
  "createdAt": Timestamp
}
```

#### `tutorProfiles/{uid}`
```json
{
  "displayName": "Dr. Smith",
  "subjects": ["Math", "Physics"],
  "isOnline": true,
  "avgRating": 4.8,
  "hourlyRate": 50
}
```

#### `verificationRequests/{uid}`
```json
{
  "status": "pending | approved | rejected",
  "documentsUrl": "gs://bucket/path",
  "submittedAt": Timestamp
}
```

#### `bookings/{bookingId}`
```json
{
  "studentId": "uid123",
  "tutorId": "uid456",
  "subject": "English",
  "minutes": 45,
  "price": 25,
  "status": "paid | completed | cancelled",
  "createdAt": Timestamp
}
```

#### `chats/{threadId}/messages/{messageId}`
```json
{
  "senderId": "uid123",
  "text": "Hello tutor!",
  "ts": 1698765432000
}
```

#### `chats/{threadId}`
```json
{
  "members": ["studentId", "tutorId"],
  "lastMessage": "Hello tutor!",
  "updatedAt": Timestamp
}
```

---

## Security Rules Summary
See `firestore.rules` for full implementation:

- **users**: Read/write own document; admins read all
- **tutorProfiles**: Public read; write only by profile owner
- **verificationRequests**: Create by tutor; read by owner/admin; update by admin
- **bookings**: Authenticated users can create/read
- **chats**: Authenticated users can read/write (thread participants should be validated in production)

---

## Role Synchronization
All roles interact with the same Firestore instance:

1. **Student books tutor** → writes `bookings/{id}` → **Tutor** sees new booking
2. **Tutor toggles online** → updates `tutorProfiles/{uid}.isOnline` → **Student** sees in search
3. **Admin approves tutor** → updates `users/{uid}.tutorVerified` → **Tutor** app re-routes to dashboard
4. **Student sends message** → writes to `chats/{threadId}/messages` → **Tutor** receives real-time via StreamBuilder

---

## Running the App

### All Roles (with Role Gate)
```bash
flutter run -t lib/main.dart
```
Routes users based on `users/{uid}.role` field.

### Student-Only Mode
```bash
flutter run -t lib/main_student.dart
```

### Tutor-Only Mode
```bash
flutter run -t lib/main_tutor.dart
```

---

## Next Steps (Production Enhancements)
- [ ] Add real payment integration (Stripe/Razorpay)
- [ ] Implement video call (WebRTC/Agora)
- [ ] Enhanced search filters (subject, price range, rating)
- [ ] Push notifications for new bookings/messages
- [ ] Profile photo uploads (Firebase Storage)
- [ ] Review & rating system after sessions
- [ ] Admin analytics dashboard

---

## Demo Notes
- Payment is simulated (all bookings auto-marked "paid")
- Admin login has no authentication for quick testing
- Tutor verification uses placeholder uploads
- Chat uses simple threadId pattern: `{studentId}_{tutorId}`

---

## License
MIT (Demo/Educational Use)
