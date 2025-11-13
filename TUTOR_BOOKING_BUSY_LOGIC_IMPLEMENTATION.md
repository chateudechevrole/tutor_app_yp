# Tutor Booking Detail Navigation + Accept/Reject + Busy Logic Implementation

## ✅ Implementation Complete

### Summary
Implemented complete tutor booking management system with:
- Navigation from booking list to detail screen
- Accept/Reject functionality with atomic Firestore updates
- "Busy tutor" logic to hide tutors from student searches when they have active bookings
- Firestore indexes for efficient queries

---

## 📁 Files Changed

### 1. **lib/core/app_routes.dart**
**Purpose:** Updated route handling to accept both bookingId and studentId

**Changes:**
```dart
case tutorBookingDetail:
  final args = settings.arguments as Map<String, dynamic>;
  return MaterialPageRoute(
    builder: (_) => TutorBookingDetailScreen(
      bookingId: args['bookingId'] as String,
      studentId: args['studentId'] as String,
    ),
  );
```

**Impact:** Route now properly extracts both bookingId and studentId from navigation arguments

---

### 2. **lib/features/tutor/tutor_messages_screen.dart**
**Purpose:** Updated navigation to pass required arguments

**Changes:**
```dart
onTap: () {
  Navigator.pushNamed(
    context,
    Routes.tutorBookingDetail,
    arguments: {
      'bookingId': bookingId,
      'studentId': studentId,
    },
  );
},
```

**Impact:** Booking list now passes both IDs to detail screen

---

### 3. **lib/features/tutor/tutor_booking_detail_screen.dart**
**Purpose:** Complete rewrite with new functionality

**Key Features:**
- **Constructor:** Now accepts `bookingId` and `studentId` as required parameters
- **UI Components:**
  - Student info card with avatar, name, and email
  - Booking details (subject, minutes, price, status, created date)
  - Info card explaining the "busy" logic
  - Accept/Reject buttons (only shown for `pending` or `paid` status)
- **State Management:**
  - `_processing` boolean to disable buttons during API calls
  - Real-time booking updates via StreamBuilder
- **Actions:**
  - `_acceptBooking()`: Calls repository method, shows success message, pops back
  - `_rejectBooking()`: Calls repository method, shows success message, pops back
- **Error Handling:** Try-catch blocks with user-friendly error messages

**UI Flow:**
```
[Student Avatar] [Name + Email]

Booking Details:
Subject: Mathematics
Minutes: 45 min
Price: RM 50.00
Status: PENDING
Created At: 31/10/2025 at 14:30

[Info Card: Explains busy logic]

[Reject Button] [Accept Button (larger)]
```

**Important Note:** 
- Handles empty/null photoURL gracefully to prevent image loading errors
- Only shows action buttons when status is `pending` or `paid`
- Uses `kPrimary` color from tutor theme
- Includes loading spinner during processing

---

### 4. **lib/data/repositories/booking_repository.dart**
**Purpose:** Added atomic accept/reject operations

**New Methods:**

#### `acceptBooking(String bookingId, String tutorId)`
```dart
Future<void> acceptBooking(String bookingId, String tutorId) async {
  final batch = _db.batch();
  
  // Update booking status
  final bookingRef = _db.doc('bookings/$bookingId');
  batch.update(bookingRef, {
    'status': 'accepted',
    'acceptedAt': FieldValue.serverTimestamp(),
  });
  
  // Mark tutor as busy
  final tutorRef = _db.doc('tutorProfiles/$tutorId');
  batch.update(tutorRef, {
    'isBusy': true,
  });
  
  await batch.commit();
}
```

**What It Does:**
1. Updates booking status to `accepted`
2. Records `acceptedAt` timestamp
3. Sets `tutorProfiles/{tutorId}.isBusy = true`
4. All changes are atomic (both succeed or both fail)

#### `rejectBooking(String bookingId, String tutorId)`
```dart
Future<void> rejectBooking(String bookingId, String tutorId) async {
  final batch = _db.batch();
  
  // Update booking status to cancelled
  final bookingRef = _db.doc('bookings/$bookingId');
  batch.update(bookingRef, {
    'status': 'cancelled',
    'cancelledAt': FieldValue.serverTimestamp(),
  });
  
  // Ensure tutor is not busy
  final tutorRef = _db.doc('tutorProfiles/$tutorId');
  batch.update(tutorRef, {
    'isBusy': false,
  });
  
  await batch.commit();
}
```

**What It Does:**
1. Updates booking status to `cancelled`
2. Records `cancelledAt` timestamp
3. Sets `tutorProfiles/{tutorId}.isBusy = false`
4. All changes are atomic

**Why Batch Writes:**
- Ensures consistency (no partial updates)
- Prevents race conditions
- Better performance than sequential writes

---

### 5. **lib/data/repositories/tutor_repository.dart**
**Purpose:** Filter out busy tutors from search results

**Changes:**
```dart
Stream<QuerySnapshot<Map<String, dynamic>>> searchOnlineVerified({
  String? grade,
  String? subject,
  String? language,
  String? purpose,
}) {
  var q = _db
      .collection('tutorProfiles')
      .where('isOnline', isEqualTo: true)
      .where('verified', isEqualTo: true)
      .where('isBusy', isEqualTo: false);  // ← NEW
  
  // ... rest of filtering logic
  
  return q.snapshots();
}
```

**Impact:**
- Students no longer see tutors who are busy with other sessions
- Prevents double-booking scenarios
- Improves user experience (students only see available tutors)

**Query Requirements:**
- Tutors must be: `online = true` AND `verified = true` AND `isBusy = false`
- Plus optional filters for grade, subject, language, or purpose

---

### 6. **firestore.indexes.json**
**Purpose:** Enable efficient multi-field queries

**New Index Added:**
```json
{
  "collectionGroup": "tutorProfiles",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "isOnline", "order": "ASCENDING" },
    { "fieldPath": "verified", "order": "ASCENDING" },
    { "fieldPath": "isBusy", "order": "ASCENDING" }
  ]
}
```

**Why This Index:**
- Firestore requires composite indexes for queries with multiple `where` clauses
- Without this index, the search query would fail with "index required" error
- Order matters: matches the query sequence in `searchOnlineVerified()`

**Existing Indexes:** Still includes indexes for:
- Verified + online + rating (DESC) - for sorting tutors by rating
- Booking queries (tutorId, studentId, status, createdAt)
- Verification requests
- Chat threads

**Deployment Required:**
```bash
firebase deploy --only firestore:indexes
```

---

## 🔄 Complete Workflow

### Student Searches for Tutors:
```
1. Student opens tutor search
2. Query filters: isOnline=true, verified=true, isBusy=false
3. Only available tutors shown
4. Student selects tutor and books session
5. Booking created with status='paid'
```

### Tutor Receives Booking Request:
```
1. Tutor sees booking in Messages tab (status='pending')
2. Tutor taps booking → navigates to detail screen
3. Detail screen shows:
   - Student info (avatar, name, email)
   - Booking details (subject, minutes, price, status)
   - Info about busy logic
4. Tutor has two options:
   a) ACCEPT → status='accepted', isBusy=true, tutor hidden from searches
   b) REJECT → status='cancelled', isBusy=false, tutor still available
```

### After Accept:
```
- Booking status: 'pending' → 'accepted'
- Tutor profile: isBusy = true
- Student searches: This tutor no longer appears
- Detail screen: Buttons disappear (status no longer 'pending')
- Success message: "Booking accepted! You are now marked as busy."
```

### After Reject:
```
- Booking status: 'pending' → 'cancelled'
- Tutor profile: isBusy = false (stays available)
- Student searches: Tutor still visible
- Detail screen: Buttons disappear (status no longer 'pending')
- Success message: "Booking rejected"
```

---

## 🔒 Safety Features

### 1. Atomic Operations
- Uses Firestore batch writes
- Both booking and tutor profile update together
- No partial states (e.g., booking accepted but tutor not marked busy)

### 2. Button Disable During Processing
```dart
bool _processing = false;

onPressed: _processing ? null : _acceptBooking,
```
- Prevents double-clicks
- Shows loading spinner
- User can't spam the button

### 3. Status Validation
```dart
final canAccept = status == 'pending' || status == 'paid';

if (canAccept)
  SafeArea(
    child: Padding(...) // Show buttons
  )
```
- Buttons only shown for actionable statuses
- Prevents accepting already-accepted bookings
- Prevents rejecting already-cancelled bookings

### 4. Error Handling
```dart
try {
  await _bookingRepo.acceptBooking(widget.bookingId, tutorId);
  // Success handling
} catch (e) {
  setState(() => _processing = false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
  );
}
```
- Catches all errors
- Resets processing state
- Shows user-friendly error message
- Doesn't crash the app

### 5. Null Safety
```dart
final photoUrl = userData?['photoURL'] as String?;

backgroundImage: photoUrl != null && photoUrl.isNotEmpty
    ? NetworkImage(photoUrl)
    : null,
```
- Handles missing student photos
- Prevents "Invalid URI" errors
- Shows default avatar icon when photo is missing

---

## 📊 Database Schema Changes

### tutorProfiles Collection
**New Field:**
```
isBusy: boolean
  - false (default): Tutor is available for new bookings
  - true: Tutor has accepted a booking and is hidden from searches
```

**When Set to `true`:**
- Tutor accepts a booking via `acceptBooking()`
- Tutor profile hidden from student searches

**When Set to `false`:**
- Tutor rejects a booking via `rejectBooking()`
- Tutor completes/cancels an active session (future implementation)
- Tutor becomes available for new bookings

### bookings Collection
**New Fields:**
```
acceptedAt: Timestamp
  - Set when tutor accepts booking
  - Used for analytics/reporting

cancelledAt: Timestamp
  - Set when tutor rejects booking
  - Used for analytics/reporting
```

---

## 🎯 User Experience Improvements

### For Tutors:
1. **Clear Booking Details:** See all booking info at a glance
2. **Student Information:** Know who's booking before accepting
3. **One-Tap Actions:** Accept or reject with single button press
4. **Immediate Feedback:** Success/error messages appear instantly
5. **Busy Status Awareness:** Info card explains they'll be hidden during active sessions

### For Students:
1. **Only Available Tutors:** Don't see tutors who are already busy
2. **No Double-Booking:** Can't book a tutor who's already accepted another session
3. **Faster Search:** Reduced result set (no busy tutors shown)
4. **Better Success Rate:** Higher chance of booking being accepted

---

## 🚀 Testing Checklist

### Manual Testing:
- [ ] Navigate from booking list to detail screen
- [ ] Verify student info displays correctly (name, email, photo)
- [ ] Verify booking details display correctly (subject, minutes, price, status, date)
- [ ] Tap Accept button → verify:
  - [ ] Booking status changes to 'accepted'
  - [ ] Tutor profile `isBusy` becomes `true`
  - [ ] Success message appears
  - [ ] Screen pops back to booking list
  - [ ] Tutor disappears from student searches
- [ ] Tap Reject button → verify:
  - [ ] Booking status changes to 'cancelled'
  - [ ] Tutor profile `isBusy` becomes `false`
  - [ ] Success message appears
  - [ ] Screen pops back to booking list
  - [ ] Tutor still visible in student searches
- [ ] Verify buttons don't appear for already-accepted bookings
- [ ] Verify buttons don't appear for already-cancelled bookings
- [ ] Test with missing student photo (should show default avatar)
- [ ] Test error scenarios (network issues, Firestore errors)

### Firestore Testing:
- [ ] Deploy indexes: `firebase deploy --only firestore:indexes`
- [ ] Verify index status in Firebase Console
- [ ] Run student search query → verify no "index required" errors
- [ ] Check booking document after accept → verify `acceptedAt` field
- [ ] Check tutor profile after accept → verify `isBusy = true`
- [ ] Check booking document after reject → verify `cancelledAt` field
- [ ] Check tutor profile after reject → verify `isBusy = false`

---

## 🔮 Future Enhancements

### 1. Auto-Clear Busy Status
When a session is completed or cancelled after acceptance, automatically set `isBusy = false`.

**Implementation Location:**
- Wherever you mark bookings as `completed`
- Add: `await _db.doc('tutorProfiles/$tutorId').update({'isBusy': false});`

### 2. Multiple Concurrent Sessions
Allow tutors to handle multiple sessions by changing `isBusy` to an integer counter:
```dart
// Accept: increment counter
'activeBookings': FieldValue.increment(1)

// Complete/Cancel: decrement counter
'activeBookings': FieldValue.increment(-1)

// Search filter:
.where('activeBookings', isLessThan: maxConcurrentSessions)
```

### 3. Booking History in Detail Screen
Show tutor's past sessions with this student for context:
```dart
StreamBuilder<QuerySnapshot>(
  stream: _db.collection('bookings')
    .where('tutorId', isEqualTo: tutorId)
    .where('studentId', isEqualTo: studentId)
    .where('status', isEqualTo: 'completed')
    .orderBy('createdAt', descending: true)
    .limit(5)
    .snapshots(),
  // ...
)
```

### 4. Accept with Scheduling
Allow tutor to propose/confirm a specific time when accepting:
```dart
showDialog(
  context: context,
  builder: (_) => TimePicker(...),
);
// Then include selectedTime in acceptBooking() call
```

### 5. Undo Rejection
Add a "Undo" action in the SnackBar after rejecting:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Booking rejected'),
    action: SnackBarAction(
      label: 'UNDO',
      onPressed: () async {
        // Re-accept the booking
      },
    ),
  ),
);
```

---

## 🐛 Known Issues / Limitations

### 1. No Automatic Busy Cleanup
**Issue:** If a tutor accepts a booking but the session is never completed, they stay `isBusy = true` forever.

**Workaround:** Manually set `isBusy = false` in Firebase Console, or implement completion flow.

**Fix:** Add session completion logic that clears busy status.

### 2. Race Conditions on Accept
**Issue:** If two tutors somehow have the same booking (shouldn't happen), both could accept simultaneously.

**Current Mitigation:** Status validation (only accept if `pending` or `paid`)

**Better Fix:** Use Firestore transactions instead of batches:
```dart
await _db.runTransaction((tx) async {
  final bookingDoc = await tx.get(bookingRef);
  if (bookingDoc.data()!['status'] != 'pending') {
    throw Exception('Booking already processed');
  }
  tx.update(bookingRef, {'status': 'accepted', ...});
  tx.update(tutorRef, {'isBusy': true});
});
```

### 3. Index Deployment Required
**Issue:** The new composite index must be deployed to Firebase before the search query works.

**Impact:** Student searches will fail with "index required" error until deployed.

**Solution:** Run `firebase deploy --only firestore:indexes` (see below).

---

## 📋 Deployment Steps

### 1. Deploy Firestore Indexes

```bash
# From project root
cd /Users/yuanping/QuickTutor/quicktutor_2

# Login to Firebase (if not already)
firebase login

# Select your project
firebase use quicktutor2

# Deploy only the indexes (faster than full deploy)
firebase deploy --only firestore:indexes
```

**Expected Output:**
```
✔  firestore: deployed indexes in firestore.indexes.json successfully
✔  Deploy complete!
```

**Wait Time:** 1-5 minutes for index to build

**Verify in Console:**
https://console.firebase.google.com/project/quicktutor2/firestore/indexes

Look for:
```
Collection: tutorProfiles
Fields: isOnline (ASC), verified (ASC), isBusy (ASC)
Status: Enabled ✓
```

### 2. Run the App

```bash
# Run tutor app to test booking management
flutter run -d 'iPhone 16e (Tutor)' -t lib/main_tutor.dart

# OR run student app to test search filtering
flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart
```

### 3. Test the Flow

**As Tutor:**
1. Open Messages tab
2. See pending booking
3. Tap booking → detail screen opens
4. Tap "Accept" → verify success message
5. Check Firebase Console → verify `isBusy = true`

**As Student:**
1. Open tutor search
2. Verify busy tutor is hidden from results
3. Verify only available tutors shown

---

## 📊 Summary of Changes

| File | Lines Changed | Type |
|------|--------------|------|
| `app_routes.dart` | ~7 | Modified |
| `tutor_messages_screen.dart` | ~9 | Modified |
| `tutor_booking_detail_screen.dart` | ~350 | Complete Rewrite |
| `booking_repository.dart` | +45 | Added Methods |
| `tutor_repository.dart` | +1 | Added Filter |
| `firestore.indexes.json` | +9 | Added Index |
| **TOTAL** | **~421 lines** | **6 files** |

---

## ✅ Completion Checklist

- [x] 1. Updated `app_routes.dart` with tutorBookingDetail route
- [x] 2. Updated `tutor_messages_screen.dart` navigation
- [x] 3. Created new `TutorBookingDetailScreen`
- [x] 4. Added `acceptBooking` and `rejectBooking` to `BookingRepo`
- [x] 5. Updated `TutorRepo` search to filter by `isBusy`
- [x] 6. Added `tutorProfiles` index for `online+isBusy`
- [x] 7. Verified all imports and no lint errors

---

## 🎯 Next Steps

1. **Deploy Indexes:**
   ```bash
   firebase deploy --only firestore:indexes
   ```

2. **Test on Device:**
   ```bash
   flutter run -d 'iPhone 16e (Tutor)' -t lib/main_tutor.dart
   ```

3. **Implement Session Completion:**
   - Add logic to set `isBusy = false` when session ends
   - Update wherever you mark bookings as `completed`

4. **Monitor Usage:**
   - Check Firebase Console for query performance
   - Monitor index usage and costs
   - Track booking acceptance rates

---

## 🔧 Troubleshooting

### "Index required" error in student search
**Cause:** Firestore index not deployed yet

**Solution:**
```bash
firebase deploy --only firestore:indexes
```
Wait 1-5 minutes for index to build.

### Tutor stays busy forever
**Cause:** No completion flow implemented yet

**Solution:** Manually update in Firebase Console:
```
tutorProfiles/{tutorId} → isBusy: false
```

### Accept button does nothing
**Cause:** Network error or Firestore permissions

**Check:**
1. Console logs for errors
2. Firestore security rules allow tutor to update own profile
3. Network connection is stable

### Student photo not loading
**Cause:** Empty or invalid photoURL

**Solution:** Already handled in code:
```dart
backgroundImage: photoUrl != null && photoUrl.isNotEmpty
    ? NetworkImage(photoUrl)
    : null,
```

---

## 📚 Related Documentation

- Firestore Batch Writes: https://firebase.google.com/docs/firestore/manage-data/transactions
- Firestore Indexes: https://firebase.google.com/docs/firestore/query-data/indexing
- Flutter Navigation: https://docs.flutter.dev/cookbook/navigation/navigation-basics

---

**Implementation Date:** October 31, 2025  
**Status:** ✅ Complete - Ready for Testing  
**Next Action:** Deploy indexes and test on device
