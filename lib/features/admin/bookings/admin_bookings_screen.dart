import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  int _selectedMonth = DateTime.now().month;
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _getMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, _selectedMonth, 1);
  }

  DateTime _getMonthEnd() {
    final now = DateTime.now();
    return DateTime(now.year, _selectedMonth + 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Records'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _searchText = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (month) => DropdownMenuItem(
                          value: month,
                          child: Text(_getMonthName(month)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('startAt', isGreaterThanOrEqualTo: _getMonthStart())
            .where('startAt', isLessThan: _getMonthEnd())
            .orderBy('startAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (_searchText.isNotEmpty) {
            docs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              final subject = (data?['subject'] ?? '').toString().toLowerCase();
              final studentId = (data?['studentId'] ?? '')
                  .toString()
                  .toLowerCase();
              final tutorId = (data?['tutorId'] ?? '').toString().toLowerCase();
              return subject.contains(_searchText) ||
                  studentId.contains(_searchText) ||
                  tutorId.contains(_searchText);
            }).toList();
          }

          if (docs.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final bookingId = doc.id;
              final studentName =
                  (data['studentName'] ??
                          data['studentId'] ??
                          'Unknown Student')
                      .toString();
              final tutorName =
                  (data['tutorName'] ?? data['tutorId'] ?? 'Unknown Tutor')
                      .toString();
              final subject = (data['subject'] ?? 'Not specified').toString();
              final status = (data['status'] ?? 'unknown').toString();
              final minutes = (data['minutes'] as num?)?.toInt();
              final startTs =
                  (data['classStartAt'] ?? data['startAt']) as Timestamp?;
              final endTs = (data['classEndAt'] ?? data['endAt']) as Timestamp?;
              final startAt = startTs?.toDate();
              DateTime? endAt = endTs?.toDate();
              if (endAt == null && startAt != null && minutes != null) {
                endAt = startAt.add(Duration(minutes: minutes));
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking ID',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  bookingId,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusPill(status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoLine(
                        context,
                        icon: Icons.person_outline,
                        label: 'Student',
                        value: studentName,
                      ),
                      _buildInfoLine(
                        context,
                        icon: Icons.school_outlined,
                        label: 'Tutor',
                        value: tutorName,
                      ),
                      _buildInfoLine(
                        context,
                        icon: Icons.menu_book_outlined,
                        label: 'Subject',
                        value: subject,
                      ),
                      if (minutes != null)
                        _buildInfoLine(
                          context,
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: '$minutes minutes',
                        ),
                      _buildInfoLine(
                        context,
                        icon: Icons.play_circle_outline,
                        label: 'Class starts',
                        value: startAt != null
                            ? _formatDateTime(startAt)
                            : 'Not scheduled',
                      ),
                      _buildInfoLine(
                        context,
                        icon: Icons.stop_circle_outlined,
                        label: 'Class ends',
                        value: endAt != null
                            ? _formatDateTime(endAt)
                            : 'Not scheduled',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final day = dt.day.toString().padLeft(2, '0');
    final month = _getMonthName(dt.month);
    return '$day $month ${dt.year} • $hour:$minute $period';
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'done':
      case 'completed':
        color = Colors.green;
        break;
      case 'booked':
      case 'paid':
      case 'accepted':
        color = Colors.blue;
        break;
      case 'cancelled':
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildInfoLine(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
