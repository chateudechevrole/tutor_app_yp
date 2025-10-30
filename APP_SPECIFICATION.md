# QuickTutor - Complete App Specification
## Minimalist Educational Tutoring Platform

**Last Updated:** October 30, 2025  
**Version:** 2.0 (Current Implementation)

---

## 🎯 App Overview

**QuickTutor** is a Flutter-based mobile application connecting students with verified tutors for personalized learning sessions. The platform features three distinct user roles (Student, Tutor, Admin) with role-specific interfaces and workflows.

**Design Philosophy:**
- **Minimalist**: Clean, uncluttered interfaces
- **Educational**: Learning-focused features
- **Simple**: Intuitive user flows
- **Professional**: Comprehensive verification and quality control

---

## 👥 User Roles

### 1. **Student** 🎓
- Browse and search for verified tutors
- Book tutoring sessions
- Chat with tutors
- Rate and review tutors
- View booking history

### 2. **Tutor** 👨‍🏫
- Create and manage tutor profile
- Toggle online/offline status (like Grab driver)
- Receive and accept booking requests
- Chat with students
- View earnings and session history
- Upload verification documents

### 3. **Admin** 🛡️
- Verify tutor credentials
- Manage user accounts
- View all platform bookings
- Monitor platform activity

---

## 📱 Student Flow

### 1. Authentication
**Entry Point:** App Launch → Splash Screen (if configured) → Login/Sign Up

**Login/Sign Up Screen:**
- Email/password authentication via Firebase Auth
- Role selection (Student/Tutor/Admin) on sign-up
- Auto-routing based on existing user role

**Implementation:**
- `lib/features/auth/login_screen.dart`
- `lib/features/auth/signup_screen.dart`

---

### 2. Home Screen (Search & Browse)
**Navigation:** After login → Student Home (with bottom navigation)

**Layout:**
```
┌─────────────────────────────┐
│ AppBar: "Find Tutor Now ✨" │
├─────────────────────────────┤
│ FILTER ROW (horizontal)     │
│ [Grade ▼] [Subject ▼]      │
│ [Purpose ▼] [Language ▼]   │
├─────────────────────────────┤
│ TUTOR LIST (scrollable)     │
│ ┌───────────────────────┐   │
│ │ 👤 Tutor Card         │   │
│ │ Name | Rating ⭐      │   │
│ │ Subjects: Math, Sci   │   │
│ │ Grades: Form 1-3      │   │
│ │ Rate: RM50/hr         │   │
│ └───────────────────────┘   │
│ ┌───────────────────────┐   │
│ │ 👤 Tutor Card         │   │
│ └───────────────────────┘   │
├─────────────────────────────┤
│ BOTTOM NAV BAR             │
│ [🏠 Home] [💬 Messages]    │
│          [👤 Profile]      │
└─────────────────────────────┘
```

**Features:**
- **Category Filters:**
  - **Grade Levels:** Primary 1-6, Form 1-5
  - **Subjects:** BM, English, Science, Maths, Sejarah, Geografi, etc.
  - **Language:** BM, English, Chinese
  - **Purpose:** Homework, Topic Help, Exam Prep, Oral Practice, Essay Writing

- **Tutor List:**
  - Only shows **verified** and **online** tutors
  - Real-time updates via Firestore streams
  - Shows tutor avatar, name, subjects, grades, rating
  - Tap to view full tutor profile

**Implementation:**
- `lib/features/student/student_home_screen.dart`
- `lib/features/student/shell/student_shell.dart` (bottom navigation)
- `lib/data/repositories/tutor_repository.dart` (search query)

---

### 3. Tutor Profile & Details
**Navigation:** Tap tutor card → Tutor Detail Screen

**Layout:**
```
┌─────────────────────────────┐
│ ← Back                      │
├─────────────────────────────┤
│     👤 Profile Photo        │
│     Tutor Name              │
│     ⭐⭐⭐⭐⭐ 4.8 (12)       │
├─────────────────────────────┤
│ INTRODUCTION                │
│ Bio text, teaching style... │
├─────────────────────────────┤
│ TEACHING INFO               │
│ • Subjects: Math, Science   │
│ • Grades: Form 1-3          │
│ • Languages: BM, English    │
│ • Experience: 5 years       │
│ • Hourly Rate: RM 50        │
├─────────────────────────────┤
│ REVIEWS & RATINGS           │
│ ★★★★★ 5.0 - Great teacher! │
│ ★★★★☆ 4.0 - Very patient   │
├─────────────────────────────┤
│   [📚 Book Now Button]      │
└─────────────────────────────┘
```

**Information Displayed:**
- Profile photo
- Display name
- Introduction/bio
- Teaching style
- Experience & education
- Subjects taught
- Grade levels
- Languages spoken
- Hourly rate
- Average rating
- Student reviews (read-only for students)

**Implementation:**
- `lib/features/student/tutor_detail_screen.dart`
- `lib/features/student/tutor_profile_screen.dart`

---

### 4. Booking Flow
**Navigation:** Tap "Book Now" → Booking Confirmation → Payment → Tutor Acceptance → Chat

#### Step 1: Booking Confirmation Screen
```
┌─────────────────────────────┐
│ Confirm Booking             │
├─────────────────────────────┤
│ Tutor: Dr. Smith            │
│ Subject: [Mathematics ▼]    │
│ Duration: [30 min ▼]        │
│ Date: [Select Date 📅]      │
│ Time: [Select Time 🕐]      │
│ Message (optional):         │
│ [text area]                 │
├─────────────────────────────┤
│ Hourly Rate: RM 50          │
│ Duration: 30 minutes        │
│ Total: RM 25                │
├─────────────────────────────┤
│   [Proceed to Payment]      │
└─────────────────────────────┘
```

**Implementation:**
- `lib/features/student/booking_confirm_screen.dart`
- Creates booking with status: `pending`

#### Step 2: Payment Gateway
```
┌─────────────────────────────┐
│ Payment                     │
├─────────────────────────────┤
│ Amount: RM 25.00            │
│ [Payment Method]            │
│ ○ Credit Card               │
│ ○ Online Banking            │
│ ○ E-Wallet                  │
├─────────────────────────────┤
│   [Pay Now]                 │
└─────────────────────────────┘
```

**Current Implementation:**
- `lib/features/student/booking_screens.dart`
- **Note:** Currently simulated (auto-sets status to `paid`)
- **Future:** Integrate with Stripe/PayPal/local payment gateway

#### Step 3: Tutor Acceptance
**Flow:**
1. After payment → Booking status: `paid`
2. Tutor receives booking notification
3. Tutor has **15 minutes** to accept
4. Tutor accepts → Status: `accepted` → Chat unlocked
5. Tutor declines → Status: `cancelled` → Refund initiated

**Implementation:**
- Handled in `lib/features/tutor/tutor_bookings_screen.dart`

---

### 5. Chat with Tutor
**Navigation:** After booking accepted → Messages tab → Chat Screen

**Layout:**
```
┌─────────────────────────────┐
│ ← Tutor Name                │
├─────────────────────────────┤
│                             │
│  [Tutor]: Hi! Ready?        │
│                             │
│      [Student]: Yes! 😊      │
│                             │
│  [Tutor]: Let's start       │
│                             │
│                             │
├─────────────────────────────┤
│ [Type message...] [Send ➤]  │
└─────────────────────────────┘
```

**Features:**
- Real-time messaging
- Send/receive learning materials (future)
- Tutor can initiate "Start Class" button
- Message history stored in Firestore

**Implementation:**
- `lib/features/student/chat_screen.dart`
- `lib/services/firestore_paths.dart` (chat collections)

---

### 6. Class Session
**Flow:**
1. Tutor has **15 minutes** to get ready after accepting
2. Tutor clicks "Start Class" button in chat
3. Class timer begins (based on booked duration)
4. After class ends → Status: `completed`
5. Student receives rating prompt

**Current Status:** 
- Start Class button: Placeholder (future integration with video call)
- Timer: Not implemented
- **Future:** Integrate with Zoom/Agora/Jitsi for video sessions

---

### 7. Rating & Review
**Navigation:** After class completion → Rating Dialog

**Layout:**
```
┌─────────────────────────────┐
│ Rate Your Session           │
├─────────────────────────────┤
│ How was your experience     │
│ with Tutor Name?            │
│                             │
│   ⭐ ⭐ ⭐ ⭐ ⭐             │
│                             │
│ Write a review (optional):  │
│ [text area]                 │
│                             │
│                             │
├─────────────────────────────┤
│  [Skip]        [Submit]     │
└─────────────────────────────┘
```

**Features:**
- 1-5 star rating (required)
- Written review (optional)
- Updates tutor's average rating
- Visible to all students browsing tutors

**Implementation:**
- **Future feature** (not yet implemented)
- Will write to: `tutorProfiles/{tutorId}/reviews/{reviewId}`
- Updates: `tutorProfiles/{tutorId}.rating` and `totalReviews`

---

### 8. Student Profile
**Navigation:** Bottom nav → Profile tab

**Layout:**
```
┌─────────────────────────────┐
│ My Profile                  │
├─────────────────────────────┤
│     👤 Profile Photo        │
│     Student Name            │
│     student@example.com     │
├─────────────────────────────┤
│ [📚 Booking History]        │
│ [⚙️ Account Settings]       │
│ [🔔 Notifications]          │
│ [ℹ️ Help & Support]         │
│ [🚪 Logout]                 │
└─────────────────────────────┘
```

**Features:**
- **Booking History:**
  - View all past bookings
  - Filter by: All, Completed, Pending, Cancelled
  - See tutor details, subject, duration, price, date
  - Tap for full booking details
  
- **Account Settings:**
  - Change password
  - Update display name
  - Email preferences (future)

**Implementation:**
- `lib/features/student/profile/student_profile_screen.dart`
- `lib/features/student/booking_history_screen.dart`

---

## 👨‍🏫 Tutor Flow

### 1. Authentication & Verification Gate
**Entry Point:** App Launch → Login/Sign Up

**First-Time Tutor Flow:**
```
Sign Up (role: tutor)
  ↓
Verification Screen
  (upload credentials)
  ↓
Waiting Screen
  (pending admin approval)
  ↓
Admin Approves
  ↓
Dashboard (verified tutor)
```

**Returning Tutor Flow:**
```
Login
  ↓
Check tutorVerified flag
  ├─ If verified → Dashboard
  ├─ If pending → Waiting Screen
  └─ If not submitted → Verification Screen
```

**Implementation:**
- `lib/features/gates/tutor_gate.dart` (role-based routing)
- `lib/main.dart` (RoleGate component)

---

### 2. Verification Screen (New Tutors Only)
**Purpose:** Upload credentials for admin review

**Layout:**
```
┌─────────────────────────────┐
│ Identity Verification       │
├─────────────────────────────┤
│ Please upload the following │
│ documents for verification: │
│                             │
│ 1. IC / MyKad               │
│    [📎 Upload Photo]        │
│    ✓ ic_photo.jpg           │
│                             │
│ 2. Education Certificate    │
│    [📎 Upload Photo]        │
│    ✓ cert.jpg               │
│                             │
│ 3. Bank Statement           │
│    [📎 Upload Photo]        │
│    ✓ bank_stmt.pdf          │
│                             │
├─────────────────────────────┤
│   [Submit for Review]       │
└─────────────────────────────┘
```

**Features:**
- 3 required document uploads:
  1. **IC/MyKad** (Malaysian ID card)
  2. **Education Certificate** (Degree, diploma, certifications)
  3. **Bank Statement** (For payout verification)

- File picker integration (`image_picker` package)
- Uploads to Firebase Storage: `verifications/{uid}/`
- Creates verification request with status: `pending`

**Implementation:**
- `lib/features/tutor/verify_upload_screen.dart`
- `lib/data/repositories/tutor_repository.dart` (submitVerification)
- `lib/data/repositories/storage_repository.dart` (putFile)

---

### 3. Waiting Screen
**Purpose:** Hold tutors until admin approval

**Layout:**
```
┌─────────────────────────────┐
│                             │
│      ⏳                      │
│                             │
│ Your Profile Is Being       │
│      Verified               │
│                             │
│ We will review your         │
│ documents within 1-2        │
│ business days.              │
│                             │
│                             │
│ [Check Status]              │
└─────────────────────────────┘
```

**Features:**
- Real-time status polling via Firestore stream
- Auto-redirects to dashboard when approved
- Shows rejection message if declined
- "Retry" button if rejected

**Implementation:**
- `lib/features/tutor/tutor_waiting_screen.dart`
- Streams: `verificationRequests/{uid}` for status updates

---

### 4. Dashboard (Verified Tutors)
**Navigation:** After verification → Tutor Dashboard

**Layout:**
```
┌─────────────────────────────┐
│ Hi, Tutor Name   [🟢 Online]│
├─────────────────────────────┤
│ STATS                       │
│ ┌─────┐ ┌─────┐ ┌─────┐    │
│ │ 12  │ │ 4.8 │ │RM   │    │
│ │Sess │ │⭐   │ │450  │    │
│ └─────┘ └─────┘ └─────┘    │
├─────────────────────────────┤
│ QUICK ACTIONS               │
│ [📚 Class History]          │
│ [💰 Earnings & Payout]      │
│ [✓ Verification Status]     │
│ [⚙️ Account Settings]       │
│ [💬 Messages]               │
├─────────────────────────────┤
│ BOTTOM NAV BAR             │
│ [🏠 Home] [💬 Messages]    │
│          [👤 Profile]      │
└─────────────────────────────┘
```

**Features:**

#### **Online/Offline Toggle**
- **Like Grab Driver:** Toggle to accept/decline new bookings
- **Online:** Visible in student search results
- **Offline:** Hidden from search, existing bookings unaffected
- Updates: `tutorProfiles/{uid}.isOnline`

#### **Stats Cards:**
- **Sessions:** Total completed sessions
- **Rating:** Average rating from student reviews
- **Earnings:** Total earnings from completed sessions (RM)

#### **Quick Actions:**
- **Class History:** View all past sessions (with statistics dialog)
- **Earnings & Payout:** View earnings breakdown (future: payout integration)
- **Verification Status:** Re-upload documents if needed
- **Account Settings:** Edit profile, change password
- **Messages:** View booking notifications and student chats

**Implementation:**
- `lib/features/tutor/tutor_dashboard_screen.dart`
- `lib/features/tutor/shell/tutor_shell.dart` (bottom nav)
- `lib/data/repositories/tutor_repository.dart` (setOnline)

---

### 5. Messages & Booking Notifications
**Navigation:** Dashboard → Messages OR Bottom nav → Messages tab

**Layout:**
```
┌─────────────────────────────┐
│ Messages & Bookings         │
├─────────────────────────────┤
│ BOOKING REQUESTS (3)        │
│ ┌───────────────────────┐   │
│ │ 🔔 New Booking        │   │
│ │ Student: Alice        │   │
│ │ Subject: Maths        │   │
│ │ Time: 3:00 PM today   │   │
│ │ [Accept] [Decline]    │   │
│ └───────────────────────┘   │
├─────────────────────────────┤
│ CHATS                       │
│ ┌───────────────────────┐   │
│ │ Alice • 2 min ago     │   │
│ │ When will class start?│   │
│ └───────────────────────┘   │
│ ┌───────────────────────┐   │
│ │ Bob • 1 hour ago      │   │
│ │ Thanks for the help!  │   │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

**Features:**

#### **Booking Notifications:**
- Real-time booking requests from students
- Shows: Student name, subject, date/time, duration, price
- Status badges: Pending (orange), Paid (blue), Accepted (green)
- **Actions:**
  - **Accept:** Opens chat thread with student
  - **Decline:** Cancels booking, triggers refund

#### **Chat Threads:**
- List of active conversations with students
- Shows last message and timestamp
- Unread message indicator
- Tap to open full chat

#### **Learning Materials:**
- Send/receive documents (future feature)
- File attachments in chat (future)

**Implementation:**
- `lib/features/tutor/tutor_messages_screen.dart`
- `lib/features/tutor/tutor_bookings_screen.dart`
- `lib/features/tutor/tutor_chats_screen.dart`
- `lib/features/tutor/tutor_chat_screen.dart`

---

### 6. Chat with Student
**Navigation:** Tap chat thread → Chat Screen

**Layout:**
```
┌─────────────────────────────┐
│ ← Student Name              │
├─────────────────────────────┤
│                             │
│ [Student]: When start? 😊    │
│                             │
│      [Tutor]: In 10 mins     │
│                             │
│                             │
├─────────────────────────────┤
│   [🎥 Start Class]          │
├─────────────────────────────┤
│ [Type message...] [Send ➤]  │
└─────────────────────────────┘
```

**Features:**
- Real-time messaging
- **"Start Class" button:**
  - Visible after booking accepted
  - Tutor has 15 minutes to get ready
  - Initiates video call (future integration)
  - Starts session timer

- Send/receive learning materials (future)
- Message history

**Implementation:**
- `lib/features/tutor/tutor_chat_screen.dart`

---

### 7. Profile Management
**Navigation:** Bottom nav → Profile OR Dashboard → Account Settings

**Layout:**
```
┌─────────────────────────────┐
│ Edit Tutor Profile          │
├─────────────────────────────┤
│ 👤 [Upload Photo]           │
│                             │
│ Display Name:               │
│ [Dr. Smith]                 │
│                             │
│ Introduction:               │
│ [text area]                 │
│                             │
│ Teaching Style:             │
│ [text area]                 │
│                             │
│ Experience:                 │
│ [5 years]                   │
│                             │
│ Education:                  │
│ [PhD in Mathematics]        │
│                             │
│ Subjects: [+ Add]           │
│ [Maths] [Science] [Physics] │
│                             │
│ Languages: [+ Add]          │
│ [English] [BM] [Chinese]    │
│                             │
│ Grade Levels: [+ Add]       │
│ [Form 1] [Form 2] [Form 3]  │
│                             │
│ ⚠️ Rating & Reviews:        │
│    (Cannot be edited)       │
│    ⭐ 4.8 (12 reviews)       │
│                             │
├─────────────────────────────┤
│   [Save Changes]            │
└─────────────────────────────┘
```

**Editable Fields:**
- Profile photo
- Display name
- Introduction/bio
- Teaching style
- Experience
- Education background
- Certificates (future)
- Subjects taught (multi-select chips)
- Languages spoken (multi-select chips)
- Grade levels (multi-select chips)

**Read-Only Fields:**
- Average rating
- Total reviews
- Review list

**Note:** Profile is visible to students browsing tutors

**Implementation:**
- `lib/features/tutor/tutor_profile_edit_screen.dart`
- Saves to: `tutorProfiles/{uid}`
- Also updates: `users/{uid}.displayName`

---

### 8. Class History
**Navigation:** Dashboard → Class History

**Layout:**
```
┌─────────────────────────────┐
│ Session History      [📊]   │
├─────────────────────────────┤
│ Filters: [All ▼]            │
│ [All] [Completed] [Upcoming]│
│     [Pending] [Cancelled]   │
├─────────────────────────────┤
│ SESSION CARDS               │
│ ┌───────────────────────┐   │
│ │ A  Alice • Maths      │   │
│ │    30 min • RM 25     │   │
│ │    Jan 15 • ✓ Done    │   │
│ └───────────────────────┘   │
│ ┌───────────────────────┐   │
│ │ B  Bob • Science      │   │
│ │    60 min • RM 50     │   │
│ │    Jan 14 • ✓ Done    │   │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

**Features:**
- Filter by status (All, Completed, Upcoming, Pending, Cancelled)
- Shows student info, subject, duration, earnings, date
- **Statistics Dialog:**
  - Total sessions
  - Completed count
  - Pending count
  - Cancelled count
  - Total earnings (RM)

**Implementation:**
- `lib/features/tutor/tutor_booking_history_screen.dart`
- `lib/data/repositories/booking_repository.dart` (getTutorBookings)

---

## 🛡️ Admin Flow

### 1. Authentication
**Entry Point:** App Launch → Admin Login

**Layout:**
```
┌─────────────────────────────┐
│ QuickTutor Admin            │
├─────────────────────────────┤
│                             │
│  🛡️                         │
│                             │
│ Email:                      │
│ [admin@quicktutor.com]      │
│                             │
│ Password:                   │
│ [••••••••]                  │
│                             │
│   [Login as Admin]          │
│                             │
└─────────────────────────────┘
```

**Implementation:**
- `lib/features/admin/admin_login_screen.dart`
- Checks: `users/{uid}.role == 'admin'`

---

### 2. Admin Dashboard
**Navigation:** After login → Admin Dashboard

**Layout:**
```
┌─────────────────────────────┐
│ Admin Dashboard             │
├─────────────────────────────┤
│ MANAGEMENT PANELS           │
│                             │
│ ┌───────────────────────┐   │
│ │ 👥 User Management    │   │
│ │ Add/Delete Users      │ ➤ │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ ✓ Tutor Verification  │   │
│ │ Approve/Reject (3)    │ ➤ │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ 📚 Booking Records    │   │
│ │ View All Activities   │ ➤ │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ ⚙️ Account Settings   │   │
│ │ Username, Password    │ ➤ │
│ └───────────────────────┘   │
│                             │
└─────────────────────────────┘
```

**Features:**
- **User Management:** Add/delete/edit users
- **Tutor Verification:** Review pending tutors
- **Booking Records:** View all platform bookings
- **Account Settings:** Change admin credentials

**Implementation:**
- `lib/features/admin/admin_dashboard_screen.dart`
- `lib/features/admin/shell/admin_shell.dart`

---

### 3. Tutor Verification Queue
**Navigation:** Dashboard → Tutor Verification

**Layout (Desktop/Tablet):**
```
┌──────────────┬──────────────────────────────┐
│ PENDING (3)  │ VERIFICATION DETAILS         │
├──────────────┼──────────────────────────────┤
│ ┌──────────┐│  👤 Dr. Alice Smith          │
│ │ AS       ││  alice@example.com           │
│ │ Alice    ││                              │
│ │ Submitted││  Submitted: 2 hours ago      │
│ │ 2h ago   ││                              │
│ └──────────┘│  DOCUMENTS:                  │
│             │  ┌─────────────────────────┐ │
│ ┌──────────┐│  │ IC / MyKad       [View]│ │
│ │ JD       ││  │ Education Cert   [View]│ │
│ │ John Doe ││  │ Bank Statement   [View]│ │
│ │ 5h ago   ││  └─────────────────────────┘ │
│ └──────────┘│                              │
│             │  Tutor Info:                 │
│ ┌──────────┐│  • Subjects: Maths, Science  │
│ │ MJ       ││  • Experience: 5 years       │
│ │ Mary Jane││  • Education: PhD Math       │
│ │ 1d ago   ││                              │
│ └──────────┘│  [Approve] [Reject]          │
└──────────────┴──────────────────────────────┘
```

**Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Tutor Verification        │
├─────────────────────────────┤
│ PENDING REQUESTS (3)        │
│                             │
│ ┌───────────────────────┐   │
│ │ AS  Dr. Alice Smith   │   │
│ │     alice@example.com │   │
│ │     2 hours ago       │ ➤ │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ JD  John Doe          │   │
│ │     john@example.com  │   │
│ │     5 hours ago       │ ➤ │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ MJ  Mary Jane         │   │
│ │     mary@example.com  │   │
│ │     1 day ago         │ ➤ │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

**Features:**

#### **Verification List:**
- Shows all pending verification requests
- Real-time updates via Firestore stream
- Displays: Tutor name, email, submission time
- Click to view full details

#### **Verification Details:**
- **Tutor Information:**
  - Name, email
  - Submission timestamp
  - Subjects, experience, education (from profile)

- **Document Review:**
  - IC/MyKad photo (clickable to view full-size)
  - Education certificate (clickable)
  - Bank statement (clickable)
  - Opens in system browser via `url_launcher`

#### **Actions:**
- **Approve:**
  - Sets `users/{uid}.tutorVerified = true`
  - Sets `tutorProfiles/{uid}.verified = true`
  - Updates `verificationRequests/{uid}.status = 'approved'`
  - Sends approval notification to tutor
  - Tutor auto-redirects to dashboard

- **Reject:**
  - Shows rejection reason dialog (optional)
  - Sets `verificationRequests/{uid}.status = 'rejected'`
  - Stores rejection reason
  - Sends rejection notification to tutor
  - Tutor sees rejection message with retry option

**Implementation:**
- `lib/features/admin/verify/admin_verification_screen.dart` (master-detail view)
- `lib/features/admin/verify/admin_verification_detail_screen.dart`
- `lib/features/admin/verify_queue_screen.dart` (legacy)
- `lib/data/repositories/admin_repository.dart`

---

### 4. Booking Records
**Navigation:** Dashboard → Booking Records

**Layout:**
```
┌─────────────────────────────┐
│ All Platform Bookings  [📊] │
├─────────────────────────────┤
│ Search: [subject, ID...]    │
├─────────────────────────────┤
│ Filters:                    │
│ [All] [Completed] [Pending] │
│     [Paid] [Cancelled]      │
├─────────────────────────────┤
│ Summary:                    │
│ Total: 45 | Revenue: RM2250 │
│          | Completed: 32    │
├─────────────────────────────┤
│ BOOKING CARDS               │
│ ┌───────────────────────┐   │
│ │ 🎓 Alice → 👨‍🏫 Dr.S  │   │
│ │ Maths • 30min • RM25  │   │
│ │ Jan 15 • ✓ Completed  │   │
│ │ ID: abc123...         │   │
│ └───────────────────────┘   │
│ ┌───────────────────────┐   │
│ │ 🎓 Bob → 👨‍🏫 Prof.J  │   │
│ │ Science • 60min • RM50│   │
│ │ Jan 14 • ⏳ Pending   │   │
│ │ ID: def456...         │   │
│ └───────────────────────┘   │
└─────────────────────────────┘
```

**Features:**

#### **Search & Filter:**
- **Search by:**
  - Subject (e.g., "Mathematics")
  - Student ID
  - Tutor ID
  - Booking ID
- **Filter by status:**
  - All Bookings
  - Completed
  - Pending
  - Paid/Accepted
  - Cancelled

#### **Summary Bar:**
- Total bookings count
- Platform revenue (RM)
- Completed sessions count

#### **Booking Details:**
- Student name and ID
- Tutor name and ID
- Subject
- Duration (minutes)
- Price (RM)
- Status (with color-coded badges)
- Created date
- Booking ID

#### **Platform Statistics Dialog:**
- Total bookings
- Completed count
- Pending count
- Cancelled count
- Visual cards with icons

**Implementation:**
- `lib/features/admin/bookings/admin_booking_history_screen.dart`
- `lib/data/repositories/booking_repository.dart` (getAllBookings)

---

### 5. User Management
**Navigation:** Dashboard → User Management

**Current Status:** Implemented in admin shell

**Features (Future Enhancement):**
- View all users (students, tutors, admins)
- Add new users
- Delete users
- Edit user roles
- Reset passwords
- Ban/unban users

**Implementation:**
- `lib/features/admin/users/admin_users_screen.dart` (basic structure exists)

---

### 6. Account Settings
**Navigation:** Dashboard → Account Settings

**Features:**
- Change admin username
- Change admin password
- Email preferences
- Security settings

**Implementation:**
- `lib/features/admin/account/admin_account_screen.dart`

---

## 🗄️ Database Structure

### Firestore Collections

#### **users/{uid}**
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "role": "student | tutor | admin",
  "tutorVerified": false,
  "displayName": "John Doe",
  "fcmToken": "fcm_device_token",
  "fcmTokens": ["token1", "token2"],
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### **tutorProfiles/{uid}**
```json
{
  "uid": "tutor123",
  "displayName": "Dr. Smith",
  "bio": "Experienced math tutor...",
  "intro": "Hi, I'm Dr. Smith...",
  "teachingStyle": "Interactive and patient",
  "experience": "5 years",
  "education": "PhD in Mathematics",
  "subjects": ["Mathematics", "Physics"],
  "languages": ["English", "BM", "Chinese"],
  "grades": ["Form 1", "Form 2", "Form 3"],
  "hourlyRate": 50,
  "photoUrl": "https://storage.../avatar.jpg",
  "rating": 4.8,
  "totalReviews": 12,
  "verified": true,
  "isOnline": true,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### **verificationRequests/{uid}**
```json
{
  "uid": "tutor123",
  "status": "pending | approved | rejected",
  "submittedAt": Timestamp,
  "reviewedAt": Timestamp,
  "reviewedBy": "admin_uid",
  "reviewNote": "Optional note",
  "files": {
    "icUrl": "https://storage.../ic.jpg",
    "eduCertUrl": "https://storage.../cert.jpg",
    "bankStmtUrl": "https://storage.../bank.pdf"
  },
  "tutorEmail": "tutor@example.com",
  "tutorName": "Dr. Smith"
}
```

#### **bookings/{bookingId}**
```json
{
  "bookingId": "booking123",
  "studentId": "student_uid",
  "tutorId": "tutor_uid",
  "subject": "Mathematics",
  "minutes": 30,
  "price": 25,
  "status": "pending | paid | accepted | completed | cancelled",
  "message": "Need help with algebra",
  "createdAt": Timestamp,
  "startAt": Timestamp,
  "studentName": "Alice",
  "tutorName": "Dr. Smith"
}
```

#### **chats/{threadId}**
```json
{
  "threadId": "student123_tutor456",
  "studentId": "student123",
  "tutorId": "tutor456",
  "lastMessage": "Thanks for the help!",
  "lastTs": Timestamp,
  "unreadByStudent": 0,
  "unreadByTutor": 2,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### **chats/{threadId}/messages/{msgId}** (Subcollection)
```json
{
  "msgId": "msg123",
  "from": "student123",
  "text": "When will class start?",
  "ts": Timestamp,
  "read": false
}
```

#### **tutorProfiles/{uid}/reviews/{reviewId}** (Subcollection)
```json
{
  "reviewId": "review123",
  "studentId": "student123",
  "studentName": "Alice",
  "rating": 5,
  "comment": "Great teacher!",
  "bookingId": "booking123",
  "createdAt": Timestamp
}
```

#### **notifications/{uid}/items/{notifId}** (Subcollection)
```json
{
  "notifId": "notif123",
  "type": "booking | verification | message",
  "title": "New Booking Request",
  "body": "Alice wants to book a session",
  "data": {
    "bookingId": "booking123"
  },
  "read": false,
  "createdAt": Timestamp
}
```

### Firebase Storage Structure
```
gs://quicktutor.appspot.com/
├── verifications/{uid}/
│   ├── ic.jpg
│   ├── edu_cert.jpg
│   └── bank_stmt.pdf
│
├── tutor_avatars/{uid}.jpg
│
├── profilePhotos/{uid}/avatar.jpg
│
├── chatAttachments/{threadId}/
│   └── {timestamp}_{filename}
│
└── verificationDocs/{uid}/
    └── {document_type}.{ext}
```

---

## 🎨 Design System

### Color Themes

#### **Student Theme** (`lib/theme/student_theme.dart`)
```dart
kStudentBg: Color(0xFFF8F9FA)    // Soft white background
kStudentPrimary: Color(0xFF2196F3) // Blue primary
kStudentDeep: Color(0xFF0D47A1)   // Deep blue text
kStudentAccent: Color(0xFFFFEB3B)  // Yellow accent
```

#### **Tutor Theme** (`lib/theme/tutor_theme.dart`)
```dart
kBg: Color(0xFFFFFBF5)          // Warm white background
kPrimary: Color(0xFF1A237E)     // Deep blue primary
kAccent: Color(0xFFFFF9C4)      // Soft yellow accent
```

#### **Admin Theme** (Default Material Theme)
- Uses system default colors
- Professional blue/grey palette

### Typography
- **Headings:** Bold, 18-24px
- **Body:** Regular, 14-16px
- **Captions:** 12px, grey color

### Components
- **Cards:** Rounded corners (12px), elevation 2
- **Buttons:** Filled (primary action), Tonal (secondary)
- **Chips:** Filter chips, choice chips for multi-select
- **Badges:** Status indicators with color coding

---

## 🔔 Push Notifications

### Implementation
- **Package:** `firebase_messaging: ^15.2.10`
- **Service:** `lib/services/push/push_service.dart`
- **Background Handler:** `lib/services/push/push_background.dart`

### Features
- **FCM Token Management:**
  - Stored in `users/{uid}.fcmTokens` array
  - Supports multiple devices per user
  - Auto-refresh on token updates

- **Notification Types:**
  1. **Booking Notifications** (Student → Tutor)
  2. **Verification Updates** (Admin → Tutor)
  3. **Message Notifications** (Student ↔ Tutor)

- **iOS Configuration:**
  - Foreground presentation: Alert, Badge, Sound
  - Background handler registered in main entry points

### Cloud Functions (Future)
```javascript
// Trigger on booking creation
exports.onBookingCreate = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate((snap, context) => {
    // Send push to tutor
  });
```

---

## 🚀 App Entry Points

### 1. **Main App** (`lib/main.dart`)
- **Purpose:** Universal entry point with role-based routing
- **Flow:**
  ```
  App Launch
    ↓
  Check Firebase Auth
    ├─ Not logged in → Login Screen
    └─ Logged in → Check users/{uid}.role
       ├─ role == 'student' → StudentShell
       ├─ role == 'tutor' → Check tutorVerified
       │   ├─ verified → TutorShell
       │   └─ not verified → TutorVerifyScreen
       └─ role == 'admin' → AdminDashboard
  ```

### 2. **Student App** (`lib/main_student.dart`)
- **Purpose:** Student-only build (faster development)
- **Entry:** Directly to `StudentShell`

### 3. **Tutor App** (`lib/main_tutor.dart`)
- **Purpose:** Tutor-only build
- **Entry:** `TutorGate` → checks verification → routes accordingly

### 4. **Admin App** (uses `main.dart`)
- **Entry:** `AdminLoginScreen` → `AdminDashboard`

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.15.2
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.12
  firebase_storage: ^12.4.10
  firebase_messaging: ^15.2.10
  
  # File Handling
  image_picker: ^1.0.7
  
  # Navigation
  url_launcher: ^6.2.5
  
  # UI
  # (using Material Design 3)
```

---

## 🔐 Security Rules

### Firestore Rules (Summary)
```javascript
// Users collection
match /users/{uid} {
  allow read: if request.auth.uid == uid || isAdmin();
  allow write: if request.auth.uid == uid;
}

// Tutor Profiles (public read)
match /tutorProfiles/{uid} {
  allow read: if true;
  allow write: if request.auth.uid == uid || isAdmin();
}

// Bookings (participant-only access)
match /bookings/{id} {
  allow read: if isParticipant() || isAdmin();
  allow create: if request.auth != null;
  allow update: if isParticipant() || isAdmin();
}

// Verification Requests (tutor + admin)
match /verificationRequests/{uid} {
  allow read: if request.auth.uid == uid || isAdmin();
  allow write: if isAdmin();
  allow create: if request.auth.uid == uid;
}

// Chats (participants only)
match /chats/{threadId} {
  allow read, write: if isParticipant();
}
```

---

## 📊 Analytics & Monitoring (Future)

- **Firebase Analytics:** Track user behavior
- **Crashlytics:** Monitor app stability
- **Performance Monitoring:** Optimize load times

---

## 🎯 Future Enhancements

### Phase 1 (Priority)
- [ ] Video call integration (Zoom/Agora/Jitsi)
- [ ] Payment gateway integration (Stripe/PayPal/iPay88)
- [ ] Student review & rating system
- [ ] Real notification system (Cloud Functions)

### Phase 2 (Medium Priority)
- [ ] Learning material file sharing
- [ ] Session recording & playback
- [ ] Tutor availability calendar
- [ ] Advanced search filters (price range, rating)
- [ ] Tutor earnings payout system

### Phase 3 (Long-term)
- [ ] In-app whiteboard
- [ ] Screen sharing
- [ ] Group tutoring sessions
- [ ] Subscription plans for students
- [ ] Tutor analytics dashboard
- [ ] Parent monitoring (for underage students)
- [ ] Multi-language support

---

## 🏗️ Project Structure

```
lib/
├── main.dart                 # Universal entry point
├── main_student.dart         # Student-only entry
├── main_tutor.dart           # Tutor-only entry
├── main_admin.dart           # Admin-only entry (future)
│
├── core/
│   └── app_routes.dart       # Route definitions
│
├── theme/
│   ├── student_theme.dart    # Student color scheme
│   ├── tutor_theme.dart      # Tutor color scheme
│   └── app_theme.dart        # Default theme
│
├── features/
│   ├── auth/                 # Login, signup screens
│   ├── gates/                # Role-based routing gates
│   ├── student/              # Student screens
│   │   ├── shell/            # Bottom navigation
│   │   ├── profile/          # Profile screens
│   │   └── messages/         # Chat screens
│   ├── tutor/                # Tutor screens
│   │   └── shell/            # Bottom navigation
│   └── admin/                # Admin screens
│       ├── shell/            # Admin navigation
│       ├── verify/           # Verification system
│       ├── users/            # User management
│       ├── bookings/         # Booking management
│       └── account/          # Admin settings
│
├── data/
│   ├── models/               # Data models
│   │   ├── user_model.dart
│   │   ├── booking_model.dart
│   │   └── ...
│   └── repositories/         # Data layer
│       ├── tutor_repository.dart
│       ├── booking_repository.dart
│       ├── admin_repository.dart
│       └── storage_repository.dart
│
└── services/
    ├── auth_service.dart     # Authentication service
    ├── firestore_paths.dart  # Firestore path helpers
    └── push/                 # Push notification service
        ├── push_service.dart
        └── push_background.dart
```

---

## 🧪 Testing Strategy

### Manual Testing Checklist

#### Student Flow
- [ ] Sign up as student
- [ ] Browse tutors with filters
- [ ] View tutor profile
- [ ] Book a session
- [ ] Complete payment
- [ ] Chat with tutor
- [ ] View booking history
- [ ] Rate tutor after session

#### Tutor Flow
- [ ] Sign up as tutor
- [ ] Upload verification documents
- [ ] Wait for admin approval
- [ ] Toggle online status
- [ ] Receive booking notification
- [ ] Accept/decline booking
- [ ] Chat with student
- [ ] Start class
- [ ] View earnings
- [ ] Edit profile

#### Admin Flow
- [ ] Login as admin
- [ ] View pending verifications
- [ ] Review tutor documents
- [ ] Approve tutor
- [ ] Reject tutor (with reason)
- [ ] View all bookings
- [ ] Search bookings
- [ ] View platform statistics
- [ ] Manage users

---

## 📝 Conclusion

**QuickTutor** is a comprehensive three-role tutoring platform with:
- **Minimalist design** for clarity and ease of use
- **Educational focus** with verified tutors and structured sessions
- **Simple workflows** from search to booking to session completion
- **Professional verification** ensuring tutor quality
- **Real-time features** for chat and notifications
- **Scalable architecture** ready for future enhancements

**Current Status:** ✅ Core features implemented and functional  
**Next Steps:** Video integration, payment gateway, review system

---

**Document Version:** 2.0  
**Last Updated:** October 30, 2025  
**Author:** QuickTutor Development Team
