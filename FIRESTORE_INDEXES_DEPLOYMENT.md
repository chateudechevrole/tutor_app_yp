# Firestore Indexes Deployment Guide

## 📋 Overview

This project uses composite Firestore indexes to enable efficient queries for:
- **Booking management** (student & tutor views)
- **Real-time messaging system** (with lastMessageAt sorting)
- **Unread message badges** (hasUnreadMessages filtering)
- **Class sessions and payouts**
- **Tutor verification workflow**

---

## 🚀 Deploy Indexes

### Quick Deploy Command

```bash
firebase deploy --only firestore:indexes
```

**Expected Output:**
```
✔  Deploy complete!

Indexes deployed:
  - bookings (tutorId, status, lastMessageAt DESC)
  - bookings (studentId, status, lastMessageAt DESC)
  - bookings (tutorId, hasUnreadMessages)
  - bookings (studentId, hasUnreadMessages)
  - messages (bookingId, ts ASC) [COLLECTION_GROUP]
  - ... and more
```

---

## 📊 New Messaging Indexes (Recently Added)

### 1. Tutor Messages Ordered by Last Message
```json
{
  "collectionGroup": "bookings",
  "fields": [
    { "fieldPath": "tutorId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
  ]
}
```
**Used by:** `TutorMessagesScreen` - Shows conversations sorted by most recent message

---

### 2. Student Messages Ordered by Last Message
```json
{
  "collectionGroup": "bookings",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
  ]
}
```
**Used by:** `StudentMessagesScreen` - Shows conversations sorted by most recent message

---

### 3. Tutor Unread Messages Badge
```json
{
  "collectionGroup": "bookings",
  "fields": [
    { "fieldPath": "tutorId", "order": "ASCENDING" },
    { "fieldPath": "hasUnreadMessages", "order": "ASCENDING" }
  ]
}
```
**Used by:** Tutor navigation badge to show unread count

---

### 4. Student Unread Messages Badge
```json
{
  "collectionGroup": "bookings",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "hasUnreadMessages", "order": "ASCENDING" }
  ]
}
```
**Used by:** Student Shell navigation - Red dot badge on Messages tab

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
**Used by:** `ChatScreen` - Load messages for any booking efficiently

---

## 🔍 Query Examples Using These Indexes

### Student Messages Screen Query
```dart
FirebaseFirestore.instance
    .collection('bookings')
    .where('studentId', isEqualTo: currentUserId)
    .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
    .orderBy('lastMessageAt', descending: true)
    .snapshots()
```
**Requires Index:** `studentId + status + lastMessageAt DESC` ✅

---

### Tutor Messages Screen Query
```dart
FirebaseFirestore.instance
    .collection('bookings')
    .where('tutorId', isEqualTo: currentUserId)
    .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
    .orderBy('lastMessageAt', descending: true)
    .snapshots()
```
**Requires Index:** `tutorId + status + lastMessageAt DESC` ✅

---

### Student Unread Badge Query
```dart
FirebaseFirestore.instance
    .collection('bookings')
    .where('studentId', isEqualTo: currentUserId)
    .where('hasUnreadMessages', isEqualTo: true)
    .snapshots()
```
**Requires Index:** `studentId + hasUnreadMessages` ✅

---

### Chat Messages Query
```dart
FirebaseFirestore.instance
    .collection('bookings')
    .doc(bookingId)
    .collection('messages')
    .orderBy('ts', descending: false)
    .snapshots()
```
**Requires Index:** Collection group index for `messages` ✅

---

## 📝 Deployment Steps

### Prerequisites
1. Firebase CLI installed: `npm install -g firebase-tools`
2. Logged in: `firebase login`
3. Project selected: `firebase use <project-id>`

### Deploy Command

```bash
firebase deploy --only firestore:indexes
```

**Expected Output:**
```
=== Deploying to 'quicktutor2'...

i  deploying firestore
i  firestore: reading indexes from firestore.indexes.json...
✔  firestore: deployed indexes in firestore.indexes.json successfully

✔  Deploy complete!

Indexes deployed:
  - bookings (tutorId + status + lastMessageAt DESC)
  - bookings (studentId + status + lastMessageAt DESC)  
  - bookings (tutorId + hasUnreadMessages)
  - bookings (studentId + hasUnreadMessages)
  - messages [COLLECTION_GROUP] (bookingId + ts ASC)
```

---

**⏱️ Index Creation Time:**
- Indexes are created in the background
- Small databases: ~1-2 minutes
- Large databases: Could take several minutes to hours
- You can monitor progress in Firebase Console

---

### Step 4: Verify Indexes in Firebase Console

1. Go to: https://console.firebase.google.com
2. Select your project: **QuickTutor2**
3. Navigate to: **Firestore Database** → **Indexes** tab
4. You should see:
   - **4 composite indexes** for the `bookings` collection
   - Status: "Building" → "Enabled" (when ready)

**Indexes Created:**
1. `bookings`: `studentId ASC, createdAt DESC`
2. `bookings`: `studentId ASC, status ASC, createdAt DESC`
3. `bookings`: `tutorId ASC, createdAt DESC`
4. `bookings`: `tutorId ASC, status ASC, createdAt DESC`

---

## 🔍 Troubleshooting

### Error: "No project active"
**Solution:**
```bash
firebase use --add
# Then select your project
```

### Error: "Not authorized"
**Solution:**
```bash
firebase logout
firebase login
```

### Error: "firestore.indexes.json not found"
**Solution:**
Make sure you're in the project root directory:
```bash
cd /Users/yuanping/QuickTutor/quicktutor_2
ls firestore.indexes.json  # Should exist
```

### Error: "Duplicate index"
**Solution:**
The index already exists in Firestore. This is fine - deployment will skip it.

---

## 📊 What These Indexes Enable

### For Students:
```dart
// Get all my bookings, newest first
bookings
  .where('studentId', isEqualTo: myUid)
  .orderBy('createdAt', descending: true)

// Get my completed bookings
bookings
  .where('studentId', isEqualTo: myUid)
  .where('status', isEqualTo: 'completed')
  .orderBy('createdAt', descending: true)
```

### For Tutors:
```dart
// Get all bookings for me, newest first
bookings
  .where('tutorId', isEqualTo: myUid)
  .orderBy('createdAt', descending: true)

// Get my pending bookings
bookings
  .where('tutorId', isEqualTo: myUid)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
```

---

## ✅ Verification

After indexes are enabled, test the booking history feature:

1. **Run the app:**
   ```bash
   flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart
   ```

2. **Navigate to Profile → Booking History**

3. **Verify:**
   - Bookings load without errors
   - Can filter by status (All, Pending, Completed, etc.)
   - Bookings are sorted by date (newest first)

---

## 📝 One-Line Deployment (For Future Use)

Once you're set up, you only need this command:

```bash
firebase deploy --only firestore:indexes
```

Run this whenever you update `firestore.indexes.json`.

---

## 🔗 Related Files

- **Index Definitions**: `/firestore.indexes.json`
- **Firebase Config**: `/firebase.json`
- **Security Rules**: `/firestore.rules`
- **Booking History Screen**: `/lib/features/student/booking_history_screen.dart`

---

## 💡 Tips

1. **Automatic Index Creation:**
   - When you run queries that need indexes, Firebase Console will suggest them
   - You can click the link in the error to auto-create
   - Or add them to `firestore.indexes.json` for version control

2. **Index Management:**
   - Unused indexes don't cost anything
   - You can delete indexes in Firebase Console
   - Keep `firestore.indexes.json` in sync with production

3. **Deployment:**
   - Always deploy indexes before deploying code that uses them
   - Indexes can take time to build on large collections
   - Test queries in small batches first

---

## 🎯 Success Criteria

✅ `firebase login` succeeds  
✅ `firebase use quicktutor2` shows correct project  
✅ `firebase deploy --only firestore:indexes` completes  
✅ Firebase Console shows 4 new indexes  
✅ Booking history loads in the app  
✅ No "index required" errors in console  

---

## 🆘 Need Help?

**Firebase CLI Documentation:**
https://firebase.google.com/docs/cli

**Firestore Indexes Guide:**
https://firebase.google.com/docs/firestore/query-data/indexing

**Check Current Indexes:**
```bash
firebase firestore:indexes
```

**Firebase Console:**
https://console.firebase.google.com/project/quicktutor2/firestore/indexes
