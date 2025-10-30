# QuickTutor - Data Flow Diagram (DFD) Level 1
## Decomposition Diagram - Internal System Processes

---

## 📚 What is DFD Level 1?

**DFD Level 1** breaks down the single "QuickTutor System" process from Level 0 into **major subsystems/processes** and shows:
- **Internal processes** (the major functions)
- **Data stores** (databases/collections)
- **Data flows** between processes and stores
- **Interactions** with external entities

---

## 🎯 Major Processes Identified

From analyzing your codebase, QuickTutor has **7 major processes**:

| Process | Name | Description |
|---------|------|-------------|
| **P1** | User Authentication & Management | Register, login, logout, profile management |
| **P2** | Tutor Profile Management | Create/update tutor profiles, manage subjects/rates |
| **P3** | Booking Management | Create, accept, decline, complete bookings |
| **P4** | Tutor Verification System | Submit docs, admin review, approval workflow |
| **P5** | Search & Discovery | Search tutors by subject, filter, browse |
| **P6** | Chat & Messaging | Real-time messaging between students and tutors |
| **P7** | Notification System | Push notifications and in-app notifications |

---

## 🗄️ Data Stores Identified

From your Firestore database:

| Store | Name | Description |
|-------|------|-------------|
| **D1** | Users | User accounts (students, tutors, admins) |
| **D2** | Tutor Profiles | Extended tutor information, subjects, rates |
| **D3** | Bookings | Session bookings and their statuses |
| **D4** | Chats | Chat threads between students and tutors |
| **D5** | Messages | Individual chat messages |
| **D6** | Verification Requests | Pending tutor verification submissions |
| **D7** | Notifications | User notification items |
| **D8** | Reviews | Tutor reviews and ratings |

---

## 📐 Complete DFD Level 1 Diagram

```
═══════════════════════════════════════════════════════════════════════════════
                        QUICKTUTOR DFD LEVEL 1
                    (Internal System Decomposition)
═══════════════════════════════════════════════════════════════════════════════

External Entities:
┌──────────┐                                                    ┌──────────┐
│ STUDENT  │                                                    │  TUTOR   │
└────┬─────┘                                                    └────┬─────┘
     │                                                               │
     │ Registration                                   Registration  │
     │ Login                                          Login          │
     ├──────────────────────────────────────────────────────────────┤
     │                                                               │
     ▼                                                               ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│  ╔═══════════════════════════════════════════════════════════════════╗   │
│  ║                                                                   ║   │
│  ║  P1: User Authentication & Management                            ║   │
│  ║      • Register new users                                        ║   │
│  ║      • Login/logout                                              ║   │
│  ║      • Update profiles                                           ║   │
│  ║      • Manage FCM tokens                                         ║   │
│  ║                                                                   ║   │
│  ╚═════════════╤═════════════════════════════════╤═════════════════╝   │
│                │                                 │                       │
│                │ Read/Write                      │ Read/Write            │
│                │ User Data                       │ User Data             │
│                ▼                                 ▼                       │
│    ┌─────────────────────┐         ┌─────────────────────┐             │
│    │  D1: Users          │         │  Auth Token         │             │
│    │  (Firestore)        │◄────────┤  (Firebase Auth)    │             │
│    │                     │         │                     │             │
│    │  • uid              │         └─────────────────────┘             │
│    │  • email            │                                             │
│    │  • role             │                                             │
│    │  • fcmTokens        │                                             │
│    └──────┬──────────────┘                                             │
│           │                                                             │
│           │ User Info                                                   │
│           ▼                                                             │
│  ╔═══════════════════════════════════════════════════════════════════╗ │
│  ║                                                                   ║ │
│  ║  P2: Tutor Profile Management                                    ║ │
│  ║      • Create tutor profile                                      ║ │
│  ║      • Update bio, subjects, rates                               ║ │
│  ║      • Upload profile photo                                      ║ │
│  ║      • Manage availability                                       ║ │
│  ║                                                                   ║ │
│  ╚═════════════╤═══════════════════════════════════════════════════╝ │
│                │                                                       │
│                │ Read/Write Profile                                    │
│                ▼                                                       │
│    ┌─────────────────────┐                                            │
│    │  D2: TutorProfiles  │                                            │
│    │  (Firestore)        │                                            │
│    │                     │                                            │
│    │  • uid              │                                            │
│    │  • bio              │                                            │
│    │  • subjects         │                                            │
│    │  • hourlyRate       │                                            │
│    │  • rating           │                                            │
│    │  • verified         │                                            │
│    └──────┬──────────────┘                                            │
│           │                                                            │
│           │ Tutor List                                                │
│           ▼                                                            │
│  ╔═══════════════════════════════════════════════════════════════════╗│
│  ║                                                                   ║│
│  ║  P5: Search & Discovery                                          ║│
│  ║      • Search tutors by subject                                  ║│
│  ║      • Filter by price, rating                                   ║│
│  ║      • Browse available tutors                                   ║│
│  ║                                                                   ║│
│  ╚═════════════╤═════════════════════════════════════════════════════╝│
│                │ Tutor Results                                         │
│                ▼                                                       │
│           (to Student)                                                 │
│                                                                        │
│                ▲ Booking Request                                       │
│                │ (from Student)                                        │
│  ╔═════════════╧═════════════════════════════════════════════════════╗│
│  ║                                                                   ║│
│  ║  P3: Booking Management                                          ║│
│  ║      • Create new booking                                        ║│
│  ║      • Accept/decline booking (tutor)                            ║│
│  ║      • Complete session                                          ║│
│  ║      • Cancel booking                                            ║│
│  ║                                                                   ║│
│  ╚═════════════╤═══════════════════════════════════╤═════════════════╝│
│                │                                   │                   │
│                │ Write Booking                     │ Trigger           │
│                ▼                                   ▼                   │
│    ┌─────────────────────┐              ┌──────────────────┐          │
│    │  D3: Bookings       │              │  P7: Notification│          │
│    │  (Firestore)        │              │      System      │          │
│    │                     │              │                  │          │
│    │  • bookingId        │              │  • Create notif  │          │
│    │  • studentId        │              │  • Send FCM push │          │
│    │  • tutorId          │              │                  │          │
│    │  • status           │              └────────┬─────────┘          │
│    │  • date/time        │                       │                    │
│    │  • totalAmount      │                       │ Store Notification │
│    └──────┬──────────────┘                       ▼                    │
│           │                          ┌─────────────────────┐          │
│           │ Booking Info             │  D7: Notifications  │          │
│           ▼                          │  (Firestore)        │          │
│     (to Student/Tutor)               │                     │          │
│                                      │  • notifId          │          │
│                                      │  • type             │          │
│                                      │  • title/body       │          │
│                                      │  • read             │          │
│                                      └─────────────────────┘          │
│                                                                        │
│           ▲ Chat Message                                              │
│           │ (from Student/Tutor)                                      │
│  ╔════════╧══════════════════════════════════════════════════════════╗│
│  ║                                                                   ║│
│  ║  P6: Chat & Messaging                                            ║│
│  ║      • Create chat thread                                        ║│
│  ║      • Send/receive messages                                     ║│
│  ║      • Update unread counts                                      ║│
│  ║      • Mark messages as read                                     ║│
│  ║                                                                   ║│
│  ╚═════════════╤═══════════════════════════════════╤═════════════════╝│
│                │                                   │                   │
│                │ Write Thread                      │ Write Message     │
│                ▼                                   ▼                   │
│    ┌─────────────────────┐          ┌─────────────────────┐          │
│    │  D4: Chats          │          │  D5: Messages       │          │
│    │  (Firestore)        │          │  (Subcollection)    │          │
│    │                     │          │                     │          │
│    │  • threadId         │          │  • msgId            │          │
│    │  • studentId        │          │  • from             │          │
│    │  • tutorId          │          │  • text             │          │
│    │  • lastMessage      │          │  • ts               │          │
│    │  • unreadCounts     │          │  • read             │          │
│    └─────────────────────┘          └─────────────────────┘          │
│                                                                        │
│           ▲ Verification Documents                                    │
│           │ (from Tutor)                                              │
│  ╔════════╧══════════════════════════════════════════════════════════╗│
│  ║                                                                   ║│
│  ║  P4: Tutor Verification System                                   ║│
│  ║      • Submit verification request                               ║│
│  ║      • Upload documents to Storage                               ║│
│  ║      • Admin review workflow                                     ║│
│  ║      • Approve/reject tutors                                     ║│
│  ║                                                                   ║│
│  ╚═════════════╤═══════════════════════════════════╤═════════════════╝│
│                │                                   │                   │
│                │ Write Request                     │ Update Status     │
│                ▼                                   ▼                   │
│    ┌─────────────────────┐          ┌─────────────────────┐          │
│    │ D6: Verification    │          │  D1: Users          │          │
│    │     Requests        │          │  (tutorVerified)    │          │
│    │  (Firestore)        │          │                     │          │
│    │                     │          │  D2: TutorProfiles  │          │
│    │  • uid              │          │  (verified)         │          │
│    │  • status           │          └─────────────────────┘          │
│    │  • documents        │                                            │
│    │  • reviewedBy       │                                            │
│    └─────────────────────┘                                            │
│                                                                        │
│           ▲ Review/Rating                                             │
│           │ (from Student)                                            │
│           │                                                            │
│           │ (After booking completed)                                 │
│    ┌─────────────────────┐                                            │
│    │  D8: Reviews        │                                            │
│    │  (Subcollection)    │                                            │
│    │                     │                                            │
│    │  • reviewId         │                                            │
│    │  • studentId        │                                            │
│    │  • rating (1-5)     │                                            │
│    │  • comment          │                                            │
│    │  • bookingId        │                                            │
│    └─────────────────────┘                                            │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘

                              ┌──────────┐
                              │  ADMIN   │
                              └────┬─────┘
                                   │
                                   │ Verification Decision
                                   │ User Management
                                   ▼
                              (to P4, P1)


External Systems:
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ Firebase Auth   │◄───────►│ Firebase Cloud  │◄───────►│ Firebase        │
│                 │         │  Messaging      │         │  Storage        │
│  • Auth tokens  │         │  • Push notifs  │         │  • Photos       │
│  • User UIDs    │         │                 │         │  • Docs         │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

---

## 🔄 Detailed Process Descriptions

### Process P1: User Authentication & Management

**Inputs:**
- Registration data from Student/Tutor
- Login credentials
- Profile updates
- FCM tokens

**Process:**
1. Validate user credentials
2. Create Firebase Auth account
3. Store user data in D1 (Users)
4. Generate and store FCM tokens for push notifications
5. Handle logout (remove tokens)

**Outputs:**
- Auth tokens to Student/Tutor
- User profile data to other processes
- Success/error messages

**Data Stores Used:**
- D1: Users (Read/Write)

---

### Process P2: Tutor Profile Management

**Inputs:**
- Profile data from Tutor (bio, subjects, hourly rate)
- Profile photo uploads
- User ID from P1

**Process:**
1. Validate tutor exists in D1
2. Create/update tutor profile in D2
3. Upload photos to Firebase Storage
4. Calculate and update rating from D8 (Reviews)

**Outputs:**
- Profile confirmation to Tutor
- Updated profile data to P5 (Search)

**Data Stores Used:**
- D1: Users (Read - verify tutor status)
- D2: TutorProfiles (Read/Write)
- D8: Reviews (Read - aggregate ratings)

---

### Process P3: Booking Management

**Inputs:**
- Booking request from Student (tutor selection, date/time)
- Booking response from Tutor (accept/decline)
- Completion confirmation

**Process:**
1. Validate student and tutor exist
2. Check tutor availability
3. Create booking record in D3
4. Update booking status based on tutor response
5. Trigger P7 for notifications

**Outputs:**
- Booking confirmation to Student
- Booking notification to Tutor (via P7)
- Completed booking data for reviews

**Data Stores Used:**
- D1: Users (Read - student/tutor info)
- D2: TutorProfiles (Read - tutor details)
- D3: Bookings (Read/Write)

**Triggers:**
- P7: Notification System (on booking create/update)

---

### Process P4: Tutor Verification System

**Inputs:**
- Verification documents from Tutor
- Verification decision from Admin

**Process:**
1. Accept document uploads to Firebase Storage
2. Create verification request in D6
3. Admin reviews request
4. Update user status in D1 (tutorVerified)
5. Update tutor profile in D2 (verified)
6. Delete verification request after approval/rejection
7. Trigger P7 for status notification

**Outputs:**
- Verification status to Tutor
- Verification queue to Admin

**Data Stores Used:**
- D1: Users (Write - tutorVerified flag)
- D2: TutorProfiles (Write - verified flag)
- D6: VerificationRequests (Read/Write)

**Triggers:**
- P7: Notification System (on status change)

---

### Process P5: Search & Discovery

**Inputs:**
- Search criteria from Student (subject, grade, price range)
- Filter parameters (rating, hourly rate)

**Process:**
1. Query D2 for matching tutors
2. Filter by subjects, price, rating
3. Sort results (by rating, price)
4. Return verified tutors only (optional)

**Outputs:**
- List of tutor profiles to Student
- Tutor details for selection

**Data Stores Used:**
- D2: TutorProfiles (Read)

---

### Process P6: Chat & Messaging

**Inputs:**
- Chat message from Student
- Chat message from Tutor
- Read receipt updates

**Process:**
1. Create chat thread in D4 (if new conversation)
2. Add message to D5 (Messages subcollection)
3. Update chat metadata (lastMessage, lastTs)
4. Increment unread counter for recipient
5. Trigger P7 for message notification

**Outputs:**
- Message delivery confirmation
- Real-time message updates to Student/Tutor
- Unread count updates

**Data Stores Used:**
- D4: Chats (Read/Write - thread metadata)
- D5: Messages (Write - individual messages)

**Triggers:**
- P7: Notification System (on new message)

---

### Process P7: Notification System

**Inputs:**
- Booking events from P3
- Verification updates from P4
- New messages from P6
- FCM tokens from D1

**Process:**
1. Determine notification type and recipient
2. Fetch FCM tokens from D1
3. Send push notification via Firebase Cloud Messaging
4. Store notification in D7 for in-app display
5. Handle notification read status

**Outputs:**
- Push notification to Student/Tutor device
- In-app notification badge
- Notification list

**Data Stores Used:**
- D1: Users (Read - FCM tokens)
- D7: Notifications (Write)

---

## 📊 Data Store Specifications

### D1: Users (Firestore Collection: `users/{uid}`)

**Fields:**
- `uid` (PK): String - Firebase Auth UID
- `email`: String
- `role`: String - 'student' | 'tutor' | 'admin'
- `tutorVerified`: Boolean
- `displayName`: String
- `fcmTokens`: Array<String>
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

**Accessed By:**
- P1 (Read/Write)
- P2 (Read)
- P3 (Read)
- P4 (Write)
- P7 (Read)

---

### D2: TutorProfiles (Firestore Collection: `tutorProfiles/{uid}`)

**Fields:**
- `uid` (PK, FK → D1)
- `bio`: String
- `subjects`: Array<String>
- `hourlyRate`: Number
- `rating`: Number
- `totalReviews`: Number
- `verified`: Boolean
- `photoUrl`: String

**Accessed By:**
- P2 (Read/Write)
- P3 (Read)
- P5 (Read)

---

### D3: Bookings (Firestore Collection: `bookings/{bookingId}`)

**Fields:**
- `bookingId` (PK)
- `studentId` (FK → D1)
- `tutorId` (FK → D1)
- `status`: String - 'pending' | 'accepted' | 'declined' | 'completed'
- `date`: Timestamp
- `totalAmount`: Number

**Accessed By:**
- P3 (Read/Write)

---

### D4: Chats (Firestore Collection: `chats/{threadId}`)

**Fields:**
- `threadId` (PK) - Composite: "studentId_tutorId"
- `studentId` (FK → D1)
- `tutorId` (FK → D1)
- `lastMessage`: String
- `lastTs`: Timestamp
- `unreadByStudent`: Number
- `unreadByTutor`: Number

**Accessed By:**
- P6 (Read/Write)

---

### D5: Messages (Firestore Subcollection: `chats/{threadId}/messages/{msgId}`)

**Fields:**
- `msgId` (PK)
- `from` (FK → D1)
- `text`: String
- `ts`: Timestamp
- `read`: Boolean

**Accessed By:**
- P6 (Write)

---

### D6: VerificationRequests (Firestore Collection: `verificationRequests/{uid}`)

**Fields:**
- `uid` (PK, FK → D1)
- `status`: String - 'pending' | 'approved' | 'rejected'
- `documents`: Array<String>
- `submittedAt`: Timestamp
- `reviewedBy` (FK → D1)

**Accessed By:**
- P4 (Read/Write)

---

### D7: Notifications (Firestore Collection: `notifications/{uid}/items/{notifId}`)

**Fields:**
- `uid` (Collection Key, FK → D1)
- `notifId` (PK)
- `type`: String - 'booking' | 'verification' | 'message'
- `title`: String
- `body`: String
- `read`: Boolean
- `createdAt`: Timestamp

**Accessed By:**
- P7 (Write)

---

### D8: Reviews (Firestore Subcollection: `tutorProfiles/{uid}/reviews/{reviewId}`)

**Fields:**
- `reviewId` (PK)
- `studentId` (FK → D1)
- `rating`: Number (1-5)
- `comment`: String
- `bookingId` (FK → D3)
- `createdAt`: Timestamp

**Accessed By:**
- P2 (Read - for rating aggregation)

---

## 🔗 Process-to-Process Data Flows

```
P1 ──User Data──► P2 (Tutor profile creation)
P1 ──User Data──► P3 (Booking validation)
P1 ──FCM Tokens─► P7 (Push notifications)

P2 ──Profile Data─► P5 (Search results)

P3 ──Booking Event─► P7 (Booking notifications)

P4 ──Verification─► P7 (Status notifications)
P4 ──Update Status─► P1 (Update tutorVerified flag)

P5 ──Tutor Selection─► P3 (Create booking)

P6 ──Message Event─► P7 (Message notifications)
```

---

## 🎨 Simplified Level 1 Diagram (For Presentations)

```
┌─────────┐                                           ┌─────────┐
│ Student │                                           │  Tutor  │
└────┬────┘                                           └────┬────┘
     │                                                      │
     ├──────────────┬──────────────┬─────────────────────┤
     │              │              │                      │
     ▼              ▼              ▼                      ▼
┌─────────┐   ┌─────────┐   ┌─────────┐          ┌──────────┐
│   P1    │   │   P5    │   │   P3    │          │    P2    │
│  Auth   │──►│ Search  │──►│ Booking │◄────────►│ Profile  │
└────┬────┘   └────┬────┘   └────┬────┘          └────┬─────┘
     │             │             │                     │
     │   ┌─────────┼─────────────┼─────────────────────┤
     │   │         │             │                     │
     ▼   ▼         ▼             ▼                     ▼
   ┌─────────────────────────────────────────────────────┐
   │              Data Stores (Firestore)                │
   │  D1:Users  D2:Profiles  D3:Bookings  D4:Chats      │
   └──────────────────┬──────────────────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │  P6: Chat     │
              │  P7: Notif    │
              └───────────────┘
                      │
                      ▼
              ┌───────────────┐
              │     Admin     │
              │  (P4: Verify) │
              └───────────────┘
```

---

## 📋 Data Flow Matrix (Process × Data Store)

| Process | D1<br>Users | D2<br>Profiles | D3<br>Bookings | D4<br>Chats | D5<br>Messages | D6<br>Verify | D7<br>Notifs | D8<br>Reviews |
|---------|:-----------:|:--------------:|:--------------:|:-----------:|:--------------:|:------------:|:------------:|:-------------:|
| **P1: Auth** | R/W | - | - | - | - | - | - | - |
| **P2: Profile** | R | R/W | - | - | - | - | - | R |
| **P3: Booking** | R | R | R/W | - | - | - | - | - |
| **P4: Verify** | W | W | - | - | - | R/W | - | - |
| **P5: Search** | - | R | - | - | - | - | - | - |
| **P6: Chat** | - | - | - | R/W | W | - | - | - |
| **P7: Notif** | R | - | - | - | - | - | W | - |

**Legend:** R = Read, W = Write, R/W = Read and Write

---

## 🔍 Critical Data Flows Explained

### Flow 1: Student Books a Tutor

```
Student
  │
  │ 1. Browse Tutors
  ▼
P5: Search ──read──► D2: TutorProfiles
  │
  │ 2. Select & Book
  ▼
P3: Booking
  ├──read──► D1: Users (validate student/tutor)
  ├──write─► D3: Bookings (create booking)
  │
  │ 3. Notify Tutor
  ▼
P7: Notification
  ├──read──► D1: Users (get tutor FCM token)
  ├──send──► Firebase Cloud Messaging
  └──write─► D7: Notifications
```

### Flow 2: Tutor Verification Workflow

```
Tutor
  │
  │ 1. Submit Documents
  ▼
P4: Verification
  ├──write─► Firebase Storage (upload docs)
  └──write─► D6: VerificationRequests
  
Admin
  │
  │ 2. Review & Approve
  ▼
P4: Verification
  ├──read──► D6: VerificationRequests
  ├──write─► D1: Users (tutorVerified = true)
  ├──write─► D2: TutorProfiles (verified = true)
  ├──delete► D6: VerificationRequests
  │
  │ 3. Notify Tutor
  ▼
P7: Notification
  └──send──► Tutor
```

### Flow 3: Real-time Chat

```
Student ──message──► P6: Chat
                       ├──write─► D4: Chats (update metadata)
                       ├──write─► D5: Messages (add message)
                       │
                       │ trigger notification
                       ▼
                     P7: Notification
                       └──send──► Tutor
```

### Flow 4: Post-Booking Review

```
Student
  │
  │ (after booking completed)
  ▼
  │ Submit Review
  ▼
  ├──write─► D8: Reviews (tutorProfiles/{tutorId}/reviews/{id})
  │
  │ trigger aggregation
  ▼
P2: Profile Management
  └──update─► D2: TutorProfiles (recalculate rating, totalReviews)
```

---

## 🎯 Next Steps: DFD Level 2

To create **Level 2**, choose one complex process and decompose it further:

**Example: P3 (Booking Management) → Level 2**
- P3.1: Validate Booking Request
- P3.2: Create Booking Record
- P3.3: Process Tutor Response
- P3.4: Handle Cancellation
- P3.5: Complete Session
- P3.6: Calculate Payment

**Example: P7 (Notification System) → Level 2**
- P7.1: Determine Recipients
- P7.2: Fetch FCM Tokens
- P7.3: Format Notification Payload
- P7.4: Send via FCM
- P7.5: Store In-App Notification
- P7.6: Handle Delivery Status

---

## ✅ DFD Level 1 Checklist

- [x] All major processes identified (P1-P7)
- [x] All data stores mapped (D1-D8)
- [x] Process inputs/outputs defined
- [x] Data flows between processes shown
- [x] External entities connected to processes
- [x] Data store access patterns documented
- [x] Critical flows explained step-by-step
- [x] Matrix showing process-store relationships

---

## 📚 References

- **Level 0 Diagram:** See `DFD_LEVEL_0_GUIDE.md`
- **Database ERD:** See `DATABASE_ERD.md`
- **Firestore Structure:** See `lib/services/firestore_paths.dart`
- **Data Models:** See `lib/data/models/`

---

**Created:** October 28, 2025  
**For:** QuickTutor Platform  
**Diagram Type:** Data Flow Diagram Level 1 (Process Decomposition)
**Processes:** 7 major subsystems  
**Data Stores:** 8 Firestore collections/subcollections
