import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../theme/student_theme.dart';

class StudentBookingHistoryScreen extends StatefulWidget {
  const StudentBookingHistoryScreen({super.key});

  @override
  State<StudentBookingHistoryScreen> createState() => _StudentBookingHistoryScreenState();
}

class _StudentBookingHistoryScreenState extends State<StudentBookingHistoryScreen> {
  final _bookingRepo = BookingRepo();
  String _selectedFilter = 'all';
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _formatDateTime(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} - $hour:$minute $period';
  }
  
  @override
  Widget build(BuildContext context) {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    
    if (studentId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view booking history')),
      );
    }

    return Theme(
      data: studentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Booking History'),
          elevation: 2,
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: StreamBuilder<List<Booking>>(
                stream: _selectedFilter == 'all'
                    ? _bookingRepo.getStudentBookings(studentId)
                    : _bookingRepo.getStudentBookings(studentId, statusFilter: _selectedFilter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final bookings = snapshot.data ?? [];

                  if (bookings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(bookings[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed', 'completed'),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Accepted', 'paid'),
            const SizedBox(width: 8),
            _buildFilterChip('Cancelled', 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: studentTheme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: studentTheme.colorScheme.primary,
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.doc('tutorProfiles/${booking.tutorId}').get(),
      builder: (context, tutorSnapshot) {
        final tutorData = tutorSnapshot.data?.data() as Map<String, dynamic>?;
        final tutorName = tutorData?['displayName'] ?? 'Unknown Tutor';
        final tutorPhoto = tutorData?['photoUrl'] as String?;

        final canCancel = ['pending', 'paid']
            .contains(booking.status.toLowerCase());

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showBookingDetails(booking, tutorName, tutorPhoto),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: tutorPhoto != null 
                            ? NetworkImage(tutorPhoto)
                            : null,
                        child: tutorPhoto == null 
                            ? Text(tutorName[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.subject,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(booking.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoRow(
                        Icons.schedule,
                        '${booking.minutes} minutes',
                      ),
                      if (booking.createdAt != null)
                        _buildInfoRow(
                          Icons.calendar_today,
                          _formatDate(booking.createdAt!),
                        ),
                      if (booking.price != null)
                        _buildInfoRow(
                          Icons.payments,
                          'RM ${booking.price}',
                        ),
                    ],
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Booking'),
                        onPressed: () => _cancelBooking(booking),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        icon = Icons.cancel;
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        icon = Icons.pending;
        break;
      case 'paid':
      case 'accepted':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        icon = Icons.verified;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_selectedFilter) {
      case 'completed':
        message = 'No completed bookings yet';
        break;
      case 'pending':
        message = 'No pending bookings';
        break;
      case 'cancelled':
        message = 'No cancelled bookings';
        break;
      default:
        message = 'No booking history yet';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bookings will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking, String tutorName, String? tutorPhoto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Tutor', tutorName),
                _buildDetailRow('Subject', booking.subject),
                _buildDetailRow('Duration', '${booking.minutes} minutes'),
                if (booking.price != null)
                  _buildDetailRow('Price', 'RM ${booking.price}'),
                _buildDetailRow('Status', booking.status.toUpperCase()),
                if (booking.createdAt != null)
                  _buildDetailRow(
                    'Booked On',
                    _formatDateTime(booking.createdAt!),
                  ),
                if (booking.startAt != null)
                  _buildDetailRow(
                    'Session Time',
                    _formatDateTime(booking.startAt!),
                  ),
                const SizedBox(height: 16),
                _buildDetailRow('Booking ID', booking.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: const Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep Booking'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel Booking'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await FirebaseFirestore.instance.doc('bookings/${booking.id}').update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAnalytics.instance.logEvent(
        name: 'booking_status',
        parameters: const {'status': 'cancelled'},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $e')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
