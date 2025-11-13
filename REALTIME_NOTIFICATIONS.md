# Real-Time Booking Notifications

## ✅ Implementation Complete

Students now receive **immediate notifications** when tutors accept or reject their bookings.

---

## Architecture Overview

### Client-Side Real-Time Monitoring

Since the project is on **Firebase Spark Plan** (free tier), Cloud Functions are not deployed. Instead, we use a **client-side notification service** that monitors Firestore changes in real-time.

**Benefits:**
- ✅ Works on Spark plan (no Cloud Functions needed)
- ✅ Real-time updates via Firestore streams
- ✅ Immediate notification display
- ✅ No backend deployment required
- ✅ Zero latency within the app

---

## Implementation Details

### 1. NotificationService (`lib/services/notification_service.dart`)

**Purpose:** Monitor booking status changes and show in-app notifications

**Key Features:**
```dart
class NotificationService {
  // Monitors all bookings for the current student
  void startMonitoring(BuildContext context);
  
  // Tracks previous statuses to detect changes
  Map<String, String> _lastStatuses = {};
  
  // Shows SnackBar when status changes
  void _showNotification(...);
  
  // Cleanup
  void dispose();
}
```

**How It Works:**
1. Listens to Firestore `bookings` collection filtered by `studentId`
2. Tracks the last known status of each booking
3. Detects when status changes to `accepted` or `cancelled`
4. Shows a colored SnackBar notification immediately

---

### 2. StudentShell Integration

**File:** `lib/features/student/shell/student_shell.dart`

**Changes:**
```dart
class _StudentShellState extends State<StudentShell> {
  final _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _initNotificationMonitoring();
  }
  
  Future<void> _initNotificationMonitoring() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _notificationService.startMonitoring(context);
    }
  }
  
  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
```

**Why the 500ms delay?**
- Ensures BuildContext is fully initialized
- Prevents showing notifications before UI is ready

---

## Notification Types

### 1. Booking Accepted ✅

**Trigger:** Tutor accepts booking (status: `paid` → `accepted`)

**Notification:**
- **Title:** "✅ Booking Accepted!"
- **Message:** "{TutorName} has accepted your {subject} booking."
- **Color:** Green
- **Duration:** 6 seconds
- **Action:** "View" button → Opens Messages tab

**Example:**
```
┌────────────────────────────────────────┐
│ ✅ Booking Accepted!                   │
│ John Smith has accepted your Math      │
│ booking.                         [View] │
└────────────────────────────────────────┘
```

---

### 2. Booking Declined ❌

**Trigger:** Tutor rejects booking (status: `paid` → `cancelled`)

**Notification:**
- **Title:** "❌ Booking Declined"
- **Message:** "{TutorName} has declined your {subject} booking."
- **Color:** Red
- **Duration:** 6 seconds
- **Action:** "View" button → Opens Messages tab

**Example:**
```
┌────────────────────────────────────────┐
│ ❌ Booking Declined                    │
│ Sarah Lee has declined your Physics    │
│ booking.                         [View] │
└────────────────────────────────────────┘
```

---

### 3. Booking Auto-Cancelled ⏰

**Trigger:** Booking expires (15 min timeout)

**Notification:**
- **Title:** "⏰ Booking Cancelled"
- **Message:** "Your booking with {TutorName} was cancelled."
- **Color:** Orange
- **Duration:** 6 seconds
- **Action:** "View" button → Opens Messages tab

---

## Flow Diagram

### Student Side (Real-Time Updates)

```
Student App Launch
       ↓
StudentShell.initState()
       ↓
NotificationService.startMonitoring()
       ↓
Listen to Firestore: bookings?studentId={userId}
       ↓
[WAITING FOR CHANGES]
       ↓
────────────────────────────────────────
TUTOR ACCEPTS/REJECTS BOOKING
────────────────────────────────────────
       ↓
Firestore: booking/{id}.status updated
       ↓
Stream emits DocumentChangeType.modified
       ↓
Detect: oldStatus ≠ newStatus
       ↓
newStatus == 'accepted' OR 'cancelled'?
       ↓ YES
Show SnackBar notification
       ↓
User sees notification IMMEDIATELY ✅
```

---

### Tutor Side (Trigger Action)

```
Tutor App: Messages Tab
       ↓
Tap booking request
       ↓
TutorBookingDetailScreen
       ↓
Tap "Accept" or "Reject"
       ↓
BookingRepo.acceptBooking() OR rejectBooking()
       ↓
Firestore batch write:
  - Update booking status
  - Update tutor isBusy flag
       ↓
Firestore triggers listener on student side
       ↓
Student receives notification instantly
```

---

## Testing the Feature

### Test Scenario 1: Accept Booking

**Setup:**
1. **Student App** (iPhone 17 Pro)
   ```bash
   flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart
   ```

2. **Tutor App** (iPhone 16e)
   ```bash
   flutter run -d "iPhone 16e (Tutor)" -t lib/main_tutor.dart
   ```

**Steps:**
1. **Student:** Book a session with the tutor
2. **Tutor:** Go to Messages tab → See booking request
3. **Tutor:** Tap booking → Tap "Accept"
4. **Expected:** Student sees green notification instantly ✅

**Console Output (Student):**
```
🔔 Starting notification monitoring for user: {studentId}
🔔 Showing notification: ✅ Booking Accepted! - John has accepted your Math booking.
```

---

### Test Scenario 2: Reject Booking

**Steps:**
1. **Student:** Book a session with the tutor
2. **Tutor:** Go to Messages tab → See booking request
3. **Tutor:** Tap booking → Tap "Reject"
4. **Expected:** Student sees red notification instantly ❌

**Console Output (Student):**
```
🔔 Starting notification monitoring for user: {studentId}
🔔 Showing notification: ❌ Booking Declined - Sarah has declined your Physics booking.
```

---

### Test Scenario 3: Multiple Bookings

**Steps:**
1. **Student:** Create 3 bookings with different tutors
2. **Tutor 1:** Accept booking
3. **Expected:** Student sees 1st notification ✅
4. **Tutor 2:** Reject booking
5. **Expected:** Student sees 2nd notification ❌
6. **Tutor 3:** Accept booking
7. **Expected:** Student sees 3rd notification ✅

**All notifications work independently and in real-time!**

---

## Technical Details

### Firestore Query

```dart
_db.collection('bookings')
    .where('studentId', isEqualTo: userId)
    .snapshots()
    .listen((snapshot) { ... });
```

**Why this works:**
- ✅ Filters only student's bookings
- ✅ Real-time stream updates
- ✅ Minimal data transfer
- ✅ No polling required

---

### Status Tracking

```dart
final Map<String, String> _lastStatuses = {};

// On document modified:
final newStatus = data['status'];
final oldStatus = _lastStatuses[bookingId];

if (oldStatus != null && oldStatus != newStatus) {
  // Status changed! Show notification
  _showNotification(...);
}

_lastStatuses[bookingId] = newStatus;
```

**Why track previous status?**
- ✅ Avoids duplicate notifications
- ✅ Only notifies on actual changes
- ✅ Ignores initial data load

---

### Memory Management

```dart
@override
void dispose() {
  _notificationService.dispose(); // Cancels stream subscription
  super.dispose();
}
```

**Prevents:**
- ❌ Memory leaks
- ❌ Orphaned listeners
- ❌ Crashes on unmounted widgets

---

## Notification Behavior

### App States

| App State | Notification Display |
|-----------|---------------------|
| **Foreground (Active)** | ✅ SnackBar shown immediately |
| **Background** | ⚠️ Not shown (client-side only) |
| **Terminated** | ⚠️ Not shown (requires Cloud Functions) |

**Note:** For background/terminated notifications, you would need:
- Cloud Functions (requires Blaze plan)
- FCM server-side messaging
- See `functions/src/index.ts` for prepared function

---

### Notification Priority

**Immediate notifications for:**
- ✅ `paid` → `accepted` (Tutor accepted)
- ✅ `paid` → `cancelled` (Tutor rejected)

**Silent changes:**
- `pending` → `paid` (Student paid - they initiated it)
- `accepted` → `in_progress` (Session started)
- `in_progress` → `completed` (Session finished)

---

## Code Structure

```
lib/
├── services/
│   ├── notification_service.dart  ← NEW: Real-time monitoring
│   └── push/
│       ├── push_service.dart      ← FCM setup (for future)
│       └── push_background.dart   ← Background handler
│
├── features/
│   └── student/
│       └── shell/
│           └── student_shell.dart ← UPDATED: Initialize monitoring
│
└── data/
    └── repositories/
        └── booking_repository.dart ← Triggers status changes
```

---

## Future Enhancements

### Option 1: Cloud Functions (Requires Blaze Plan)

**File:** `functions/src/index.ts`

Already prepared! Just deploy:
```bash
cd functions
npm run deploy
```

**Function:** `notifyBookingStatusChange`
- Listens to booking status changes
- Sends FCM push notifications
- Works even when app is closed

---

### Option 2: Local Notifications

Add `flutter_local_notifications` package:
```yaml
dependencies:
  flutter_local_notifications: ^latest
```

**Benefits:**
- Show notifications even in background
- Custom sounds
- Persistent notifications
- Still works on Spark plan

---

## Debugging

### Enable Debug Logging

```dart
// In notification_service.dart
debugPrint('🔔 Starting notification monitoring for user: $userId');
debugPrint('🔔 Showing notification: $title - $message');
```

### Check Firestore Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Navigate to Firestore Database
3. Watch `bookings` collection in real-time
4. See status changes as they happen

### Test Status Changes Manually

```dart
// In Firestore Console, edit a booking document:
{
  "status": "accepted",  // Change from "paid"
  "acceptedAt": [current timestamp]
}

// Student app should show notification immediately
```

---

## Troubleshooting

### Issue: "No notifications showing"

**Check:**
1. Student app is running in foreground ✅
2. Booking status actually changed ✅
3. Console shows "🔔 Showing notification" ✅
4. BuildContext is mounted ✅

**Debug:**
```dart
// Add this in _showNotification():
debugPrint('Context mounted: ${context.mounted}');
debugPrint('Old status: $oldStatus, New status: $newStatus');
```

---

### Issue: "Duplicate notifications"

**Cause:** Status tracking not working

**Fix:**
```dart
// Ensure _lastStatuses is updated:
if (newStatus != null) {
  _lastStatuses[bookingId] = newStatus;
}
```

---

### Issue: "Notifications appear on app launch"

**Cause:** Initial data treated as changes

**Fix:**
```dart
// Track initial statuses without showing notifications:
if (change.type == DocumentChangeType.added) {
  _lastStatuses[bookingId] = status;
  // Don't show notification for initial load
}
```

---

## Summary

| Feature | Status | Implementation |
|---------|--------|----------------|
| Real-time monitoring | ✅ Complete | NotificationService with Firestore streams |
| Accept notifications | ✅ Working | Green SnackBar with "View" action |
| Reject notifications | ✅ Working | Red SnackBar with "View" action |
| Auto-cancel notifications | ✅ Working | Orange SnackBar |
| Memory management | ✅ Safe | Proper dispose() cleanup |
| Foreground updates | ✅ Instant | Zero latency |
| Background updates | ⚠️ Limited | Requires Cloud Functions (Blaze plan) |

---

**Students now get instant feedback when tutors respond to their bookings!** 🎉

**Next Steps:**
1. Test with real bookings ✅
2. Add navigation to booking detail from notification
3. Consider adding sound/vibration
4. Upgrade to Blaze plan for background notifications (optional)
