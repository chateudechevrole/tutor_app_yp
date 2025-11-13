import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class MessageRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Get chat messages for a specific booking
  Stream<List<ChatMessage>> getBookingMessages(String bookingId) {
    return _db
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .orderBy('ts', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Send a message in a booking chat
  Future<void> sendMessage({
    required String bookingId,
    required String text,
  }) async {
    final userId = _auth.currentUser!.uid;
    final rawName = _auth.currentUser!.displayName?.trim();
    final userName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (_auth.currentUser?.email?.split('@').first ?? 'User');

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

    // Update booking's lastMessage and lastMessageAt
    await _db.collection('bookings').doc(bookingId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSender': userId,
      'hasUnreadMessages': true,
    });
  }

  /// Send automatic welcome message when tutor accepts booking
  Future<void> sendWelcomeMessage({
    required String bookingId,
    required String tutorId,
    required String tutorName,
  }) async {
    final messageRef = _db
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .doc();

    final welcomeText =
        "Hi! I've accepted your booking. Please feel free to share any materials, topics you'd like to focus on, or specific goals you want to achieve in our session. Looking forward to working with you!";

    await messageRef.set({
      'senderId': tutorId,
      'senderName': tutorName,
      'text': welcomeText,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
      'isWelcomeMessage': true,
    });

    // Update booking's lastMessage
    await _db.collection('bookings').doc(bookingId).update({
      'lastMessage': welcomeText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSender': tutorId,
      'hasUnreadMessages': true,
    });
  }

  /// Mark messages as read for current user
  Future<void> markMessagesAsRead(String bookingId) async {
    final userId = _auth.currentUser!.uid;

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

  /// Get count of unread messages for a user
  Future<int> getUnreadMessageCount(String userId) async {
    // Get all bookings where user is student or tutor
    final studentBookingsSnapshot = await _db
        .collection('bookings')
        .where('studentId', isEqualTo: userId)
        .where('hasUnreadMessages', isEqualTo: true)
        .get();

    final tutorBookingsSnapshot = await _db
        .collection('bookings')
        .where('tutorId', isEqualTo: userId)
        .where('hasUnreadMessages', isEqualTo: true)
        .get();

    return studentBookingsSnapshot.docs.length +
        tutorBookingsSnapshot.docs.length;
  }

  /// Stream of unread message count
  Stream<int> watchUnreadMessageCount(String userId) {
    return _db
        .collection('bookings')
        .where('studentId', isEqualTo: userId)
        .snapshots()
        .asyncMap((studentSnapshot) async {
          final tutorSnapshot = await _db
              .collection('bookings')
              .where('tutorId', isEqualTo: userId)
              .get();

          int count = 0;

          // Count student bookings with unread messages
          for (final doc in studentSnapshot.docs) {
            final data = doc.data();
            if (data['hasUnreadMessages'] == true &&
                data['lastMessageSender'] != userId) {
              count++;
            }
          }

          // Count tutor bookings with unread messages
          for (final doc in tutorSnapshot.docs) {
            final data = doc.data();
            if (data['hasUnreadMessages'] == true &&
                data['lastMessageSender'] != userId) {
              count++;
            }
          }

          return count;
        });
  }
}
