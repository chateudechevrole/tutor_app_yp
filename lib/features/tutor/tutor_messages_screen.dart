import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tutor_theme.dart';
import '../../core/app_routes.dart';

class TutorMessagesScreen extends StatelessWidget {
  const TutorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('tutorId', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No booking requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When students book you, they\'ll appear here',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;
              final bookingId = booking.id;
              final studentId = data['studentId'] as String;
              final amount = (data['amount'] ?? 0).toDouble();
              final duration = data['duration'] ?? 45;
              final createdAt = data['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kPrimary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: kPrimary),
                  ),
                  title: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .doc('users/$studentId')
                        .get(),
                    builder: (ctx, userSnap) {
                      final userName = userSnap.data?.data() != null
                          ? (userSnap.data!.data()
                                    as Map<String, dynamic>)['displayName'] ??
                                'Student'
                          : 'Student';
                      return Text(
                        'Booking from $userName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Duration: $duration min • RM ${amount.toStringAsFixed(2)}',
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(createdAt.toDate()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.tutorBookingDetail,
                      arguments: bookingId,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
