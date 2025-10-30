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
                final status = (booking['status'] ?? 'pending') as String;
                final subject = (booking['subject'] ?? '') as String;
                final minutes = ((booking['minutes'] ?? 0) as num).toInt();
                final studentId = (booking['studentId'] ?? '') as String;
                final acceptDeadline = booking['acceptDeadline'] as Timestamp?;
                final endAt = booking['endAt'] as Timestamp?;

                final overDeadline = acceptDeadline != null &&
                    acceptDeadline.toDate().isBefore(DateTime.now());
                final canAccept = status == 'paid' && !overDeadline;
                final canStart = status == 'accepted';
                final canComplete = status == 'in_progress';

                if (status != 'in_progress') {
                  _autoCompleting.remove(doc.id);
                }

                Color chipColor;
                switch (status) {
                  case 'paid':
                    chipColor = Colors.green.shade100;
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
                    chipColor = Colors.orange.shade100;
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
                              child: Text(
                                '$subject • $minutes min',
                                style: Theme.of(itemCtx).textTheme.titleMedium,
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
                        Text('Student: $studentId'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (canAccept)
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
                                  await updateStatus('accepted', {
                                    'status': 'accepted',
                                    'acceptedAt': FieldValue.serverTimestamp(),
                                  });
                                },
                                child: const Text('Accept'),
                              ),
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
                                  return Row(
                                    children: const [
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
