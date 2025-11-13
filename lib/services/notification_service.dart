// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/chat/chat_screen.dart';

/// Service to monitor booking status changes and trigger local notifications
class NotificationService {
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _bookingSubscription;
  final Map<String, String> _lastStatuses = {};

  /// Start monitoring bookings for status changes
  void startMonitoring(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    debugPrint('🔔 Starting notification monitoring for user: $userId');

    // Listen to user's bookings
    _bookingSubscription = _db
        .collection('bookings')
        .where('studentId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final bookingId = change.doc.id;
              final data = change.doc.data()!;
              final newStatus = data['status'] as String?;
              final oldStatus = _lastStatuses[bookingId];

              // Check if status changed to accepted or cancelled
              if (oldStatus != null &&
                  oldStatus != newStatus &&
                  (newStatus == 'accepted' || newStatus == 'cancelled')) {
                _showNotification(
                  context,
                  bookingId,
                  data,
                  oldStatus,
                  newStatus!,
                );
              }

              // Update tracked status
              if (newStatus != null) {
                _lastStatuses[bookingId] = newStatus;
              }
            } else if (change.type == DocumentChangeType.added) {
              // Track initial status
              final bookingId = change.doc.id;
              final status = change.doc.data()?['status'] as String?;
              if (status != null) {
                _lastStatuses[bookingId] = status;
              }
            }
          }
        });
  }

  /// Show in-app notification for booking status change
  void _showNotification(
    BuildContext context,
    String bookingId,
    Map<String, dynamic> data,
    String oldStatus,
    String newStatus,
  ) {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final subject = data['subject'] as String? ?? 'your booking';
    String tutorName = (data['tutorName'] as String?)?.trim() ?? '';
    if (tutorName.isEmpty) {
      tutorName =
          (data['tutorDisplayName'] as String?)?.trim() ?? 'Tutor';
    }
    final chatName = tutorName.isEmpty ? 'Tutor' : tutorName;

    String title = '';
    String message = '';
    Color backgroundColor = Colors.blue;

    if (newStatus == 'accepted') {
      title = '✅ Booking Accepted!';
      message = '$tutorName has accepted your $subject booking.';
      backgroundColor = Colors.green;
    } else if (newStatus == 'cancelled') {
      // Check if this was a tutor rejection
      final isTutorRejection = oldStatus == 'paid';
      if (isTutorRejection) {
        title = '❌ Booking Declined';
        message = '$tutorName has declined your $subject booking.';
        backgroundColor = Colors.red.shade700;
      } else {
        title = '⏰ Booking Cancelled';
        message = 'Your booking with $tutorName was cancelled.';
        backgroundColor = Colors.orange;
      }
    }

    debugPrint('🔔 Showing notification: $title - $message');

    void navigateToChat() {
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(bookingId: bookingId, otherUserName: chatName),
        ),
      );
    }

    // Show SnackBar notification
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            debugPrint('🔔 User tapped notification for booking: $bookingId');
            if (newStatus == 'accepted') {
              navigateToChat();
            }
          },
        ),
      ),
    );

  }

  /// Stop monitoring bookings
  void stopMonitoring() {
    debugPrint('🔔 Stopping notification monitoring');
    _bookingSubscription?.cancel();
    _bookingSubscription = null;
    _lastStatuses.clear();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
