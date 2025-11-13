# Firestore Indexes Update - Messaging System

## ✅ Changes Made

Updated `firestore.indexes.json` with new composite indexes for the messaging system.

---

## 🆕 New Indexes Added

### 1. Tutor Messages with Last Message Sorting
```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "tutorId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
  ]
}
```
**Query:** Get tutor's bookings sorted by most recent message  
**Used in:** `lib/features/tutor/tutor_messages_screen.dart`

---

### 2. Student Messages with Last Message Sorting
```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
  ]
}
```
**Query:** Get student's bookings sorted by most recent message  
**Used in:** `lib/features/student/messages/student_messages_screen.dart`

---

### 3. Tutor Unread Messages
```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "tutorId", "order": "ASCENDING" },
    { "fieldPath": "hasUnreadMessages", "order": "ASCENDING" }
  ]
}
```
**Query:** Get tutor's bookings with unread messages  
**Used in:** Tutor Shell navigation badge (future implementation)

---

### 4. Student Unread Messages
```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "hasUnreadMessages", "order": "ASCENDING" }
  ]
}
```
**Query:** Get student's bookings with unread messages  
**Used in:** `lib/features/student/shell/student_shell.dart` (red badge on Messages tab)

---

### 5. Messages Collection Group
```json
{
  "collectionGroup": "messages",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    { "fieldPath": "bookingId", "order": "ASCENDING" },
    { "fieldPath": "ts", "order": "ASCENDING" }
  ]
}
```
**Query:** Get all messages for a booking across the entire database  
**Used in:** `lib/features/chat/chat_screen.dart`

---

## 📋 Complete Index List

| Collection | Fields | Order | Purpose |
|------------|--------|-------|---------|
| **bookings** | tutorId, status, lastMessageAt | ASC, ASC, DESC | Tutor messages sorted by recent |
| **bookings** | studentId, status, lastMessageAt | ASC, ASC, DESC | Student messages sorted by recent |
| **bookings** | tutorId, hasUnreadMessages | ASC, ASC | Tutor unread badge |
| **bookings** | studentId, hasUnreadMessages | ASC, ASC | Student unread badge |
| **messages** | bookingId, ts | ASC, ASC | Chat messages (collection group) |

---

## 🚀 Deployment

### Command
```bash
firebase deploy --only firestore:indexes
```

### Expected Output
```
=== Deploying to 'quicktutor2'...

i  deploying firestore
i  firestore: reading indexes from firestore.indexes.json...
✔  firestore: deployed indexes in firestore.indexes.json successfully

✔  Deploy complete!
```

### Build Time
- Small database (< 1000 docs): ~1-5 minutes
- Medium database (1000-10000 docs): ~10-20 minutes
- Large database (> 10000 docs): ~30-60 minutes

**Check status:** Firebase Console → Firestore → Indexes

---

## 🔍 Queries That Now Work

### Student Messages Screen
```dart
// Query: Get my conversations sorted by last message
FirebaseFirestore.instance
    .collection('bookings')
    .where('studentId', isEqualTo: userId)
    .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
    .orderBy('lastMessageAt', descending: true)
    .snapshots()
```
✅ **Requires:** `studentId + status + lastMessageAt DESC`

---

### Student Badge (Red Dot)
```dart
// Query: Count unread messages
FirebaseFirestore.instance
    .collection('bookings')
    .where('studentId', isEqualTo: userId)
    .where('hasUnreadMessages', isEqualTo: true)
    .snapshots()
```
✅ **Requires:** `studentId + hasUnreadMessages`

---

### Tutor Messages Screen
```dart
// Query: Get my student conversations
FirebaseFirestore.instance
    .collection('bookings')
    .where('tutorId', isEqualTo: userId)
    .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
    .orderBy('lastMessageAt', descending: true)
    .snapshots()
```
✅ **Requires:** `tutorId + status + lastMessageAt DESC`

---

### Chat Screen
```dart
// Query: Load all messages in a booking
FirebaseFirestore.instance
    .collection('bookings')
    .doc(bookingId)
    .collection('messages')
    .orderBy('ts', descending: false)
    .snapshots()
```
✅ **Requires:** Collection group index for `messages`

---

## 📝 Files Updated

- ✅ `firestore.indexes.json` - Added 5 new composite indexes
- ✅ `FIRESTORE_INDEXES_DEPLOYMENT.md` - Updated deployment guide

---

## ⚠️ Before Deploying

**Checklist:**
- [ ] Firebase CLI installed: `npm install -g firebase-tools`
- [ ] Logged in: `firebase login`
- [ ] Correct project selected: `firebase use <project-id>`
- [ ] Backed up current indexes (if any)
- [ ] Reviewed `firestore.indexes.json` for correctness

---

## 🎯 Quick Reference

**Deploy indexes:**
```bash
firebase deploy --only firestore:indexes
```

**View current indexes:**
```bash
firebase firestore:indexes
```

**Check project:**
```bash
firebase projects:list
```

**Switch project:**
```bash
firebase use <project-id>
```

---

## 📚 Related Documentation

- `MESSAGING_SYSTEM.md` - Complete messaging architecture
- `MESSAGING_IMPLEMENTATION_SUMMARY.md` - Implementation details
- `FIRESTORE_INDEXES_DEPLOYMENT.md` - Full deployment guide
- `firestore.rules` - Security rules

---

**Status:** ✅ Ready to deploy  
**Impact:** Enables efficient messaging queries  
**Breaking Changes:** None (additive only)  
**Rollback:** Not needed (indexes are additive)
