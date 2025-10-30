import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tutor_theme.dart';

class TutorBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const TutorBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<TutorBookingDetailScreen> createState() =>
      _TutorBookingDetailScreenState();
}

class _TutorBookingDetailScreenState extends State<TutorBookingDetailScreen> {
  bool _processing = false;

  Future<void> _updateBookingStatus(String status) async {
    setState(() => _processing = true);

    try {
      await FirebaseFirestore.instance
          .doc('bookings/${widget.bookingId}')
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
            'reviewedBy': FirebaseAuth.instance.currentUser!.uid,
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Booking accepted successfully!'
                  : 'Booking declined',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking Request')),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .doc('bookings/${widget.bookingId}')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const Center(child: Text('Booking not found'));
            }

            final studentId = data['studentId'] as String;
            final amount = (data['amount'] ?? 0).toDouble();
            final duration = data['duration'] ?? 45;
            final status = data['status'] ?? 'pending';
            final createdAt = data['createdAt'] as Timestamp?;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Student Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .doc('users/$studentId')
                                .get(),
                            builder: (ctx, userSnap) {
                              final userData =
                                  userSnap.data?.data()
                                      as Map<String, dynamic>?;
                              final studentName =
                                  userData?['displayName'] ?? 'Student';
                              final studentEmail =
                                  userData?['email'] ?? 'No email';

                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: kPrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: kPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          studentEmail,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Booking Details
                      const Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Duration', '$duration minutes'),
                      _buildDetailRow(
                        'Price',
                        'RM ${amount.toStringAsFixed(2)}',
                      ),
                      _buildDetailRow(
                        'Status',
                        status.toUpperCase(),
                        statusColor: _getStatusColor(status),
                      ),
                      if (createdAt != null)
                        _buildDetailRow(
                          'Requested',
                          _formatDateTime(createdAt.toDate()),
                        ),
                      const SizedBox(height: 24),

                      // Instructions
                      Card(
                        color: Colors.blue.shade50,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Next Steps',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• Accept the booking to confirm\n'
                                '• Contact the student to schedule\n'
                                '• Conduct the session and mark as completed',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (status == 'pending')
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _processing
                                  ? null
                                  : () => _updateBookingStatus('declined'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _processing
                                  ? null
                                  : () => _updateBookingStatus('accepted'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: kPrimary,
                              ),
                              child: _processing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Accept Booking'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
