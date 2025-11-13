import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tutor_theme.dart';
import '../../data/repositories/booking_repository.dart';
import '../chat/chat_screen.dart';

class TutorBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String studentId;

  const TutorBookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.studentId,
  });

  @override
  State<TutorBookingDetailScreen> createState() =>
      _TutorBookingDetailScreenState();
}

class _TutorBookingDetailScreenState extends State<TutorBookingDetailScreen> {
  bool _processing = false;
  final _bookingRepo = BookingRepo();

  @override
  void initState() {
    super.initState();
    debugPrint('📋 TutorBookingDetailScreen initialized');
    debugPrint('   bookingId: ${widget.bookingId}');
    debugPrint('   studentId: ${widget.studentId}');
  }

  Future<void> _acceptBooking() async {
    setState(() => _processing = true);

    try {
      final tutorId = FirebaseAuth.instance.currentUser!.uid;
      await _bookingRepo.acceptBooking(widget.bookingId, tutorId);

      if (!mounted) return;

      final studentDoc = await FirebaseFirestore.instance
          .doc('users/${widget.studentId}')
          .get();

      if (!mounted) return;

      final studentName =
          (studentDoc.data()?['displayName'] as String?)?.trim() ?? 'Student';

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            bookingId: widget.bookingId,
            otherUserName: studentName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking() async {
    setState(() => _processing = true);

    try {
      final tutorId = FirebaseAuth.instance.currentUser!.uid;
      await _bookingRepo.rejectBooking(widget.bookingId, tutorId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: tutorTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking Detail')),
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

            final subject = data['subject'] as String? ?? 'Unknown';
            final minutes = data['minutes'] ?? 45;
            final price = (data['price'] ?? 0).toDouble();
            final status = data['status'] ?? 'pending';
            final createdAt = data['createdAt'] as Timestamp?;

            final canAccept = status == 'pending' || status == 'paid';

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Student Info Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .doc('users/${widget.studentId}')
                                .get(),
                            builder: (ctx, userSnap) {
                              final userData =
                                  userSnap.data?.data()
                                      as Map<String, dynamic>?;
                              final studentName =
                                  userData?['displayName'] ?? 'Student';
                              final studentEmail =
                                  userData?['email'] ?? 'No email';
                              final photoUrl = userData?['photoURL'] as String?;

                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: kPrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                    backgroundImage:
                                        photoUrl != null && photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl == null || photoUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 32,
                                            color: kPrimary,
                                          )
                                        : null,
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
                      _buildDetailRow('Subject', subject),
                      _buildDetailRow('Minutes', '$minutes min'),
                      _buildDetailRow(
                        'Price',
                        'RM ${price.toStringAsFixed(2)}',
                      ),
                      _buildDetailRow(
                        'Status',
                        status.toUpperCase(),
                        statusColor: _getStatusColor(status),
                      ),
                      if (createdAt != null)
                        _buildDetailRow(
                          'Created At',
                          _formatDateTime(createdAt.toDate()),
                        ),
                      const SizedBox(height: 24),

                      // Info Card
                      if (canAccept)
                        Card(
                          color: Colors.blue.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Accept This Booking',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Accepting will mark you as "busy" and hide you from student searches until this session is completed.',
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
                if (canAccept)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _processing ? null : _rejectBooking,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _processing ? null : _acceptBooking,
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
                                  : const Text('Accept'),
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
      case 'cancelled':
      case 'declined':
        return Colors.red;
      case 'pending':
      case 'paid':
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
