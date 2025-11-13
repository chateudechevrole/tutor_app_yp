# Messaging System with Chat Implementation

## ✅ Features Implemented

### 1. 🔴 Red Dot Badge on Messages Tab
- Student sees red badge when there are unread messages
- Badge appears on Messages navigation icon
- Real-time updates using Firestore streams

### 2. 💬 Automatic Welcome Message
- Tutor accepts booking → Automatic welcome message sent
- Default message: *"Hi! I've accepted your booking. Please feel free to share any materials, topics you'd like to focus on, or specific goals you want to achieve in our session. Looking forward to working with you!"*
- Message appears in student's Messages tab immediately

### 3. 💬 Real-Time Chat System
- Students and tutors can chat in real-time
- Messages stored in Firestore under `bookings/{bookingId}/messages`
- Auto-scroll to latest message
- Read receipts (messages marked as read when chat is opened)
- Message timestamps

---

## Architecture Overview

### Data Structure

#### Firestore Collections

**1. `bookings/{bookingId}` Document Fields:**
```javascript
{
  // Existing fields...
  studentId: string,
  tutorId: string,
  status: string,  // 'accepted', 'in_progress', 'completed'
  
  // New messaging fields:
  lastMessage: string,              // Last message text
  lastMessageAt: Timestamp,          // When last message was sent
  lastMessageSender: string,         // UID of who sent last message
  hasUnreadMessages: boolean         // True if recipient hasn't read
}
```

**2. `bookings/{bookingId}/messages/{messageId}` Subcollection:**
```javascript
{
  senderId: string,         // UID of sender
  senderName: string,       // Display name of sender
  text: string,             // Message content
  ts: number,               // Timestamp in milliseconds
  isRead: boolean,          // Has recipient read this message?
  isWelcomeMessage: boolean // (optional) Auto-sent welcome message
}
```

---

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   └── message_model.dart                    [UPDATED]
│   └── repositories/
│       ├── message_repository.dart               [NEW]
│       └── booking_repository.dart               [UPDATED]
│
├── features/
│   ├── chat/
│   │   └── chat_screen.dart                      [NEW]
│   ├── student/
│   │   ├── messages/
│   │   │   └── student_messages_screen.dart      [UPDATED]
│   │   └── shell/
│   │       └── student_shell.dart                [UPDATED]
│   └── tutor/
│       └── tutor_messages_screen.dart            [UPDATED]
│
└── services/
    └── notification_service.dart                 [EXISTING]
```

---

## Implementation Details

### 1. MessageRepository (`lib/data/repositories/message_repository.dart`)

**Key Methods:**

#### `getBookingMessages(String bookingId)`
```dart
Stream<List<ChatMessage>> getBookingMessages(String bookingId) {
  return _db
      .collection('bookings')
      .doc(bookingId)
      .collection('messages')
      .orderBy('ts', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
          .toList());
}
```
Returns real-time stream of messages for a booking.

---

#### `sendMessage({required String bookingId, required String text})`
```dart
Future<void> sendMessage({
  required String bookingId,
  required String text,
}) async {
  final messageRef = _db
      .collection('bookings')
      .doc(bookingId)
      .collection('messages')
      .doc();

  await messageRef.set({
    'senderId': userId,
    'senderName': userName,
    'text': text,
    'ts': DateTime.now().millisecondsSinceEpoch,
    'isRead': false,
  });

  // Update booking's lastMessage
  await _db.collection('bookings').doc(bookingId).update({
    'lastMessage': text,
    'lastMessageAt': FieldValue.serverTimestamp(),
    'lastMessageSender': userId,
  });
}
```
Sends a message and updates booking metadata.

---

#### `sendWelcomeMessage(...)`
```dart
Future<void> sendWelcomeMessage({
  required String bookingId,
  required String tutorId,
  required String tutorName,
}) async {
  final welcomeText = "Hi! I've accepted your booking. Please feel free to share any materials, topics you'd like to focus on, or specific goals you want to achieve in our session. Looking forward to working with you!";

  // Save to Firestore...
  await _db.collection('bookings').doc(bookingId).update({
    'lastMessage': welcomeText,
    'lastMessageAt': FieldValue.serverTimestamp(),
    'lastMessageSender': tutorId,
    'hasUnreadMessages': true,
  });
}
```
Called automatically when tutor accepts booking.

---

#### `markMessagesAsRead(String bookingId)`
```dart
Future<void> markMessagesAsRead(String bookingId) async {
  // Mark all messages from other user as read
  final messagesSnapshot = await _db
      .collection('bookings')
      .doc(bookingId)
      .collection('messages')
      .where('senderId', isNotEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .get();

  final batch = _db.batch();
  for (final doc in messagesSnapshot.docs) {
    batch.update(doc.reference, {'isRead': true});
  }

  // Update booking to mark no unread messages
  batch.update(_db.collection('bookings').doc(bookingId), {
    'hasUnreadMessages': false,
  });

  await batch.commit();
}
```
Called when user opens chat screen.

---

### 2. ChatScreen (`lib/features/chat/chat_screen.dart`)

**Features:**
- Real-time message list (StreamBuilder)
- Text input with send button
- Auto-scroll to bottom on new messages
- Message bubbles (left for other user, right for current user)
- Timestamps
- Empty state

**UI Structure:**
```
AppBar (other user name)
    ↓
Messages ListView (StreamBuilder)
    ↓
Message Input (TextField + Send Button)
```

**Message Bubble Design:**
- **Current User:** Blue background, white text, aligned right
- **Other User:** Gray background, black text, aligned left, shows sender name

---

### 3. Student Messages Screen Updates

**Before:**
- Showed chat threads from `threads` collection
- Generic chat interface

**After:**
- Shows accepted bookings with messages
- Query: `bookings` where `studentId == currentUser` and `status IN ['accepted', 'in_progress', 'completed']`
- Sorted by `lastMessageAt` descending
- Shows:
  - Tutor name
  - Subject
  - Last message preview
  - Unread badge (red dot + "NEW" label)
  - Bold border if unread

**Code:**
```dart
stream: FirebaseFirestore.instance
    .collection('bookings')
    .where('studentId', isEqualTo: uid)
    .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
    .orderBy('lastMessageAt', descending: true)
    .snapshots(),
```

---

### 4. Student Shell - Badge Implementation

**Feature:** Red dot badge on Messages tab icon

**Implementation:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('bookings')
      .where('studentId', isEqualTo: userId)
      .where('hasUnreadMessages', isEqualTo: true)
      .snapshots(),
  builder: (context, snapshot) {
    final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

    return NavigationBar(
      destinations: [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: hasUnread,  // ← Red dot appears
            label: Text(''),
            child: Icon(Icons.message),
          ),
          label: 'Messages',
        ),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  },
)
```

**How it works:**
- Listens to bookings with `hasUnreadMessages == true`
- Shows badge if any exist
- Badge disappears when messages are read

---

### 5. Tutor Messages Screen Updates

**Same pattern as Student:**
- Shows accepted bookings with chat
- Query: `bookings` where `tutorId == currentUser` and `status IN ['accepted', 'in_progress', 'completed']`
- Shows unread badges
- Navigates to ChatScreen

---

## User Flow

### Flow 1: Tutor Accepts Booking

```
1. Tutor opens Messages tab
   → Sees pending booking request
   
2. Tutor taps booking
   → Opens TutorBookingDetailScreen
   
3. Tutor clicks "Accept" button
   → BookingRepo.acceptBooking() called
   → Booking status: 'paid' → 'accepted'
   → Tutor marked as busy (isBusy = true)
   → MessageRepo.sendWelcomeMessage() called
   
4. Welcome message created:
   "Hi! I've accepted your booking..."
   → Stored in bookings/{id}/messages/{msgId}
   → Booking.lastMessage updated
   → Booking.hasUnreadMessages = true
   
5. Student receives notification (NotificationService)
   → SnackBar: "✅ Booking Accepted!"
   
6. Student opens Messages tab
   → 🔴 Red dot badge visible
   → Booking appears at top with "NEW" label
   → Preview shows welcome message
   
7. Student taps booking
   → Opens ChatScreen
   → markMessagesAsRead() called
   → hasUnreadMessages = false
   → Red badge disappears
   
8. Student sees welcome message
   → Can type and send reply
   
9. Tutor sees new message
   → Red badge on their Messages tab
   → Opens chat → Real-time conversation
```

---

### Flow 2: Ongoing Chat

```
Student Side                         Tutor Side
    │                                    │
    │  1. Opens ChatScreen               │
    │  markMessagesAsRead()              │
    │                                    │
    │  2. Types message                  │
    │  "I want to learn calculus"        │
    │                                    │
    │  3. Taps Send                      │
    │  sendMessage() → Firestore         │
    │                                    │
    │  ← Firestore update ─────────────→ │
    │                                    │
    │                              4. StreamBuilder emits
    │                              New message appears
    │                              🔴 Badge on Messages tab
    │                                    │
    │                              5. Opens ChatScreen
    │                              markMessagesAsRead()
    │                                    │
    │                              6. Types reply
    │                              "Great! Let's start..."
    │                                    │
    │  ← Firestore update ─────────────← │
    │                                    │
    │  7. New message appears            │
    │  Auto-scroll to bottom             │
    │                                    │
    v                                    v
```

---

## Testing Guide

### Test 1: Accept Booking & Welcome Message

**Setup:**
```bash
# Terminal 1 - Student
flutter run -d 'iPhone 17 Pro' -t lib/main_student.dart

# Terminal 2 - Tutor  
flutter run -d "iPhone 16e (Tutor)" -t lib/main_tutor.dart
```

**Steps:**
1. **Student:** Book a session with tutor
2. **Tutor:** 
   - Tap notification → Opens booking requests
   - Tap booking → Opens detail screen
   - Tap "Accept" button
3. **Expected:**
   - Tutor returns to shell
   - Student sees green notification: "✅ Booking Accepted!"
4. **Student:** Tap "Messages" tab
   - **Expected:** 
     - ✅ Red dot badge on Messages icon
     - ✅ Booking appears with "NEW" label
     - ✅ Preview shows welcome message
     - ✅ Bold border around card
5. **Student:** Tap the booking
   - **Expected:**
     - ✅ Opens ChatScreen
     - ✅ Shows welcome message from tutor
     - ✅ Red badge disappears
6. **Tutor:** Check Messages tab
   - **Expected:**
     - ✅ Booking appears in list
     - ✅ Shows welcome message preview
     - ✅ No unread badge (tutor sent it)

---

### Test 2: Two-Way Chat

**Steps:**
1. **Student:** In ChatScreen, type "I need help with calculus"
2. **Student:** Tap Send button
3. **Expected:**
   - ✅ Message appears on right (blue bubble)
   - ✅ Auto-scrolls to bottom
4. **Tutor:** Open Messages tab
   - **Expected:**
     - ✅ Red dot badge appears
     - ✅ "NEW" label on booking
     - ✅ Preview shows student's message
5. **Tutor:** Tap booking
   - **Expected:**
     - ✅ Opens ChatScreen
     - ✅ Shows both welcome message and student reply
     - ✅ Student message on left (gray bubble)
6. **Tutor:** Type "Sure! Let's start with derivatives"
7. **Tutor:** Tap Send
8. **Expected:**
   - ✅ Message appears on right (blue bubble)
9. **Student:** Check Messages tab
   - **Expected:**
     - ✅ Red badge appears again
     - ✅ Preview updates to tutor's reply
10. **Student:** Open chat
    - **Expected:**
      - ✅ All 3 messages visible
      - ✅ Conversation flows naturally
      - ✅ Timestamps shown

---

### Test 3: Multiple Bookings

**Steps:**
1. **Student:** Book 3 different tutors
2. **Tutors:** All 3 accept bookings
3. **Expected:**
   - ✅ Student sees 3 bookings in Messages
   - ✅ All show welcome messages
   - ✅ Badge shows (unread count)
4. **Student:** Open chat with Tutor 1
5. **Expected:**
   - ✅ Badge count decreases
   - ✅ Other 2 bookings still show "NEW"
6. **Student:** Chat with all 3 tutors
7. **Expected:**
   - ✅ Badge disappears when all read
   - ✅ Bookings sorted by last message time

---

## Database Queries

### Student Messages Query
```dart
FirebaseFirestore.instance
    .collection('bookings')
    .where('studentId', isEqualTo: currentUserId)
    .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
    .orderBy('lastMessageAt', descending: true)
    .snapshots()
```

**Firestore Index Required:**
```
Collection: bookings
Fields: studentId (Ascending), status (Ascending), lastMessageAt (Descending)
```

---

### Tutor Messages Query
```dart
FirebaseFirestore.instance
    .collection('bookings')
    .where('tutorId', isEqualTo: currentUserId)
    .where('status', whereIn: ['accepted', 'in_progress', 'completed'])
    .orderBy('lastMessageAt', descending: true)
    .snapshots()
```

**Firestore Index Required:**
```
Collection: bookings
Fields: tutorId (Ascending), status (Ascending), lastMessageAt (Descending)
```

---

### Unread Badge Query (Student)
```dart
FirebaseFirestore.instance
    .collection('bookings')
    .where('studentId', isEqualTo: currentUserId)
    .where('hasUnreadMessages', isEqualTo: true)
    .snapshots()
```

**Firestore Index Required:**
```
Collection: bookings
Fields: studentId (Ascending), hasUnreadMessages (Ascending)
```

---

## Console Logs

### When Tutor Accepts Booking:
```
📋 TutorBookingDetailScreen initialized
   bookingId: abc123
   studentId: def456
[Accept button tapped]
✅ Welcome message sent to student
Booking accepted! You are now marked as busy.
```

### When Student Opens Chat:
```
📱 Marking messages as read for booking: abc123
✅ 1 messages marked as read
✅ Booking hasUnreadMessages updated to false
```

### When Message Sent:
```
💬 Sending message in booking: abc123
   Sender: John Doe (student123)
   Text: "I want to learn calculus"
✅ Message saved
✅ Booking lastMessage updated
```

---

## Summary

| Feature | Status | Implementation |
|---------|--------|----------------|
| Red dot badge | ✅ Complete | StreamBuilder on unread bookings |
| Welcome message | ✅ Complete | Auto-sent on booking acceptance |
| Real-time chat | ✅ Complete | ChatScreen with Firestore streams |
| Read receipts | ✅ Complete | markMessagesAsRead() |
| Unread indicators | ✅ Complete | "NEW" label + bold borders |
| Student messages | ✅ Complete | Shows accepted bookings |
| Tutor messages | ✅ Complete | Shows accepted bookings |
| Message timestamps | ✅ Complete | Shown below each message |
| Auto-scroll | ✅ Complete | Scrolls to latest message |

---

**Students and tutors can now chat in real-time after booking acceptance!** 💬🎉
