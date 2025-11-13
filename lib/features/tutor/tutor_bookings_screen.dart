import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../theme/tutor_theme.dart';

class TutorBookingsScreen extends StatefulWidget {
  const TutorBookingsScreen({super.key});

  @override
  State<TutorBookingsScreen> createState() => _TutorBookingsScreenState();
}

class _TutorBookingsScreenState extends State<TutorBookingsScreen> {
  final Set<String> _autoCompleting = <String>{};

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return '00:00';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking Notifications')),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('tutorId', isEqualTo: uid)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final bookings = snapshot.data!.docs;
            if (bookings.isEmpty) {
              return const Center(child: Text('No bookings yet'));
            }
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (itemCtx, i) {
                final doc = bookings[i];
                final booking = doc.data();
                final status = (booking['status'] ?? 'requested') as String;
                final subject = (booking['subject'] ?? '') as String;
                final minutes = ((booking['durationMin'] ?? booking['minutes'] ?? 45) as num).toInt();
                final studentId = (booking['studentId'] ?? '') as String;
                final price = ((booking['price'] ?? booking['amount'] ?? 0) as num).toDouble();
                final acceptDeadline = booking['acceptDeadline'] as Timestamp?;
                final endAt = booking['endAt'] as Timestamp?;

                final overDeadline = acceptDeadline != null &&
                    acceptDeadline.toDate().isBefore(DateTime.now());
                // Allow Accept for both 'requested' and 'paid' status (requested = after payment)
                final canAccept = (status == 'requested' || status == 'paid') && !overDeadline;
                final canStart = status == 'accepted';
                final canComplete = status == 'in_progress';

                if (status != 'in_progress') {
                  _autoCompleting.remove(doc.id);
                }

                Color chipColor;
                switch (status) {
                  case 'requested':
                  case 'paid':
                    chipColor = Colors.orange.shade100; // New booking waiting for action
                    break;
                  case 'accepted':
                    chipColor = Colors.lightGreen.shade100;
                    break;
                  case 'in_progress':
                    chipColor = Colors.amber.shade100;
                    break;
                  case 'completed':
                    chipColor = Colors.blue.shade100;
                    break;
                  case 'cancelled':
                    chipColor = Colors.red.shade100;
                    break;
                  default:
                    chipColor = Colors.grey.shade100;
                }

                Future<void> updateStatus(
                  String newStatus,
                  Map<String, dynamic> data,
                ) async {
                  await FirebaseFirestore.instance
                      .doc('bookings/${doc.id}')
                      .update(data);
                  await FirebaseAnalytics.instance.logEvent(
                    name: 'booking_status',
                    parameters: {'status': newStatus},
                  );
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.isNotEmpty ? '$subject • $minutes min' : '$minutes min session',
                                    style: Theme.of(itemCtx).textTheme.titleMedium,
                                  ),
                                  if (price > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'RM ${price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(status.toUpperCase()),
                              backgroundColor: chipColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .doc('users/$studentId')
                              .get(),
                          builder: (ctx, userSnap) {
                            if (userSnap.hasData) {
                              final userData = userSnap.data!.data() as Map<String, dynamic>?;
                              final studentName = userData?['displayName'] ?? 'Student';
                              final studentEmail = userData?['email'] ?? '';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Student: $studentName',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if (studentEmail.isNotEmpty)
                                    Text(
                                      studentEmail,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                ],
                              );
                            }
                            return Text('Student: $studentId');
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (canAccept) ...[
                              ElevatedButton(
                                onPressed: () async {
                                  if (overDeadline) {
                                    ScaffoldMessenger.of(itemCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'This booking can no longer be accepted.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  // Update booking status and mark tutor as busy
                                  final batch = FirebaseFirestore.instance.batch();
                                  final bookingRef = FirebaseFirestore.instance.doc('bookings/${doc.id}');
                                  batch.update(bookingRef, {
                                    'status': 'accepted',
                                    'acceptedAt': FieldValue.serverTimestamp(),
                                  });
                                  
                                  // Mark tutor as busy (hidden from search)
                                  final tutorProfileRef = FirebaseFirestore.instance.doc('tutorProfiles/$uid');
                                  batch.update(tutorProfileRef, {
                                    'isBusy': true,
                                    'isOnline': false, // Also set offline when busy
                                  });
                                  
                                  await batch.commit();
                                  
                                  await FirebaseAnalytics.instance.logEvent(
                                    name: 'booking_status',
                                    parameters: {'status': 'accepted'},
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  // Reject booking - mark as cancelled
                                  final batch = FirebaseFirestore.instance.batch();
                                  final bookingRef = FirebaseFirestore.instance.doc('bookings/${doc.id}');
                                  batch.update(bookingRef, {
                                    'status': 'cancelled',
                                    'cancelledAt': FieldValue.serverTimestamp(),
                                  });
                                  
                                  await batch.commit();
                                  
                                  ScaffoldMessenger.of(itemCtx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Booking rejected'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  
                                  await FirebaseAnalytics.instance.logEvent(
                                    name: 'booking_status',
                                    parameters: {'status': 'rejected'},
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                            if (canStart)
                              ElevatedButton(
                                onPressed: () async {
                                  await updateStatus('in_progress', {
                                    'status': 'in_progress',
                                    'startAt': FieldValue.serverTimestamp(),
                                    'endAt': Timestamp.fromDate(
                                      DateTime.now().add(
                                        Duration(minutes: minutes),
                                      ),
                                    ),
                                  });
                                },
                                child: const Text('Start Class'),
                              ),
                            if (canComplete)
                              ElevatedButton(
                                onPressed: () async {
                                  await updateStatus('completed', {
                                    'status': 'completed',
                                    'completedAt': FieldValue.serverTimestamp(),
                                  });
                                },
                                child: const Text('Mark Complete'),
                              ),
                          ],
                        ),
                        if (status == 'in_progress' && endAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: StreamBuilder<DateTime>(
                              stream: Stream<DateTime>.periodic(
                                const Duration(seconds: 1),
                                (_) => DateTime.now(),
                              ),
                              initialData: DateTime.now(),
                              builder: (timerCtx, timeSnap) {
                                final now = timeSnap.data ?? DateTime.now();
                                final remaining = endAt.toDate().difference(now);

                                if (remaining <= Duration.zero) {
                                  if (_autoCompleting.add(doc.id)) {
                                    unawaited(updateStatus('completed', {
                                      'status': 'completed',
                                      'completedAt': FieldValue.serverTimestamp(),
                                    }));
                                  }
                                  return const Row(
                                    children: [
                                      Icon(Icons.timer_off, size: 16, color: Colors.grey),
                                      SizedBox(width: 6),
                                      Text(
                                        'Completing session…',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer, size: 16, color: Colors.deepOrange),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDuration(remaining),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepOrange[700],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
