# QuickTutor - Entity Relationship Diagram (ERD)

## Database: Firebase Firestore

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          QUICKTUTOR DATABASE SCHEMA                          │
└─────────────────────────────────────────────────────────────────────────────┘

┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃      users/{uid}      ┃ (Root Collection)
┣━━━━━━━━━━━━━━━━━━━━━━━┫
│ uid (PK)              │ String - Firebase Auth UID
│ email                 │ String
│ role                  │ String - 'student'|'tutor'|'admin'
│ tutorVerified         │ Boolean
│ displayName           │ String
│ fcmToken              │ String - Push notification token
│ fcmTokens             │ Array<String> - Multiple device tokens
│ fcmUpdatedAt          │ Timestamp
│ createdAt             │ Timestamp
│ updatedAt             │ Timestamp
┗━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │ 1:1 (if role='tutor')
         ↓
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  tutorProfiles/{uid}           ┃ (Root Collection)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
│ uid (PK, FK→users)             │ String
│ displayName                    │ String
│ bio                            │ String
│ intro                          │ String
│ teachingStyle                  │ String
│ experience                     │ String
│ education                      │ String
│ subjects                       │ Array<String>
│ languages                      │ Array<String>
│ grades                         │ Array<String>
│ hourlyRate                     │ Number
│ photoUrl                       │ String - Avatar URL (Storage)
│ rating                         │ Number
│ totalReviews                   │ Number
│ verified                       │ Boolean
│ createdAt                      │ Timestamp
│ updatedAt                      │ Timestamp
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │ 1:N
         ↓
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  tutorProfiles/{uid}/reviews/{reviewId}  ┃ (Subcollection)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
│ reviewId (PK)                             │ Auto-generated
│ studentId (FK→users)                      │ String
│ studentName                               │ String
│ rating                                    │ Number (1-5)
│ comment                                   │ String
│ bookingId (FK→bookings)                   │ String
│ createdAt                                 │ Timestamp
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  verificationRequests/{uid}        ┃ (Root Collection)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
│ uid (PK, FK→users)                 │ String - Tutor UID
│ status                             │ String - 'pending'|'approved'|'rejected'
│ submittedAt                        │ Timestamp
│ reviewedAt                         │ Timestamp
│ reviewedBy (FK→users)              │ String - Admin UID
│ reason                             │ String - Rejection reason
│ documents                          │ Array<String> - Document URLs
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  bookings/{bookingId}         ┃ (Root Collection)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
│ bookingId (PK)                │ Auto-generated
│ studentId (FK→users)          │ String
│ tutorId (FK→users)            │ String
│ subject                       │ String
│ sessionType                   │ String - 'online'|'in-person'
│ date                          │ Timestamp
│ time                          │ String
│ duration                      │ Number (hours)
│ hourlyRate                    │ Number
│ totalAmount                   │ Number
│ status                        │ String - 'pending'|'accepted'|'declined'|'completed'|'cancelled'
│ message                       │ String - Student message
│ tutorResponse                 │ String
│ createdAt                     │ Timestamp
│ updatedAt                     │ Timestamp
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  chats/{threadId}               ┃ (Root Collection)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
│ threadId (PK)                   │ String - Composite: "studentId_tutorId"
│ studentId (FK→users)            │ String
│ tutorId (FK→users)              │ String
│ lastMessage                     │ String
│ lastTs                          │ Timestamp
│ unreadByStudent                 │ Number
│ unreadByTutor                   │ Number
│ createdAt                       │ Timestamp
│ updatedAt                       │ Timestamp
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         │ 1:N
         ↓
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  chats/{threadId}/messages/{msgId}  ┃ (Subcollection)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
│ msgId (PK)                          │ Auto-generated
│ from (FK→users)                     │ String - Sender UID
│ text                                │ String - Message content
│ ts                                  │ Timestamp
│ read                                │ Boolean
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  notifications/{uid}/items/{notifId}     ┃ (Root + Subcollection)
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
│ uid (Collection Key, FK→users)           │ String - Recipient UID
│ notifId (PK)                             │ Auto-generated
│ type                                     │ String - 'booking'|'verification'|'message'
│ title                                    │ String
│ body                                     │ String
│ data                                     │ Map - Additional payload
│ read                                     │ Boolean
│ createdAt                                │ Timestamp
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


═══════════════════════════════════════════════════════════════════════════
                              RELATIONSHIPS
═══════════════════════════════════════════════════════════════════════════

┌────────────┐                ┌──────────────────┐
│   users    │────────1:1────▶│ tutorProfiles    │
│            │   (if tutor)   │                  │
└────────────┘                └──────────────────┘
      │                                 │
      │                                 │
      │ 1:1                             │ 1:N
      │                                 ↓
      ↓                        ┌──────────────────┐
┌────────────┐                │     reviews      │ (subcollection)
│verification│                └──────────────────┘
│  Requests  │
└────────────┘

┌────────────┐
│   users    │
│ (student)  │───────┐
└────────────┘       │
                     │ N:M (via bookings)
┌────────────┐       │
│   users    │       │        ┌────────────┐
│  (tutor)   │───────┴───────▶│  bookings  │
└────────────┘                └────────────┘


┌────────────┐                
│   users    │                
│ (student)  │───────┐        
└────────────┘       │        
                     │ 1:N    
┌────────────┐       │        ┌────────────┐
│   users    │       ├───────▶│   chats    │───1:N──▶ messages (subcollection)
│  (tutor)   │───────┘        └────────────┘
└────────────┘                


┌────────────┐                
│   users    │────────1:N────▶┌────────────────────────┐
│            │                │ notifications/{uid}/... │
└────────────┘                └────────────────────────┘


═══════════════════════════════════════════════════════════════════════════
                         FIREBASE STORAGE STRUCTURE
═══════════════════════════════════════════════════════════════════════════

Storage Bucket (gs://your-project.appspot.com)
│
├── profilePhotos/{uid}/
│   └── avatar.jpg                  // Tutor profile photos
│
├── verificationDocs/{uid}/
│   ├── document1.pdf
│   └── document2.jpg               // Tutor verification documents
│
└── chatAttachments/{threadId}/
    └── {timestamp}_{filename}      // Future: Chat file attachments


═══════════════════════════════════════════════════════════════════════════
                              KEY INDEXES (Recommended)
═══════════════════════════════════════════════════════════════════════════

Collection: tutorProfiles
  • Composite: (verified, rating DESC)
  • Composite: (subjects array-contains, rating DESC)
  • Single: hourlyRate ASC/DESC

Collection: bookings
  • Composite: (studentId, createdAt DESC)
  • Composite: (tutorId, status, createdAt DESC)
  • Single: status

Collection: chats
  • Composite: (studentId, lastTs DESC)
  • Composite: (tutorId, lastTs DESC)

Collection: notifications/{uid}/items
  • Composite: (read, createdAt DESC)


═══════════════════════════════════════════════════════════════════════════
                           DATA FLOW DIAGRAMS
═══════════════════════════════════════════════════════════════════════════

Student Books Tutor:
  Student → creates → bookings/{id}
         → triggers Cloud Function
         → sends push to tutor (via fcmTokens in users/{tutorId})
         → creates → notifications/{tutorId}/items/{id}

Tutor Verification:
  Tutor → uploads docs → Storage (verificationDocs/{uid}/)
        → creates → verificationRequests/{uid}
        → Admin reviews
        → updates → users/{uid}.tutorVerified
        → updates → tutorProfiles/{uid}.verified
        → deletes → verificationRequests/{uid}
        → creates → notifications/{uid}/items/{id}

Chat Flow:
  User A → sends message
         → creates/updates → chats/{threadId}
         → adds → chats/{threadId}/messages/{msgId}
         → increments unreadByB counter

Review Flow:
  Student → completes booking
          → writes → tutorProfiles/{tutorId}/reviews/{reviewId}
          → updates tutorProfile aggregates (rating, totalReviews)


═══════════════════════════════════════════════════════════════════════════
                            SECURITY RULES SUMMARY
═══════════════════════════════════════════════════════════════════════════

users/{uid}:
  • Read: auth.uid == uid || admin
  • Write: auth.uid == uid (own profile)

tutorProfiles/{uid}:
  • Read: anyone (public profiles)
  • Write: auth.uid == uid || admin

tutorProfiles/{uid}/reviews:
  • Read: anyone
  • Write: student who completed booking

bookings/{id}:
  • Read: studentId == auth.uid || tutorId == auth.uid || admin
  • Write: create (student), update status (tutor), delete (admin)

chats/{threadId}:
  • Read/Write: participants only (studentId or tutorId)

verificationRequests/{uid}:
  • Read: auth.uid == uid || admin
  • Write: create (tutor), update/delete (admin)

notifications/{uid}:
  • Read/Write: auth.uid == uid


═══════════════════════════════════════════════════════════════════════════
                              NOTES
═══════════════════════════════════════════════════════════════════════════

1. Primary Key (PK): Unique identifier for the document
2. Foreign Key (FK): References another collection's document
3. Subcollections are denoted with indentation and path notation
4. Array fields (subjects, languages, grades, fcmTokens) use Firestore array operations
5. Timestamps use Firestore FieldValue.serverTimestamp()
6. Push notifications use FCM tokens stored in users collection
7. Chat threadId format: "{studentId}_{tutorId}" for deterministic lookup
8. All monetary values stored as numbers (hourly rates, amounts)
9. Cloud Functions trigger on bookings creation to send push notifications
10. Storage URLs are saved as strings in Firestore documents

```

## Visual ERD (Mermaid Diagram)

```mermaid
erDiagram
    USERS ||--o| TUTOR_PROFILES : "has (if tutor)"
    USERS ||--o| VERIFICATION_REQUESTS : "submits"
    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o{ BOOKINGS : "creates (student)"
    USERS ||--o{ BOOKINGS : "receives (tutor)"
    USERS ||--o{ CHATS : "participates"
    
    TUTOR_PROFILES ||--o{ REVIEWS : "has"
    CHATS ||--|{ MESSAGES : "contains"
    
    USERS {
        string uid PK
        string email
        string role
        boolean tutorVerified
        string displayName
        string fcmToken
        array fcmTokens
        timestamp createdAt
    }
    
    TUTOR_PROFILES {
        string uid PK_FK
        string displayName
        string bio
        array subjects
        array languages
        array grades
        number hourlyRate
        string photoUrl
        number rating
        boolean verified
    }
    
    VERIFICATION_REQUESTS {
        string uid PK_FK
        string status
        timestamp submittedAt
        timestamp reviewedAt
        string reviewedBy FK
    }
    
    BOOKINGS {
        string bookingId PK
        string studentId FK
        string tutorId FK
        string subject
        timestamp date
        number totalAmount
        string status
    }
    
    CHATS {
        string threadId PK
        string studentId FK
        string tutorId FK
        string lastMessage
        timestamp lastTs
    }
    
    MESSAGES {
        string msgId PK
        string from FK
        string text
        timestamp ts
    }
    
    REVIEWS {
        string reviewId PK
        string studentId FK
        number rating
        string comment
    }
    
    NOTIFICATIONS {
        string notifId PK
        string uid FK
        string type
        string title
        boolean read
    }
```

---

**Created:** October 27, 2025  
**Last Updated:** October 27, 2025  
**Database:** Firebase Firestore  
**Storage:** Firebase Storage
